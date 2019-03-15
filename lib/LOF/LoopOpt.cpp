

#include "LoopOpt.h"
#include "GreenTree.h"
#include "RedTree.h"
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


GreenLoop* LoopOptimizer:: createGreenLoop(StagedLoop *Staged ) {
	auto Seq = createGreenSequence(Staged->Body);
	return	GreenLoop::create(Seq);
}

GreenSequence* LoopOptimizer:: createGreenSequence(StagedBlock *Sequence) {
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

GreenRoot *LoopOptimizer:: createGreenRoot(StagedBlock *TopLoop) {
	auto GSeq = createGreenSequence(TopLoop);
	auto Green = GreenRoot::create(GSeq);
	return Green;
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


