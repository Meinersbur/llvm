#include "LoopTree.h"

using namespace llvm;

ArrayRef < GreenNode * >  GreenRoot::getChildren() const  {		
	GreenNode *X = Block;
	return   {X};		
}


ArrayRef <GreenNode * > GreenStore:: getChildren() const { 
	return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],(size_t)2); 
}

ArrayRef <GreenNode * > GreenSet:: getChildren() const  { return ArrayRef<GreenNode*>(Val); }


ArrayRef <GreenNode * > GreenGEP:: getChildren() const { return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],Operands.size());  }


ArrayRef <GreenNode * > GreenICmp:: getChildren() const  {
	return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],(size_t)2); 
}
