#include "GreenTree.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"

using namespace llvm;


ArrayRef <const  GreenNode * >GreenSequence:: getChildren() const  {
	return ArrayRef<GreenNode*>((GreenNode**)&Blocks[0],Blocks.size());
}


ArrayRef <const  GreenNode * >  GreenRoot::getChildren() const  {		
	return   {Sequence};		
}


 ArrayRef <const GreenNode * >GreenLoop:: getChildren() const   {
	 return {Sequence};
 }


ArrayRef <const GreenNode * > GreenStore:: getChildren() const { 
	return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],(size_t)2); 
}



void GreenLoop:: codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const {
	auto StartV= Iterations->codegen(Builder, ActiveRegs);
	Function *F = Builder.GetInsertBlock()->getParent();
	LLVMContext &Context = F->getContext();

	if (ExecuteInParallel) {
	} else {
		Value *ValueLB, *ValueUB, *ValueInc;
		Type *MaxType;
		BasicBlock *ExitBlock;
		Value *IV;
		CmpInst::Predicate Predicate;

		BasicBlock *BeforeBB = Builder.GetInsertBlock();
		auto AfterBB = SplitBlock(BeforeBB,&* Builder.GetInsertPoint());

		BasicBlock *CondBB = BasicBlock::Create(Context, "loop.cond", F);
		BasicBlock *BodyBB = BasicBlock::Create(Context, "loop.body", F);

		BeforeBB->getTerminator()->setSuccessor(0, CondBB);
	

		Builder.SetInsertPoint(CondBB);
		Builder.SetInsertPoint(BodyBB);
#if 0


		// BeforeBB
		if (GuardBB) {
			BeforeBB->getTerminator()->setSuccessor(0, GuardBB);
			DT.addNewBlock(GuardBB, BeforeBB);

			// GuardBB
			Builder.SetInsertPoint(GuardBB);
			Value *LoopGuard;
			LoopGuard = Builder.CreateICmp(Predicate, LB, UB);
			LoopGuard->setName("polly.loop_guard");
			Builder.CreateCondBr(LoopGuard, PreHeaderBB, ExitBB);
			DT.addNewBlock(PreHeaderBB, GuardBB);
		} else {
			
			DT.addNewBlock(PreHeaderBB, BeforeBB);
		}

		// PreHeaderBB
		Builder.SetInsertPoint(PreHeaderBB);
		Builder.CreateBr(HeaderBB);

		// HeaderBB
		DT.addNewBlock(HeaderBB, PreHeaderBB);
		Builder.SetInsertPoint(HeaderBB);
		PHINode *IV = Builder.CreatePHI(LoopIVType, 2, "polly.indvar");
		IV->addIncoming(LB, PreHeaderBB);
		Stride = Builder.CreateZExtOrBitCast(Stride, LoopIVType);
		Value *IncrementedIV = Builder.CreateNSWAdd(IV, Stride, "polly.indvar_next");
		Value *LoopCondition =
			Builder.CreateICmp(Predicate, IncrementedIV, UB, "polly.loop_cond");

		// Create the loop latch and annotate it as such.
		BranchInst *B = Builder.CreateCondBr(LoopCondition, HeaderBB, ExitBB);
		if (Annotator)
			Annotator->annotateLoopLatch(B, NewLoop, Parallel, LoopVectDisabled);

		IV->addIncoming(IncrementedIV, HeaderBB);
		if (GuardBB)
			DT.changeImmediateDominator(ExitBB, GuardBB);
		else
			DT.changeImmediateDominator(ExitBB, HeaderBB);

		// The loop body should be added here.
		Builder.SetInsertPoint(HeaderBB->getFirstNonPHI());
		return IV;



		IDToValue[IteratorID.get()] = IV;

		create(Body.release());

		Annotator.popLoop(MarkParallel);

		IDToValue.erase(IDToValue.find(IteratorID.get()));

		Builder.SetInsertPoint(&ExitBlock->front());

		SequentialLoops++;
#endif
	}
	
}



void GreenStmt:: codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const {
	for (auto Inst : Insts) 
		Inst->codegen(Builder, ActiveRegs);
}






void GreenStore::codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const {
	auto Val = getVal()->codegen(Builder,ActiveRegs);
	auto Ptr = getPtr()->codegen(Builder,ActiveRegs);
	
	Builder.CreateStore(Val, Ptr);
}

ArrayRef <const GreenNode * > GreenSet:: getChildren() const  { return ArrayRef<GreenNode*>(Val); }


void GreenSet::codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const {
	auto NewVal =Val->codegen(Builder,ActiveRegs); 
	assert(NewVal);
	assert(!ActiveRegs.count(Var));
	ActiveRegs[ Var] = NewVal;
}


Value* GreenConst::codegen(IRBuilder<> &Builder , ActiveRegsTy &ActiveRegs)const  {
	return Const;
}


Value* GreenReg:: codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const {
	auto Result = ActiveRegs.lookup(Var);
	assert(Result);
	return Result;
}


ArrayRef <const GreenNode * > GreenGEP:: getChildren() const { return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],Operands.size());  }


Value*GreenGEP:: codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs ) const {
	SmallVector<Value*,2> Indices;
	for (auto Green : getIndices()) {
		auto IndexVal=	Green->codegen(Builder,ActiveRegs);
		Indices.push_back(IndexVal);
	}

	auto BaseVal = getBase()->codegen(Builder,ActiveRegs);

	auto Result =Builder.CreateGEP(BaseVal, Indices );
return Result;
}



ArrayRef <const GreenNode * > GreenICmp:: getChildren() const  {
	return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],(size_t)2); 
}


Value*GreenICmp:: codegen(IRBuilder<> &Builder , ActiveRegsTy &ActiveRegs)const  {
	auto LHS = getLHS()->codegen(Builder,ActiveRegs);
		auto RHS = getLHS()->codegen(Builder,ActiveRegs);
auto Result=	Builder.CreateICmp(Predicate, LHS, RHS);
return Result;
}

