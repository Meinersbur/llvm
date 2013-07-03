//===- LoopIncAMPrep.cpp - Loop Pre/Post-Inc. AM Prep. Pass ---------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements a pass to prepare loops for pre/post-increment
// addressing modes.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "loop-inc-am-prep"
#include "llvm/Transforms/Scalar.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Analysis/CodeMetrics.h"
#include "llvm/Analysis/InstructionSimplify.h"
#include "llvm/Analysis/LoopPass.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpander.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Support/CFG.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
using namespace llvm;

namespace {

  class LoopIncAMPrep : public LoopPass {
  public:
    static char ID; // Pass ID, replacement for typeid
    LoopIncAMPrep() : LoopPass(ID) {
      initializeLoopIncAMPrepPass(*PassRegistry::getPassRegistry());
    }

    virtual void getAnalysisUsage(AnalysisUsage &AU) const {
      AU.addPreserved<DominatorTree>();
      AU.addRequired<LoopInfo>();
      AU.addPreserved<LoopInfo>();
      AU.addRequired<ScalarEvolution>();
      AU.addRequired<TargetTransformInfo>();
    }

    bool runOnLoop(Loop *L, LPPassManager &LPM);
    void simplifyLoopLatch(Loop *L);
    bool rotateLoop(Loop *L);

  private:
    LoopInfo *LI;
    ScalarEvolution *SE;
    DataLayout *TD;
  };
}

char LoopIncAMPrep::ID = 0;
const char *name = "Prepare loop for pre/post-inc. addressing modes";
INITIALIZE_PASS_BEGIN(LoopIncAMPrep, "loop-inc-am-prep", name, false, false)
INITIALIZE_AG_DEPENDENCY(TargetTransformInfo)
INITIALIZE_PASS_DEPENDENCY(LoopInfo)
INITIALIZE_PASS_DEPENDENCY(ScalarEvolution)
INITIALIZE_PASS_END(LoopIncAMPrep, "loop-inc-am-prep", name, false, false)

Pass *llvm::createLoopIncAMPrepPass() { return new LoopIncAMPrep(); }

namespace {
  struct SCEVLess : std::binary_function<const SCEV *, const SCEV *, bool>
  {
    SCEVLess(ScalarEvolution *SE) : SE(SE) {}

    bool operator() (const SCEV *X, const SCEV *Y) const {
      const SCEV *Diff = SE->getMinusSCEV(X, Y);
      return cast<SCEVConstant>(Diff)->getValue()->getSExtValue() < 0;
    }

  protected:
    ScalarEvolution *SE;
  };
}

static bool IsPtrInBounds(Value *BasePtr) {
  Value *StrippedBasePtr = BasePtr;
  while (BitCastInst *BC = dyn_cast<BitCastInst>(StrippedBasePtr))
    StrippedBasePtr = BC->getOperand(0);
  if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(StrippedBasePtr))
    return GEP->isInBounds();

  return false;
}

static Value *GetPointerOperand(Value *MemI) {
  if (LoadInst *LMemI = dyn_cast<LoadInst>(MemI)) {
    return LMemI->getPointerOperand();
  } else if (StoreInst *SMemI = dyn_cast<StoreInst>(MemI)) {
    return SMemI->getPointerOperand();
  } else if (IntrinsicInst *IMemI = dyn_cast<IntrinsicInst>(MemI)) {
    if (IMemI->getIntrinsicID() == Intrinsic::prefetch)
      return IMemI->getArgOperand(0);
  }

  return 0;
}

bool LoopIncAMPrep::runOnLoop(Loop *L, LPPassManager &LPM) {
  LI = &getAnalysis<LoopInfo>();
  SE = &getAnalysis<ScalarEvolution>();
  TD = getAnalysisIfAvailable<DataLayout>();
  const TargetTransformInfo &TTI = getAnalysis<TargetTransformInfo>();
  bool MadeChange = false;

  if (!TD)
    return MadeChange;

  unsigned MaxVars;
  if (!TTI.prepForPreIncAM(MaxVars))
    return MadeChange;

  // Only prep. the inner-most loop
  if (!L->empty())
    return MadeChange;

  BasicBlock *Header = L->getHeader();
  BasicBlock *LoopPredecessor = L->getLoopPredecessor();
  if (!LoopPredecessor)
    return MadeChange;

  unsigned HeaderLoopPredCount = 0;
  for (pred_iterator PI = pred_begin(Header), PE = pred_end(Header);
       PI != PE; ++PI) {
    ++HeaderLoopPredCount;
  }

  typedef std::multimap<const SCEV *, Instruction *, SCEVLess> Bucket;
  SmallVector<Bucket, 16> Buckets;
  for (Loop::block_iterator I = L->block_begin(), IE = L->block_end();
       I != IE; ++I) {
    for (BasicBlock::iterator J = (*I)->begin(), JE = (*I)->end();
        J != JE; ++J) {
      Value *PtrValue;
      Instruction *MemI;

      if (LoadInst *LMemI = dyn_cast<LoadInst>(J)) {
        MemI = LMemI;
        PtrValue = LMemI->getPointerOperand();
      } else if (StoreInst *SMemI = dyn_cast<StoreInst>(J)) {
        MemI = SMemI;
        PtrValue = SMemI->getPointerOperand();
      } else if (IntrinsicInst *IMemI = dyn_cast<IntrinsicInst>(J)) {
        if (IMemI->getIntrinsicID() == Intrinsic::prefetch) {
          MemI = IMemI;
          PtrValue = IMemI->getArgOperand(0);
        } else continue;
      } else continue;

      unsigned PtrAddrSpace = PtrValue->getType()->getPointerAddressSpace();
      if (PtrAddrSpace)
        continue;

      if (L->isLoopInvariant(PtrValue))
        continue;

      const SCEV *LSCEV = SE->getSCEV(PtrValue);
      if (!isa<SCEVAddRecExpr>(LSCEV))
        continue;

      bool FoundBucket = false;
      for (unsigned i = 0, e = Buckets.size(); i != e; ++i)
        for (Bucket::iterator K = Buckets[i].begin(), KE = Buckets[i].end();
             K != KE; ++K) {
          const SCEV *Diff = SE->getMinusSCEV(K->first, LSCEV);
          if (isa<SCEVConstant>(Diff)) {
            Buckets[i].insert(std::make_pair(LSCEV, MemI));
            FoundBucket = true;
            break;
          }
        }

      if (!FoundBucket) {
        Buckets.push_back(Bucket(SCEVLess(SE)));
        Buckets[Buckets.size()-1].insert(std::make_pair(LSCEV, MemI));
      }
    }
  }

  if (Buckets.size() > MaxVars)
    return MadeChange;

  SmallSet<BasicBlock *, 16> BBChanged;
  for (unsigned i = 0, e = Buckets.size(); i != e; ++i) {
    // The base address of each bucket is transformed into a phi and the others
    // are rewritten as offsets of that variable.

    const SCEVAddRecExpr *BasePtrSCEV =
      cast<SCEVAddRecExpr>(Buckets[i].begin()->first);
    if (!BasePtrSCEV->isAffine())
      continue;

    Instruction *MemI = Buckets[i].begin()->second;
    Value *BasePtr = GetPointerOperand(MemI);
    assert(BasePtr && "No pointer operand");

    Type *I8PtrTy = Type::getInt8PtrTy(MemI->getParent()->getContext(),
      BasePtr->getType()->getPointerAddressSpace());

    const SCEV *BasePtrStartSCEV = BasePtrSCEV->getStart();
    if (!SE->isLoopInvariant(BasePtrStartSCEV, L))
      continue;

    const SCEVConstant *BasePtrIncSCEV =
      dyn_cast<SCEVConstant>(BasePtrSCEV->getStepRecurrence(*SE));
    if (!BasePtrIncSCEV)
      continue;

    PHINode *NewPHI = PHINode::Create(I8PtrTy, HeaderLoopPredCount,
      MemI->hasName() ? MemI->getName() + ".phi" : "",
      Header->getFirstNonPHI());

    SCEVExpander SCEVE(*SE, "pistart");
    BasePtrStartSCEV = SE->getMinusSCEV(BasePtrStartSCEV, BasePtrIncSCEV);

    Value *BasePtrStart = SCEVE.expandCodeFor(BasePtrStartSCEV, I8PtrTy,
      LoopPredecessor->getTerminator());
    NewPHI->addIncoming(BasePtrStart, LoopPredecessor);

    Instruction *InsPoint = Header->getFirstInsertionPt();
    GetElementPtrInst *PtrInc =
      GetElementPtrInst::Create(NewPHI, BasePtrIncSCEV->getValue(),
        MemI->hasName() ? MemI->getName() + ".inc" : "", InsPoint);
    PtrInc->setIsInBounds(IsPtrInBounds(BasePtr));
    for (pred_iterator PI = pred_begin(Header), PE = pred_end(Header);
         PI != PE; ++PI) {
      if (*PI == LoopPredecessor)
        continue;

      NewPHI->addIncoming(PtrInc, *PI);
    }

    Instruction *NewBasePtr;
    if (PtrInc->getType() != BasePtr->getType())
      NewBasePtr = new BitCastInst(PtrInc, BasePtr->getType(),
        PtrInc->hasName() ? PtrInc->getName() + ".cast" : "", InsPoint);
    else
      NewBasePtr = PtrInc;

    if (Instruction *IDel = dyn_cast<Instruction>(BasePtr))
      BBChanged.insert(IDel->getParent());
    BasePtr->replaceAllUsesWith(NewBasePtr);
    RecursivelyDeleteTriviallyDeadInstructions(BasePtr);

    Value *LastNewPtr = NewBasePtr;
    for (Bucket::iterator I = llvm::next(Buckets[i].begin()),
         IE = Buckets[i].end(); I != IE; ++I) {
      Value *Ptr = GetPointerOperand(I->second);
      assert(Ptr && "No pointer operand");
      if (Ptr == LastNewPtr)
        continue;

      Instruction *PtrIP = dyn_cast<Instruction>(Ptr);
      if (PtrIP && isa<Instruction>(NewBasePtr) &&
          cast<Instruction>(NewBasePtr)->getParent() == PtrIP->getParent())
        PtrIP = 0;
      else if (isa<PHINode>(PtrIP))
        PtrIP = PtrIP->getParent()->getFirstInsertionPt();
      else if (!PtrIP)
        PtrIP = I->second;

      const SCEVConstant *Diff =
        cast<SCEVConstant>(SE->getMinusSCEV(I->first, BasePtrSCEV));
      GetElementPtrInst *NewPtr =
        GetElementPtrInst::Create(PtrInc, Diff->getValue(),
          I->second->hasName() ? I->second->getName() + ".off" : "", PtrIP);
      if (!PtrIP)
        NewPtr->insertAfter(cast<Instruction>(PtrInc));
      NewPtr->setIsInBounds(IsPtrInBounds(Ptr));

      if (Instruction *IDel = dyn_cast<Instruction>(Ptr))
        BBChanged.insert(IDel->getParent());

      Instruction *ReplNewPtr;
      if (Ptr->getType() != NewPtr->getType()) {
        ReplNewPtr = new BitCastInst(NewPtr, Ptr->getType(),
          Ptr->hasName() ? Ptr->getName() + ".cast" : "");
        ReplNewPtr->insertAfter(NewPtr);
      } else
        ReplNewPtr = NewPtr;

      Ptr->replaceAllUsesWith(ReplNewPtr);
      RecursivelyDeleteTriviallyDeadInstructions(Ptr);

      LastNewPtr = NewPtr;
    }

    MadeChange = true;
  }

  for (Loop::block_iterator I = L->block_begin(), IE = L->block_end();
       I != IE; ++I) {
    if (BBChanged.count(*I))
      DeleteDeadPHIs(*I);
  }

  return MadeChange;
}

