

#include "LoopOpt.h"
#include "GreenTree.h"
#include "RedTree.h"
#include "llvm/ADT/PostOrderIterator.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Support/GraphWriter.h"
#include "llvm/Transforms/Utils/LoopUtils.h"


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

      auto HasPragmaParallelize = getBooleanLoopAttribute(L,  "llvm.loop.parallelize_thread.enable"    );
			if (!HasPragmaParallelize && !L->isAnnotatedParallel())
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

		void view(const GreenRoot *Root);

		void print(raw_ostream &OS) override {
			OS << "Nothing to print yet\n";
		}
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
		auto Green = GreenArg::create(P);
		return Green;
	}

	if (auto C = dyn_cast<Constant>(I)) {
		auto Green = GreenConst::create(C);
		return Green;
	}
	
	if (auto PHI = dyn_cast<PHINode>(I)) {
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
		}	else if (auto C = dyn_cast<CallInst>(I) ) {
			auto Callee =   getGreenExpr( C->getCalledOperand());
			SmallVector<const  GreenExpr *,8> Ops;
			for (auto &Op : C->args()) {
				auto Val = getGreenExpr(Op.get());
				Ops.push_back(Val); 
			}
			Result = GreenCall::create(Callee, Ops);
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
	DenseMap <Loop*,StagedLoop*> LoopMap;
	LoopMap[nullptr] = new StagedLoop(nullptr, nullptr);
	StagedBlock *RootBlock = LoopMap[nullptr]->Body;
	for (auto L : LI->getLoopsInPreorder()) {
		// TODO: Use own analysis on loop tree instead of SCEV.
		auto Taken = SE->getBackedgeTakenCount(L);
		Taken = SE->getSCEVAtScope(Taken, L->getParentLoop());

		//auto IterCount = SE->getMinusSCEV(Taken,  SE->getSCEV( ConstantInt::get(Context, APInt(2, -1, true) ) ) );
		Value * IterCountV;
		if (isa<SCEVSMaxExpr>(Taken)) {
		 IterCountV = cast<SCEVUnknown>( cast<SCEVSMaxExpr>(Taken)->getOperand(1) )->getValue();
		} else {
			IterCountV = cast<SCEVConstant>(Taken)->getValue();
		}

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
	std::string FuncName = Func->getName();
	Function *NewFunc = Function::Create(FT, Func->getLinkage(), Twine(), M);
	NewFunc->addFnAttr("lof-output");
	// TODO: Carry-over function attributes

	BasicBlock *EntryBB = BasicBlock::Create(Context, "entry", NewFunc);

	IRBuilder<> Builder(EntryBB);
	ActiveRegsTy ActiveRegs; // TODO: Add arguments
	for ( auto P : zip( Func->args(), NewFunc->args() )  ) {
		ActiveRegs.insert({ &std::get<0>(P) ,&std:: get<1>(P) } );
	}

	Root->getSequence()->codegen(Builder, ActiveRegs);

	if (FT->getReturnType()->isVoidTy())
		Builder.CreateRetVoid();
	else 
		Builder.CreateRet( Builder.getInt32(0) );
	


	// Remove old function
	// FIXME: Cannot remove function while being processed, so we just make it 'unused' here at rely on some cleanup pass to actually remove it. 
	// FIXME: FunctionPassManager has not been written for removing/adding functions during passes. It will ignore added functions and continue to process the currently processed function even if it was removed. We may need to switch to be a CGSCC pass, which supports adding/removing functions, bu will compute a call graph that we do not need. Howver, when we want to process OpenMP frontend-outlined subfunctions, we will need to become an CGSCC pass. 
	Func->replaceAllUsesWith(NewFunc); // This might be evil in a FunctionPass
	Func->setLinkage(GlobalValue::PrivateLinkage);
	Func->setName(Twine(".") + FuncName + Twine(".") );

	// Assign the name after removing the previous to avoid name disambiguation.
	NewFunc->setName(FuncName);
}



bool LoopOptimizerImpl::optimize() {
	auto OrigTree = buildOriginalLoopTree();

  auto OrigRedTree = RedRoot::Create(OrigTree);
  OrigRedTree->findAllDefinitions();

	auto OptimizedTree = parallelize(OrigTree);
	if (OptimizedTree == OrigTree)
		return false;

	view(OptimizedTree);

	codegen(OptimizedTree);
	return true;
}




template <> 
struct GraphTraits<const GreenNode *> {
	using GraphRef = const GreenNode *;
	using NodeRef = const GreenNode *;

	static NodeRef getEntryNode(GraphRef L) { return L; }

	using ChildIteratorType =  ArrayRef<NodeRef>::iterator ;
	static ChildIteratorType child_begin(NodeRef N) { return N->getChildren().begin(); }
	static ChildIteratorType child_end(NodeRef N) { return N->getChildren().end(); }

	using nodes_iterator = df_iterator<NodeRef>;
	static nodes_iterator nodes_begin(GraphRef RI) {
		return nodes_iterator::begin(getEntryNode(RI));
	}
	static nodes_iterator nodes_end(GraphRef RI) {
		return nodes_iterator::end(getEntryNode(RI));
	}
};


template <> 
struct DOTGraphTraits<const GreenNode *> : public DefaultDOTGraphTraits {
	using GraphRef = const GreenNode *;
	using NodeRef = const GreenNode *;

	DOTGraphTraits(bool isSimple = false) : DefaultDOTGraphTraits(isSimple) {}

	std::string getNodeLabel(NodeRef Node, GraphRef Graph) {
		SmallString<256> Result;
		raw_svector_ostream OS(Result);
		if (isSimple()) 
			Node->printLine(OS);
		else
			Node->printText(OS);
		return OS.str();
	}
};



void LoopOptimizerImpl:: view(const GreenRoot *Root) {
  ViewGraph<const GreenNode *>(Root, "lof", false, "Loop Hierarchy Graph");
}




LoopOptimizer *llvm::createLoopOptimizer(Function*Func,LoopInfo*LI,ScalarEvolution *SE) {
	return new LoopOptimizerImpl(Func,LI,SE);
}

