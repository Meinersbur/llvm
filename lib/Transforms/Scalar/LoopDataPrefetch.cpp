//===- LoopDataPrefetch.cpp - Loop Data Prefetching Pass ------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements a Loop Data Prefetching Pass.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "loop-data-prefetch"
#include "llvm/Transforms/Scalar.h"
#include "llvm/ADT/Statistic.h"
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

  class LoopDataPrefetch : public LoopPass {
  public:
    static char ID; // Pass ID, replacement for typeid
    LoopDataPrefetch() : LoopPass(ID) {
      initializeLoopDataPrefetchPass(*PassRegistry::getPassRegistry());
    }

    virtual void getAnalysisUsage(AnalysisUsage &AU) const {
      AU.addPreserved<DominatorTree>();
      AU.addRequired<LoopInfo>();
      AU.addPreserved<LoopInfo>();
      AU.addRequired<ScalarEvolution>();
      // FIXME: For some reason, preserving SE here breaks LSR (even if
      // this pass changes nothing).
      // AU.addPreserved<ScalarEvolution>();
      AU.addRequired<TargetTransformInfo>();
    }

    bool runOnLoop(Loop *L, LPPassManager &LPM);

  private:
    LoopInfo *LI;
    ScalarEvolution *SE;
    DataLayout *TD;
  };
}

char LoopDataPrefetch::ID = 0;
INITIALIZE_PASS_BEGIN(LoopDataPrefetch, "loop-data-prefetch", "Loop Data Prefetch", false, false)
INITIALIZE_AG_DEPENDENCY(TargetTransformInfo)
INITIALIZE_PASS_DEPENDENCY(LoopInfo)
INITIALIZE_PASS_DEPENDENCY(ScalarEvolution)
INITIALIZE_PASS_END(LoopDataPrefetch, "loop-data-prefetch", "Loop Data Prefetch", false, false)

Pass *llvm::createLoopDataPrefetchPass() { return new LoopDataPrefetch(); }

bool LoopDataPrefetch::runOnLoop(Loop *L, LPPassManager &LPM) {
  LI = &getAnalysis<LoopInfo>();
  SE = &getAnalysis<ScalarEvolution>();
  TD = getAnalysisIfAvailable<DataLayout>();
  const TargetTransformInfo &TTI = getAnalysis<TargetTransformInfo>();
  bool MadeChange = false;

  bool PrefetchWrites;
  unsigned LoopDataPrefDist;
  if (!TTI.useSoftwarePrefetching(PrefetchWrites, LoopDataPrefDist))
    return MadeChange;

  unsigned L1CacheLineSize = TTI.getL1CacheLineSize();

  // Only prefetch in the inner-most loop
  if (!L->empty())
    return MadeChange;

  // Calculate the number of iterations ahead to prefetch
  CodeMetrics Metrics;
  for (Loop::block_iterator I = L->block_begin(), IE = L->block_end();
       I != IE; ++I) {

    // If the loop already has prefetches, then assume that the user knows
    // what he or she is doing and don't add any more.
    for (BasicBlock::iterator J = (*I)->begin(), JE = (*I)->end();
         J != JE; ++J)
      if (CallInst *CI = dyn_cast<CallInst>(J))
        if (Function *F = CI->getCalledFunction())
          if (F->getIntrinsicID() == Intrinsic::prefetch)
            return MadeChange;

    Metrics.analyzeBasicBlock(*I, TTI);
  }
  unsigned LoopSize = Metrics.NumInsts;
  if (!LoopSize)
    LoopSize = 1;

  unsigned ItersAhead = LoopDataPrefDist/LoopSize;
  if (!ItersAhead)
    ItersAhead = 1;

  SmallVector<std::pair<Instruction *, const SCEVAddRecExpr *>, 16> PrefLoads;
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
        if (!PrefetchWrites) continue;
        MemI = SMemI;
        PtrValue = SMemI->getPointerOperand();
      } else continue;

      unsigned PtrAddrSpace = PtrValue->getType()->getPointerAddressSpace();
      if (PtrAddrSpace)
        continue;

      if (L->isLoopInvariant(PtrValue))
        continue;

      const SCEV *LSCEV = SE->getSCEV(PtrValue);
      const SCEVAddRecExpr *LSCEVAddRec = dyn_cast<SCEVAddRecExpr>(LSCEV);
      if (!LSCEVAddRec)
        continue;

      // We don't want to double prefetch individual cache lines. If this load
      // is known to be within one cache line of some other load that has
      // already been prefetched, then don't prefetch this one as well.
      bool DupPref = false;
      for (SmallVector<std::pair<Instruction *, const SCEVAddRecExpr *>,
             16>::iterator K = PrefLoads.begin(), KE = PrefLoads.end();
           K != KE; ++K) {
        const SCEV *PtrDiff = SE->getMinusSCEV(LSCEVAddRec, K->second);
        if (const SCEVConstant *ConstPtrDiff =
            dyn_cast<SCEVConstant>(PtrDiff)) {
          int64_t PD = abs64(ConstPtrDiff->getValue()->getSExtValue());
          if (PD < (int64_t) L1CacheLineSize) {
            DupPref = true;
            break;
          }
        }
      }
      if (DupPref)
        continue;

      PrefLoads.push_back(std::make_pair(MemI, LSCEVAddRec));

      const SCEV *NextLSCEV = SE->getAddExpr(LSCEVAddRec, SE->getMulExpr(
        SE->getConstant(LSCEVAddRec->getType(), ItersAhead),
        LSCEVAddRec->getStepRecurrence(*SE)));

      Type *I8Ptr = Type::getInt8PtrTy((*I)->getContext(), PtrAddrSpace);
      SCEVExpander SCEVE(*SE, "prefaddr");
      Value *PrefPtrValue = SCEVE.expandCodeFor(NextLSCEV, I8Ptr, MemI);

      IRBuilder<> Builder(MemI);
      Module *M = (*I)->getParent()->getParent();
      Type *I32 = Type::getInt32Ty((*I)->getContext());
      Value *PrefetchFunc = Intrinsic::getDeclaration(M, Intrinsic::prefetch);
      Builder.CreateCall4(PrefetchFunc, PrefPtrValue,
        ConstantInt::get(I32, MemI->mayReadFromMemory() ? 0 : 1),
        ConstantInt::get(I32, 3), ConstantInt::get(I32, 1));

      MadeChange = true;
    }
  }

  return MadeChange;
}

