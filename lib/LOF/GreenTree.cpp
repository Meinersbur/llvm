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

StructType *GreenLoop:: getIdentTy(Module *M) const {
	auto &Context = M->getContext();
	auto Int32Ty = Type::getInt32Ty(Context);
	auto Int8PtrTy = Type::getInt8PtrTy(Context);

	StructType *IdentTy = M->getTypeByName("struct.ident_t");
	if (!IdentTy) {
		Type *LocMembers[] = {Int32Ty, Int32Ty,	Int32Ty,Int32Ty,Int8PtrTy};
		IdentTy =			StructType::create(Context, LocMembers, "struct.ident_t", false);
	}
	return IdentTy;
}


void GreenSequence:: codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const{
	for (auto Block : Blocks) 
		Block->codegen(Builder,ActiveRegs);
}



Function * GreenLoop::codegenSubfunc(Module *M)const {
	auto &Context = M->getContext();
	auto& DL = M->getDataLayout();

	auto Int32Ty = Type::getInt32Ty(Context);
	auto Int32PtrTy = Type::getInt32PtrTy(Context);
	auto Int8PtrTy = Type::getInt8PtrTy(Context);
	auto LongTy =  Type::getInt64Ty(Context); // Depends on the bitness of the loop counter
	auto LongPtrTy = LongTy->getPointerTo();
	auto VoidTy=  Type::getVoidTy(Context);


	SmallVector<Type*, 8> ArgTypes  = {/* global_tid */ Int32PtrTy, /* bound_tid */ Int32PtrTy, /* Iterations */ LongPtrTy}; 
	// TODO: Add used variables to argument list

	FunctionType *FT = FunctionType::get(VoidTy, ArgTypes, false);
	Function *SubFn = Function::Create(FT, Function::InternalLinkage, "parloop.par.subfun", M);
	(SubFn->arg_begin() + 0)->setName(".global_tid.");
	(SubFn->arg_begin() + 1)->setName(".bound_tid.");
	(SubFn->arg_begin() + 2)->setName("parloop.iterations.addr");

	BasicBlock *EntryBB = BasicBlock::Create(Context, "parloop.entry", SubFn);
	BasicBlock *PrecondThenBB = BasicBlock::Create(Context, "parloop.precond.then", SubFn);
	BasicBlock *InnerForCondBB = BasicBlock::Create(Context, "parloop.inner.for.cond", SubFn);
	BasicBlock *InnerForBodyBB = BasicBlock::Create(Context, "parloop.inner.for.body", SubFn);
	BasicBlock *ExitBB = BasicBlock::Create(Context, "parloop.loop.exit", SubFn);
	BasicBlock *PrecondEndBB = BasicBlock::Create(Context, "parloop.precond.end", SubFn);

	IRBuilder<> Builder(EntryBB);
	Value *IsLastPtr = Builder.CreateAlloca(Int32Ty, nullptr,"parloop.is_last.addr");
	Value *LBPtr = Builder.CreateAlloca(LongTy, nullptr, "parloop.lb.addr");
	Value *UBPtr = Builder.CreateAlloca(LongTy, nullptr, "parloop.ub.addr");
	Value *StridePtr = Builder.CreateAlloca(LongTy, nullptr, "parloop.stride.addr");
	

	auto IterationsPtr = SubFn->arg_begin()+2;
	auto IterationsV = Builder.CreateLoad(IterationsPtr, "parloop.iterations");

	auto Cmp=Builder.CreateICmpULT( Builder.getInt64(0), IterationsV );
	Builder.CreateCondBr(Cmp, PrecondThenBB, PrecondEndBB);


	Builder.SetInsertPoint(PrecondThenBB);
	auto GlobalTidPtr = SubFn->arg_begin();
	auto GlobalTidV = Builder.CreateLoad(GlobalTidPtr, "parloop.global_id");

	auto IdentTy = getIdentTy(M);
	auto IdentPtrTy = IdentTy->getPointerTo();
	auto Ident = ConstantPointerNull::get(IdentPtrTy);

	Function *KmpcForStaticInit = M->getFunction("__kmpc_for_static_init_8u");
	if (!KmpcForStaticInit) {
		Type *Params[] = {IdentPtrTy, Int32Ty, Int32Ty,  
			Int32PtrTy,LongPtrTy, LongPtrTy, LongPtrTy,  LongTy, LongTy};
		FunctionType *Ty = FunctionType::get(VoidTy, Params, false);
		KmpcForStaticInit = Function::Create(Ty, Function::ExternalLinkage, "__kmpc_for_static_init_8u", M);
	};

	Builder.CreateStore( Builder.getInt32(0), IsLastPtr );
	Builder.CreateStore( Builder.getInt64(0),LBPtr  );
	Builder.CreateStore( IterationsV,UBPtr );
	Builder.CreateStore( Builder.getInt64(1),StridePtr );
	Value *KmpcForStaticInitArgs[] = {Ident ,GlobalTidV, /* kmp_sch_static */ Builder.getInt32(34) , 
		IsLastPtr,  LBPtr,UBPtr,StridePtr,Builder.getInt64(1), /* ChunkSize */ Builder.getInt64(1)};
	Builder.CreateCall(KmpcForStaticInit, KmpcForStaticInitArgs);


	Value* UB = Builder.CreateLoad(UBPtr, "parloop.ub");
	auto UBSmall= Builder.CreateICmpULT(  IterationsV, UB);
	UB = Builder.CreateSelect(UBSmall,IterationsV,UB );

	auto LB = Builder.CreateLoad(LBPtr, "parloop.lb");
	Builder.CreateBr(InnerForCondBB);


	Builder.SetInsertPoint(InnerForCondBB);
	auto IV = Builder.CreatePHI( LongTy, 2, "parloop.iv" );
	IV->addIncoming( Builder.getInt64(0), PrecondThenBB );
	auto Cont = Builder.CreateICmpULT(IV, UB, "parloop.cont");
	Builder.CreateCondBr(Cont, InnerForBodyBB,ExitBB );



	Builder.SetInsertPoint(InnerForBodyBB);

	// TODO: Reuse/Insert parent active regs 
	ActiveRegsTy SubFnActiveRegs; 
	SubFnActiveRegs.insert({IndVar, IV} );

	Sequence->codegen(Builder, SubFnActiveRegs);

	auto NextIV = Builder.CreateAdd(IV, Builder.getInt64(0), "parloop.iv.next" );
	IV->addIncoming( NextIV, InnerForBodyBB );


	Builder.SetInsertPoint(ExitBB);

	Function *KmpcForStaticFini = M->getFunction("__kmpc_for_static_fini");
	if (!KmpcForStaticFini) {
		Type *Params[] = {IdentPtrTy, Int32Ty};
		FunctionType *Ty = FunctionType::get(VoidTy, Params, false);
		KmpcForStaticFini = Function::Create(Ty, Function::ExternalLinkage, "__kmpc_for_static_fini", M);
	};
	Value *KmpcForStaticFiniArgs[] = {Ident, GlobalTidV, GlobalTidV};
	Builder.CreateCall(KmpcForStaticFini, KmpcForStaticFiniArgs);
	Builder.CreateBr(PrecondEndBB);


	Builder.SetInsertPoint(PrecondEndBB);
	Builder.CreateRetVoid();
	return SubFn;
}


void GreenLoop:: codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const {
	auto ItersV = Iterations->codegen(Builder, ActiveRegs);
	Function *F = Builder.GetInsertBlock()->getParent();
	LLVMContext &Context = F->getContext();
	auto M = F->getParent();

	auto Int32Ty = Type::getInt32Ty(Context);
	auto Int32PtrTy = Type::getInt32PtrTy(Context);
	auto Int8PtrTy = Type::getInt8PtrTy(Context);
	auto LongTy =  Type::getInt64Ty(Context); // Depends on the bitness of the loop counter
	auto LongPtrTy = LongTy->getPointerTo();
	auto VoidTy=  Type::getVoidTy(Context);

	if (ExecuteInParallel) {
		auto SubFunc = codegenSubfunc(M );

		IRBuilder<> AllocaBuilder(&F->getEntryBlock());
		auto IterationsPtr =AllocaBuilder.CreateAlloca(LongTy, nullptr, "iterations.ptr");
		Builder.CreateStore(ItersV, IterationsPtr);

		auto IdentTy = getIdentTy(M);
		auto IdentPtrTy = IdentTy->getPointerTo();
		auto Ident = ConstantPointerNull::get(IdentPtrTy);

		FunctionType *Kmpc_MicroTy=nullptr;
		if (!Kmpc_MicroTy) {
			// Build void (*kmpc_micro)(kmp_int32 *global_tid, kmp_int32 *bound_tid,...)
			llvm::Type *MicroParams[] = {Int32PtrTy, Int32PtrTy};
			Kmpc_MicroTy = llvm::FunctionType::get(VoidTy, MicroParams, true);
		}

		Function *KmpcForkCall = M->getFunction("__kmpc_fork_call");
		if (!KmpcForkCall) {
			Type *Params[] = {IdentTy->getPointerTo(), Int32Ty,	Kmpc_MicroTy->getPointerTo()};
			FunctionType *Ty = FunctionType::get(VoidTy, Params, true);
			KmpcForkCall = Function::Create(Ty, Function::ExternalLinkage, "__kmpc_fork_call", M);
		}

	

		Value *Task = Builder.CreatePointerBitCastOrAddrSpaceCast(SubFunc, Kmpc_MicroTy->getPointerTo());
		Value *Args[] = {Ident,			/* Number of subfn varargs */ Builder.getInt32(1), Task, ItersV  };
		Builder.CreateCall(KmpcForkCall, Args);
	} else {
		Value *ValueLB, *ValueUB, *ValueInc;
		Type *MaxType;
		BasicBlock *ExitBlock;
		CmpInst::Predicate Predicate;

		BasicBlock *BeforeBB = Builder.GetInsertBlock();
		auto AfterBB = SplitBlock(BeforeBB,&* Builder.GetInsertPoint());

		BasicBlock *CondBB = BasicBlock::Create(Context, "loop.cond", F);
		BasicBlock *BodyBB = BasicBlock::Create(Context, "loop.body", F);

		BeforeBB->getTerminator()->setSuccessor(0, CondBB);
	

		Builder.SetInsertPoint(CondBB);
		PHINode *IV = Builder.CreatePHI(Builder.getInt32Ty() , 2, "loop.indvar");
		IV->addIncoming(Builder.getInt32(0), BeforeBB);
		Value *LoopCondition = Builder.CreateICmp(CmpInst::ICMP_SLT , IV, ItersV, "loop.cond");
		BranchInst *B = Builder.CreateCondBr(LoopCondition, BodyBB, AfterBB);

		Builder.SetInsertPoint(BodyBB);
		Sequence->codegen(Builder, ActiveRegs);
		Value *IncrementedIV = Builder.CreateNSWAdd(IV,  Builder.getInt32(1), "loop.indvar.next");
		IV->addIncoming(IncrementedIV, BodyBB);

		Builder.SetInsertPoint(AfterBB);
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

