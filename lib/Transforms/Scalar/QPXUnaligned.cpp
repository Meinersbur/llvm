//===- QPXUnaligned.cpp - QPX Unaligned Memory Access Pass ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements IR-level lowering of QPX unaligned access.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "qpx-unaligned"
#include "llvm/Transforms/Scalar.h"
#include "llvm/ADT/DepthFirstIterator.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/CodeMetrics.h"
#include "llvm/Analysis/Dominators.h"
#include "llvm/Analysis/InstructionSimplify.h"
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

  class QPXUnaligned : public FunctionPass {
  public:
    static char ID; // Pass ID, replacement for typeid
    QPXUnaligned() : FunctionPass(ID) {
      initializeQPXUnalignedPass(*PassRegistry::getPassRegistry());
    }

    virtual void getAnalysisUsage(AnalysisUsage &AU) const {
      AU.addRequired<DominatorTree>();
      AU.addPreserved<DominatorTree>();
      AU.addRequired<ScalarEvolution>();
      // FIXME: For some reason, preserving SE here breaks LSR (even if
      // this pass changes nothing).
      // AU.addPreserved<ScalarEvolution>();
      AU.addRequired<TargetTransformInfo>();
      AU.addRequired<AliasAnalysis>();
      AU.addPreserved<AliasAnalysis>();
    }

    bool runOnFunction(Function &F);

  private:
    AliasAnalysis *AA;
    DominatorTree *DT;
    ScalarEvolution *SE;
    DataLayout *TD;
  };
}

char QPXUnaligned::ID = 0;
INITIALIZE_PASS_BEGIN(QPXUnaligned, "qpx-unaligned", "QPX Unaligned", false, false)
INITIALIZE_AG_DEPENDENCY(AliasAnalysis)
INITIALIZE_AG_DEPENDENCY(TargetTransformInfo)
INITIALIZE_PASS_DEPENDENCY(DominatorTree)
INITIALIZE_PASS_DEPENDENCY(ScalarEvolution)
INITIALIZE_PASS_END(QPXUnaligned, "qpx-unaligned", "QPX Unaligned", false, false)

Pass *llvm::createQPXUnalignedPass() { return new QPXUnaligned(); }

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

  struct ExpandableLoad {
    LoadInst *NextLoad;
    bool NextLoadFirst;
    bool MoveNextLoad;
    bool NextLoadCreationSafe;

    ExpandableLoad() :
      NextLoad(0),
      NextLoadFirst(false),
      MoveNextLoad(false),
      NextLoadCreationSafe(false) {}

    bool isValid() const {
      return NextLoad || NextLoadCreationSafe;
    }
  };
}

bool QPXUnaligned::runOnFunction(Function &F) {
  AA = &getAnalysis<AliasAnalysis>();
  DT = &getAnalysis<DominatorTree>();
  SE = &getAnalysis<ScalarEvolution>();
  TD = getAnalysisIfAvailable<DataLayout>();
  const TargetTransformInfo &TTI = getAnalysis<TargetTransformInfo>();
  bool MadeChange = false;

  if (!TTI.isPowerPCWithQPX())
    return MadeChange;

  Type *V4DoubleTy = VectorType::get(Type::getDoubleTy(F.getContext()), 4);

  // First, see if there is anything to do...
  bool hasUnalignedQPX = false;
  for (Function::iterator I = F.begin(), IE = F.end(); I != IE; ++I) {
    for (BasicBlock::iterator J = I->begin(), JE = I->end(); J != JE; ++J) {
      LoadInst *MemI = dyn_cast<LoadInst>(J);
      if (!MemI)
        continue;

      // Look for unaligned QPX loads to expand.
      if (MemI->getType() != V4DoubleTy)
        continue;

      // Skip aligned loads.
      if (MemI->getAlignment() >= 32)
        continue;

      hasUnalignedQPX = true;
      break;
    }

    if (hasUnalignedQPX)
      break;
  }

  if (!hasUnalignedQPX)
    return MadeChange;

  // Introduce a qvlpcldx-based permutation for unaligned QPX vector loads
  // when we can prove that accessing the next 32 bytes is safe. To do this,
  // we may need to peel off the last loop iteration.

  typedef std::multimap<const SCEV *, LoadInst *, SCEVLess> Bucket;
  SmallVector<Bucket, 16> Buckets;

  BasicBlock *EntryBB = F.begin();
  for (df_iterator<BasicBlock *> I = df_begin(EntryBB), IE = df_end(EntryBB);
       I != IE; ++I) {
    for (BasicBlock::iterator J = (*I)->begin(), JE = (*I)->end();
        J != JE; ++J) {
      LoadInst *MemI = dyn_cast<LoadInst>(J);
      if (!MemI)
        continue;

      Value *PtrValue = MemI->getPointerOperand();
      unsigned PtrAddrSpace = PtrValue->getType()->getPointerAddressSpace();
      if (PtrAddrSpace)
        continue;

      const SCEV *LSCEV = SE->getSCEV(PtrValue);

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

  MapVector<LoadInst *, ExpandableLoad> ExpandableLoads;
  for (unsigned i = 0, e = Buckets.size(); i != e; ++i) {
    for (Bucket::iterator I = Buckets[i].begin(), IE = Buckets[i].end();
         I != IE; ++I) {
      // Look for unaligned QPX loads to expand.
      if (I->second->getType() != V4DoubleTy)
        continue;

      // Skip aligned loads.
      if (I->second->getAlignment() >= 32)
        continue;

      // Look for loads to the next address that either always come before
      // this load or always come after it.
      ExpandableLoad EL;
      for (Bucket::iterator J = llvm::next(I); J != IE; ++J) {
        int64_t Diff = cast<SCEVConstant>(
          SE->getMinusSCEV(J->first, I->first))->getValue()->getSExtValue();
        int64_t DiffEnd = Diff + TD->getTypeStoreSize(J->second->getType()) - 1;
        bool CouldReuse = J->second->getType() == V4DoubleTy &&
                          J->second->isSimple() && Diff == 32;
        // If this load does not cover the last byte of the next QPX load,
        // then it does not tell us what we need to know.
        if (DiffEnd < 63)
          continue;

        // We've found a QPX load of the next vector.
        if (DT->dominates(J->second, I->second)) {
          // This load dominates the first, so everything is safe and
          // we're done.
          if (CouldReuse) {
            EL.NextLoad = J->second;
            EL.NextLoadFirst = true;
          } else
            EL.NextLoadCreationSafe = true;
 
          ExpandableLoads.insert(std::make_pair(I->second, EL));
          break;
        }

        bool DomAllUses = true;
        for (Value::use_iterator K = I->second->use_begin(),
             KE = I->second->use_end(); K != KE; ++K) {
          if (Instruction *U = dyn_cast<Instruction>(*K)) {
            if (!DT->dominates(J->second, U)) {
              DomAllUses = false;
              break;
            }
          }
        }

        if (DomAllUses) {
          // The second load does not dominate the first, but it does
          // dominate all uses of the first. That is good enough, and so
          // we're done.
          if (CouldReuse)
            EL.NextLoad = J->second;
          else
            EL.NextLoadCreationSafe = true;

          ExpandableLoads.insert(std::make_pair(I->second, EL));
          break;
        }

        if (DT->dominates(I->second, J->second)) {
          // This load always comes after the first. This generally
          // makes the second load safe at the location of the first load,
          // except in the case where the code *did something* to
          // make the load safe. Specifically, this must be some kind of
          // system call or inline asm. We can only actually move and reuse
          // the existing second load if there are no intervening aliasing
          // writes.

          if (CouldReuse) {
            EL.NextLoad = J->second;
            EL.MoveNextLoad = true;
          } else
            EL.NextLoadCreationSafe = true;

          SmallPtrSet<BasicBlock *, 16> Visited;
          SmallVector<BasicBlock::iterator, 16> Worklist;

          // At this point we know that all predecessor paths from the second
          // load reach the first load (but not necessarily the other way
          // around). So we need to do a backward walk from the second load
          // to the first.

          if (BasicBlock::iterator(J->second) ==
              J->second->getParent()->begin()) {
            for (pred_iterator PI = pred_begin(J->second->getParent()),
                 PIE = pred_end(J->second->getParent()); PI != PIE; ++PI)
              Worklist.push_back(BasicBlock::iterator((*PI)->getTerminator()));
          } else
            Worklist.push_back(llvm::prior(BasicBlock::iterator(J->second)));
          while (!Worklist.empty()) {
            BasicBlock::iterator P = Worklist.pop_back_val();
            if (!Visited.insert(P->getParent()))
              continue;

            bool FoundI = false;
            BasicBlock::iterator K = P, KE = P->getParent()->begin();
            do {
              if (cast<Value>(K) == I->second) {
                FoundI = true;
                break;
              }

              // FIXME: This is an over-approximation because we don't actually
              // care about writes to the first load, only to the second load.
              // Unfortunately, AA does not understand offsets.
              if (K->mayWriteToMemory() &&
                  (AA->getModRefInfo(K, I->second->getPointerOperand(), 64) &
                   AliasAnalysis::Mod) != 0) {
                if (StoreInst *SI = dyn_cast<StoreInst>(K)) {
                  // Try to refine AA's answer with SE in case this is a write
                  // to the first vector and not to the second.
                  bool FirstOnly = false;
                  const SCEV *KPtrSCEV = SE->getSCEV(SI->getPointerOperand());
                  if (const SCEVConstant *KPtrDiffSCEV =
                      dyn_cast<SCEVConstant>(SE->getMinusSCEV(KPtrSCEV, I->first))) {
                    int64_t KPtrDiff = KPtrDiffSCEV->getValue()->getSExtValue();
                    if (KPtrDiff +
                        TD->getTypeStoreSize(SI->getValueOperand()->getType()) -
                        1 < 32)
                      FirstOnly = true;
                  }

                  if (!FirstOnly) {
                    // We can't use this load directly (or move it for that
                    // matter) because there is an aliasing write in between
                    // the first load and the second; the fact that we're here,
                    // however, means that we can still assume that the second
                    // load will be safe.
                    EL.NextLoad = 0;
                    EL.MoveNextLoad = false;
                    EL.NextLoadCreationSafe = true;
                  }
                } else {
                  // This could be anything; bail...
                  goto next_J;
                }
              }

              if (K == KE)
                break;
              --K;
            } while (true);

            if (FoundI)
              continue;

            for (pred_iterator PI = pred_begin(P->getParent()),
                 PIE = pred_end(P->getParent()); PI != PIE; ++PI)
              Worklist.push_back(BasicBlock::iterator((*PI)->getTerminator()));
          }
        }
next_J:;

        if (EL.isValid()) {
          ExpandableLoads.insert(std::make_pair(I->second, EL));
          break;
        }
      }
    }
  }

  SmallPtrSet<Value *, 16> Perms;
  for (MapVector<LoadInst *, ExpandableLoad>::iterator I =
       ExpandableLoads.begin(), IE = ExpandableLoads.end(); I != IE; ++I) {
    LoadInst *Load = I->first;
    ExpandableLoad &EL = I->second;

    Load->setAlignment(32);
    if (EL.NextLoad) {
      if (EL.NextLoad->getAlignment() < 32 &&
          !ExpandableLoads.count(EL.NextLoad)) {
        EL.NextLoad = 0;
        EL.NextLoadCreationSafe = true;
      } else
        EL.NextLoad->setAlignment(32);
    }

    LoadInst *InsertPt;
    if (EL.NextLoad && EL.MoveNextLoad) {
      EL.NextLoad->removeFromParent();
      EL.NextLoad->insertAfter(Load);
      InsertPt = EL.NextLoad;

      // FIXME: We now may have moved this load to dominate other duplicate
      // loads. If there are no intervening aliasing writes, replace the
      // duplicates with this one.
    } else if (EL.NextLoad) {
      if (EL.NextLoadFirst) {
        // The second load came first.
        InsertPt = Load;
      } else
        InsertPt = EL.NextLoad;
    } else {
      SmallVector<Value *, 1> Indx;
      Indx.push_back(ConstantInt::get(Type::getInt32Ty(
        Load->getParent()->getContext()), 1));
      Instruction *NextPtr = GetElementPtrInst::Create(
        Load->getPointerOperand(), Indx);
      NextPtr->insertAfter(Load);
      InsertPt = new LoadInst(NextPtr);
      InsertPt->setAlignment(32);
      InsertPt->insertAfter(NextPtr);

      MDNode *TBAATag = Load->getMetadata(LLVMContext::MD_tbaa);
      if (TBAATag)
        InsertPt->setMetadata(LLVMContext::MD_tbaa, TBAATag);
    }

    // Now use the address of the first load to generate a qvlpcldx
    // instruction and the qvfperm shuffle.

    IRBuilder<> Builder(llvm::next(BasicBlock::iterator(InsertPt)));

    Module *M = F.getParent();
    Value *QVLPCLDFunc = Intrinsic::getDeclaration(M,
      Intrinsic::ppc_qpx_qvlpcld);
    Value *QVFPERMFunc = Intrinsic::getDeclaration(M,
      Intrinsic::ppc_qpx_qvfperm);

    Type *I8PtrTy = Type::getInt8PtrTy(F.getContext(),
      Load->getPointerOperand()->getType()->getPointerAddressSpace());
    Value *CastedPtr =
      Builder.CreateBitCast(Load->getPointerOperand(), I8PtrTy);

    Value *Perm = Builder.CreateCall(QVLPCLDFunc, CastedPtr);
    Value *Res = Builder.CreateCall3(QVFPERMFunc, Load,
      InsertPt == Load ? EL.NextLoad : InsertPt, Perm);
    Perms.insert(Res);

    // After this, the only use of the original load should be the
    // permutation just created above.
    SmallVector<Instruction *, 16> Uses;
    for (Value::use_iterator K = Load->use_begin(),
         KE = Load->use_end(); K != KE; ++K) {
      if (Instruction *U = dyn_cast<Instruction>(*K)) {
        if (Perms.count(U))
          continue;
        Uses.push_back(U);
      }
    }

    for (SmallVector<Instruction *, 16>::iterator K = Uses.begin(),
         KE = Uses.end(); K != KE; ++K)
        (*K)->replaceUsesOfWith(Load, Res);

    MadeChange = true;
  }

  return MadeChange;
}

