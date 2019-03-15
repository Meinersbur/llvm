
#include "llvm/LOF/LOF.h"
#include "llvm/Pass.h"
#include "LoopTree.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/Loads.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/MemoryLocation.h"
#include "llvm/Analysis/OptimizationRemarkEmitter.h"
#include "llvm/Analysis/RegionInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/DiagnosticPrinter.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"
#include "llvm/Pass.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/Regex.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <cassert>
#include <memory>
#include <stack>
#include <string>
#include <utility>
#include <vector>
#include "llvm/ADT/PostOrderIterator.h"


using namespace llvm;

namespace {
	class StagedBlock;

	class StagedLoop {
	public:
		Loop *L ;
		StagedBlock *Body;

		StagedLoop() ;
	};

	
	class StagedBlock {
	public:
		SmallVector<llvm::PointerUnion< GreenStmt*, StagedLoop*> ,16> Stmts;

		void appendStmt(GreenStmt *Stmt) { Stmts.push_back(Stmt); }
		void appendLoop(StagedLoop *Loop) { Stmts.push_back(Loop); }
	};


	StagedLoop::StagedLoop() {
		Body = new StagedBlock();
	}


	class LoopOptimizer {
	private:
		Function *Func;

		LoopInfo *LI;
		ScalarEvolution *SE;

		GreenLoop *createHierarchy(Function *F) const;
		GreenLoop *createHierarchy(Loop *L) const;
		GreenStmt *createHierarchy(BasicBlock *BB) const;
		
		GreenExpr *createExpr(Value *I);


		DenseMap <Value *, GreenExpr*> ExprCache;
		GreenExpr *getGreenExpr(Value *C) ;

		DenseMap <Instruction *, GreenInst*> InstCache; // FIXME: Instructions may not be re-usable, so do not cache.
		GreenInst *getGreenInst(Instruction *I) ;

		GreenStmt *createGreenStmt(ArrayRef<GreenInst*> Insts);

	

		GreenLoop* createGreenLoop(StagedLoop *Staged ) {
			auto Seq = createGreenSequence(Staged->Body);
			return	GreenLoop::create(Seq);
		}

		GreenSequence* createGreenSequence(StagedBlock *Sequence) {
			SmallVector<GreenBlock *,32> Blocks;

			for(auto Block : Sequence->Stmts) {
				if (auto Stmt = Block.dyn_cast<GreenStmt*>()) {
					Blocks.push_back(Stmt);
				} else 				if (auto Loop = Block.dyn_cast<StagedLoop*>()) {
					auto GLoop = createGreenLoop(Loop);
					Blocks.push_back(GLoop);
				} else 
					llvm_unreachable("Something is wrong");
			}

			auto Green = GreenSequence::create(Blocks);
			return Green;
		} 

		GreenRoot *createGreenRoot(StagedBlock *TopLoop) {
			auto GSeq = createGreenSequence(TopLoop);
			auto Green = GreenRoot::create(GSeq);
			return Green;
		}

#if 0
		GreenBlock*createBlock (Loop *InLoop, ReversePostOrderTraversal<Function*>::rpo_iterator Iter) {
			auto EntryBlock = *Iter;

			SmallVector<GreenStmt*, 32> InBlockStmts; 

			while (true) {
				auto Block = *Iter;

				auto Loop = LI->getLoopFor(Block);
				if (Loop != InLoop) {
					// We entered or exited a loop
					if (Loop)

					if (!Loop) {
						// We exited all loops
						ExitLoopsUntil(nullptr);
					} else if (Loop->getParentLoop() == CurLoop) {
						// We entered one loop
						// Note that LoopInfo identifies a loop by its header block (rather than the backedge as most textbooks do), so we can enter at most one loop at a time.

						if (CurLoop)
							LoopStack.push_back(CurLoop);
						CurLoop=Loop;
					} else {
						// We exited one or more loops
						ExitLoopsUntil(Loop);
					}

					continue;
				}

			}


		
		}


		GreenLoop* createLoop(Loop *L, ReversePostOrderTraversal<Function*>::rpo_iterator Iter){
		}

		GreenRoot *createRoot();
#endif

	public:
		LoopOptimizer(Function *Func, LoopInfo*LI) : Func(Func), LI(LI) {}

		bool optimize();
		void print(raw_ostream &OS) {}
	};



	class LoopOptimizationFramework : public FunctionPass {
	private:
		std::unique_ptr<LoopOptimizer> lo;

	public :
		static char ID;

		LoopOptimizationFramework() : FunctionPass(ID){
			initializeLoopOptimizationFrameworkPass(*PassRegistry::getPassRegistry());
		}

		/// @name FunctionPass interface
		//@{
		void getAnalysisUsage(AnalysisUsage &AU) const override {
			AU.addRequired<LoopInfoWrapperPass>();
			AU.addRequired<ScalarEvolutionWrapperPass>();
			AU.addRequired<DominatorTreeWrapperPass>();
			AU.addRequired<OptimizationRemarkEmitterWrapperPass>();
			AU.addRequired<AAResultsWrapperPass>();

			// Required since transitive
			//AU.addPreserved<ScalarEvolutionWrapperPass>();
		}
		void releaseMemory() override { lo.reset(); }
		bool runOnFunction(Function &F) override {
			auto LI = &getAnalysis<LoopInfoWrapperPass>().getLoopInfo();
			lo = make_unique<LoopOptimizer>(&F, LI);
			return lo->optimize();
		}
		void print(raw_ostream &OS, const Module *) const override {
			lo->print(OS);
		}
		//@}
	};



}

GreenLoop *LoopOptimizer::createHierarchy(Function *F) const {
	llvm_unreachable("unimplemented");
}

GreenLoop *LoopOptimizer::createHierarchy(Loop *L) const {
	llvm_unreachable("unimplemented");
}

GreenStmt *LoopOptimizer::createHierarchy(BasicBlock *BB) const {
	for (auto &I : *BB) {
		if (I.mayThrow())
			return nullptr;


	}
	llvm_unreachable("unimplemented");
}

GreenExpr *LoopOptimizer::getGreenExpr(Value *V) {
	auto &Result = ExprCache[V];
	if (!Result) {
		Result = createExpr(V);
	}
	return Result;
}


GreenExpr *LoopOptimizer::createExpr(Value *I)  {
	if (auto P = dyn_cast<Argument>(I)) {
		auto Green = GreenReg::create(P);
		return Green;
	}

	if (auto C = dyn_cast<Constant>(I)) {
		auto Green = GreenConst::create(C);
		return Green;
	}
	
	if (auto PHI = dyn_cast<PHINode >(I)) {
		// FIXME: This is not really a register use; replace by case instruction or other closed-form (AddRecExpr) expression 
		auto Green = GreenReg::create(PHI);
		return Green;
	}

	if (auto GEP = dyn_cast<GetElementPtrInst>(I)) {
		SmallVector<GreenExpr*,4> Exprs;
		for (auto Op : GEP->operand_values()) {
			auto GreenOp = getGreenExpr(Op);
			Exprs.push_back(GreenOp);
		}
		auto Green = GreenGEP::create(Exprs);
		return Green;
	}

	if (auto E = dyn_cast<ICmpInst>(I)) {
		assert(E->getNumOperands()==2);
		auto LHS = getGreenExpr(E->getOperand(0));
		auto RHS = getGreenExpr(E->getOperand(1));
		return GreenICmp::create(LHS, RHS);
	}

	llvm_unreachable("unimplemented");
}



GreenInst *LoopOptimizer::getGreenInst(Instruction *I) {
	auto &Result = InstCache[I];
	if (!Result) {
		if (auto S = dyn_cast<StoreInst>(I)) {
			auto Val = getGreenExpr(S->getValueOperand());
			auto Ptr = getGreenExpr(S->getPointerOperand());
			Result = GreenStore::create(Val, Ptr);
		} else {
			// Register definition
			assert(!I->mayHaveSideEffects());
			auto Expr = getGreenExpr(I);
			Result = GreenSet::create(I,Expr);
		}
	}
	return Result;
}


GreenStmt *LoopOptimizer:: createGreenStmt(ArrayRef<GreenInst*> Insts) {
	return GreenStmt::create(Insts);
}


#if 0
GreenRoot *LoopOptimizer::createRoot() {
	ReversePostOrderTraversal<Function*> RPOT(Func);
	auto GBlock = createBlock (nullptr, RPOT.begin());
	return	GreenRoot::create(GBlock);
}
#endif


bool LoopOptimizer::optimize() {
	for (auto& Block : *Func) {
		SmallVector<GreenStmt*, 32> Stmts;
		for (auto &I : Block) {
			if (I.isTerminator())
				continue;
			if (!I.mayHaveSideEffects())
				continue;
			auto Inst = getGreenInst(&I);
			auto Stmt = createGreenStmt({Inst});
			Stmts.push_back(Stmt);
		}
	}




	DenseMap <Loop*,StagedLoop*> LoopMap;
	LoopMap[nullptr] = new StagedLoop();
	StagedBlock *RootBlock = LoopMap[nullptr]->Body;
	for (auto L : LI->getLoopsInPreorder()) {
		LoopMap[L] = new StagedLoop();
	}




	// Build a temporaru loop tree
	ReversePostOrderTraversal<Function*> RPOT(Func);
	for (auto Block : RPOT) {
		auto Loop = LI->getLoopFor(Block);
		auto SLoop = LoopMap.lookup(Loop);
		auto SBody = SLoop->Body;

		if (Loop && Block == Loop->getHeader()) {
			auto ParentLoop = Loop->getParentLoop();
			auto ParentSLoop =  LoopMap.lookup(ParentLoop);
			auto ParentSBody =  ParentSLoop->Body;
			ParentSBody->appendLoop(SLoop);
		}

		for (auto &I : *Block) {
			if (I.isTerminator())
				continue;
			if (!I.mayHaveSideEffects())
				continue;
			auto Inst = getGreenInst(&I);
			auto Stmt = createGreenStmt({Inst});
			SBody->appendStmt(Stmt);
		}
	}

	
	auto Green = createGreenRoot(RootBlock);



	return false;
}


char LoopOptimizationFramework::ID = 0;

INITIALIZE_PASS_BEGIN(LoopOptimizationFramework, "lof",	"Loop Optimization Framework", false,	false);
INITIALIZE_PASS_DEPENDENCY(AAResultsWrapperPass);
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass);
INITIALIZE_PASS_DEPENDENCY(DominatorTreeWrapperPass);
INITIALIZE_PASS_DEPENDENCY(ScalarEvolutionWrapperPass);
INITIALIZE_PASS_DEPENDENCY(OptimizationRemarkEmitterWrapperPass);
INITIALIZE_PASS_END(LoopOptimizationFramework, "lof", "Loop Optimization Framework", false, false); 
