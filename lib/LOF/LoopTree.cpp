#include "LoopTree.h"

using namespace llvm;


ArrayRef < GreenNode * >GreenSequence:: getChildren() const  {
	return ArrayRef<GreenNode*>((GreenNode**)&Blocks[0],Blocks.size());
}


ArrayRef < GreenNode * >  GreenRoot::getChildren() const  {		
	return   {Sequence};		
}


 ArrayRef <GreenNode * >GreenLoop:: getChildren() const   {
	 return {Sequence};
 }


ArrayRef <GreenNode * > GreenStore:: getChildren() const { 
	return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],(size_t)2); 
}

ArrayRef <GreenNode * > GreenSet:: getChildren() const  { return ArrayRef<GreenNode*>(Val); }


ArrayRef <GreenNode * > GreenGEP:: getChildren() const { return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],Operands.size());  }


ArrayRef <GreenNode * > GreenICmp:: getChildren() const  {
	return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],(size_t)2); 
}
