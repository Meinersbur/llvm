

#include "LoopOpt.h"
#include "GreenTree.h"
#include "RedTree.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"




using namespace llvm;

namespace {
	class StagedBlock;

	class StagedLoop {
	public:
		Loop *L ;
		StagedBlock *Body;
		Value *Iterations;

		explicit StagedLoop(Loop *LoopInfoLoop, Value *Iterations)  ;
	};

	
	class StagedBlock {
	public:
		SmallVector<llvm::PointerUnion< GreenStmt*, StagedLoop*> ,16> Stmts;

		void appendStmt(GreenStmt *Stmt) { Stmts.push_back(Stmt); }
		void appendLoop(StagedLoop *Loop) { Stmts.push_back(Loop); }
	};


	StagedLoop::StagedLoop(Loop *LoopInfoLoop, Value *Iterations): L(LoopInfoLoop), Body(new StagedBlock()) , Iterations(Iterations){
		
	}



	class LoopOptimizerImpl : public LoopOptimizer {
	private:
		Function *Func;

		LoopInfo *LI;
		ScalarEvolution *SE;


		GreenRoot *OriginalRoot=nullptr;


		GreenLoop *createHierarchy(Function *F) const;
		GreenLoop *createHierarchy(Loop *L) const;
		GreenStmt *createHierarchy(BasicBlock *BB) const;

		GreenExpr *createExpr(Value *I);


		DenseMap <Value *, GreenExpr*> ExprCache;
		GreenExpr *getGreenExpr(Value *C) ;

		DenseMap <Instruction *, GreenInst*> InstCache; // FIXME: Instructions may not be re-usable, so do not cache.
		GreenInst *getGreenInst(Instruction *I) ;

		GreenStmt *createGreenStmt(ArrayRef<GreenInst*> Insts);



		GreenLoop* createGreenLoop(StagedLoop *Staged ) ;
		GreenSequence* createGreenSequence(StagedBlock *Sequence) ;
		GreenRoot *createGreenRoot(StagedBlock *TopLoop) ;


	const	GreenSequence *parallelizeSequence(const GreenSequence *Seq) {
			bool Changed = false;
			SmallVector<const GreenBlock*,32> NewBlocks;
			for (auto Block : Seq->blocks()) {
				const GreenBlock *NewBlock;
				if (auto Stmt = dyn_cast<GreenStmt>(Block)) {
					NewBlock = Stmt;
				} else if (auto Loop = dyn_cast<GreenLoop>(Block)) {
					NewBlock = parallelizeLoop(Loop);
				} else 
					llvm_unreachable("unexpected");

				if (Block != NewBlock)
					Changed=true;

				NewBlocks.push_back(NewBlock);
			}	

			if (!Changed)
				return Seq;

			return GreenSequence::create(NewBlocks);
		}

	const	GreenLoop *parallelizeLoop(const GreenLoop *Loop) {
			auto L = Loop->getLoopInfoLoop();
			if (!L)
				return Loop;
			if (!L->isAnnotatedParallel())
				return Loop;
			if (Loop->isExecutedInParallel())
				return Loop;

			auto Cloned = Loop->clone();
			Cloned->setExecuteInParallel();
			return Cloned;
		}



	public:
		LoopOptimizerImpl(Function *Func, LoopInfo*LI, ScalarEvolution *SE) : Func(Func), LI(LI) ,SE(SE){}

		GreenRoot * buildOriginalLoopTree();
		const GreenRoot *parallelize(const GreenRoot *Root);
		void codegen(const GreenRoot *Root);
		 

		bool optimize()override ;
		void print(raw_ostream &OS) override {}
	};


	

}

GreenLoop *LoopOptimizerImpl::createHierarchy(Function *F) const {
	llvm_unreachable("unimplemented");
}

GreenLoop *LoopOptimizerImpl::createHierarchy(Loop *L) const {
	llvm_unreachable("unimplemented");
}

GreenStmt *LoopOptimizerImpl::createHierarchy(BasicBlock *BB) const {
	for (auto &I : *BB) {
		if (I.mayThrow())
			return nullptr;


	}
	llvm_unreachable("unimplemented");
}

GreenExpr *LoopOptimizerImpl::getGreenExpr(Value *V) {
	auto &Result = ExprCache[V];
	if (!Result) {
		Result = createExpr(V);
	}
	return Result;
}


GreenExpr *LoopOptimizerImpl::createExpr(Value *I)  {
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
		return GreenICmp::create( E->getPredicate(), LHS, RHS);
	}

	llvm_unreachable("unimplemented");
}



GreenInst *LoopOptimizerImpl::getGreenInst(Instruction *I) {
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


GreenStmt *LoopOptimizerImpl:: createGreenStmt(ArrayRef<GreenInst*> Insts) {
	return GreenStmt::create(Insts);
}


GreenLoop* LoopOptimizerImpl:: createGreenLoop(StagedLoop *Staged ) {
	auto Seq = createGreenSequence(Staged->Body);
auto Iters=	getGreenExpr(Staged->Iterations);
	return	GreenLoop::create(Iters, Staged->L->getCanonicalInductionVariable(), Seq, Staged->L);
}

GreenSequence* LoopOptimizerImpl:: createGreenSequence(StagedBlock *Sequence) {
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

GreenRoot *LoopOptimizerImpl:: createGreenRoot(StagedBlock *TopLoop) {
	auto GSeq = createGreenSequence(TopLoop);
	auto Green = GreenRoot::create(GSeq);
	return Green;
}






GreenRoot* LoopOptimizerImpl::buildOriginalLoopTree() {
	auto &Context = Func->getContext();

	DenseMap <Loop*,StagedLoop*> LoopMap;
	LoopMap[nullptr] = new StagedLoop(nullptr, nullptr);
	StagedBlock *RootBlock = LoopMap[nullptr]->Body;
	for (auto L : LI->getLoopsInPreorder()) {
		// TODO: Use own analysis on loop tree instead of SCEV.
		auto Taken = SE->getBackedgeTakenCount(L);
		Taken = SE->getSCEVAtScope(Taken, L->getParentLoop());

		//auto IterCount = SE->getMinusSCEV(Taken,  SE->getSCEV( ConstantInt::get(Context, APInt(2, -1, true) ) ) );
		auto IterCountV = cast<SCEVUnknown>( cast<SCEVSMaxExpr>(Taken)->getOperand(1) )->getValue();

		// FIXME: This assume the form without loop-rotation
		//    for (int = 0; i < 0; i+=1)
		LoopMap[L] = new StagedLoop(L,IterCountV );
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

	
	OriginalRoot = createGreenRoot(RootBlock);
	return OriginalRoot;
}



const GreenRoot *LoopOptimizerImpl::parallelize(const GreenRoot *Root){
	auto NewSeq= parallelizeSequence(Root->getSequence() );
	if (NewSeq==Root->getSequence())
		return Root;

	auto NewRoot = Root->clone();
	NewRoot->setSequence(NewSeq);
	return NewRoot;
}





void LoopOptimizerImpl::codegen(const GreenRoot *Root) {
	auto M = Func->getParent();
	auto &Context = M->getContext();

	// Make a clone of the original function.
	FunctionType *FT = Func->getFunctionType()  ;
	Function *NewFunc = Function::Create(FT, Func->getLinkage(), Func->getName(), M);

	BasicBlock *EntryBB = BasicBlock::Create(Context, "entry", NewFunc);

	IRBuilder<> Builder(EntryBB);
	ActiveRegsTy ActiveRegs; // TODO: Add arguments
	for ( auto P : zip( Func->args(), NewFunc->args() )  ) {
		ActiveRegs.insert({ &std::get<0>(P) ,&std:: get<1>(P) } );
	}

	Root->getSequence()->codegen(Builder, ActiveRegs);

	Builder.CreateRetVoid();

	Func->replaceAllUsesWith(NewFunc);
	Func->removeFromParent();
}



bool LoopOptimizerImpl::optimize() {
	auto OrigTree= buildOriginalLoopTree();

	auto OptimizedTree = parallelize(OrigTree);
	if (OptimizedTree == OrigTree)
		return false;

	codegen(OptimizedTree);
	return true;
}



LoopOptimizer *llvm::createLoopOptimizer(Function*Func,LoopInfo*LI,ScalarEvolution *SE) {
	return new LoopOptimizerImpl(Func,LI,SE);
}

