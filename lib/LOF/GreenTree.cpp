#include "GreenTree.h"

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


void GreenStore::codegen(IRBuilder<> &Builder )const {
	auto Val = getVal()->codegen(Builder);
	auto Ptr = getPtr()->codegen(Builder);
	
	Builder.CreateStore(Val, Ptr);
}

ArrayRef <const GreenNode * > GreenSet:: getChildren() const  { return ArrayRef<GreenNode*>(Val); }


void GreenSet::codegen(IRBuilder<> &Builder )const {
	llvm_unreachable("unimplemented");
}


Value* GreenConst::codegen(IRBuilder<> &Builder )const  {
	return Const;
}


Value* GreenReg:: codegen(IRBuilder<> &Builder )const {
	llvm_unreachable("unimplemented");
}


ArrayRef <const GreenNode * > GreenGEP:: getChildren() const { return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],Operands.size());  }


Value*GreenGEP:: codegen(IRBuilder<> &Builder ) const {
	SmallVector<Value*,2> Indices;
	for (auto Green : getIndices()) {
		auto IndexVal=	Green->codegen(Builder);
		Indices.push_back(IndexVal);
	}

	auto BaseVal = getBase()->codegen(Builder);

	auto Result =Builder.CreateGEP(BaseVal, Indices );
return Result;
}



ArrayRef <const GreenNode * > GreenICmp:: getChildren() const  {
	return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],(size_t)2); 
}


Value*GreenICmp:: codegen(IRBuilder<> &Builder )const  {
	auto LHS = getLHS()->codegen(Builder);
		auto RHS = getLHS()->codegen(Builder);
auto Result=	Builder.CreateICmp(Predicate, LHS, RHS);
return Result;
}

