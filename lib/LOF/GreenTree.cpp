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

ArrayRef <const GreenNode * > GreenSet:: getChildren() const  { return ArrayRef<GreenNode*>(Val); }


ArrayRef <const GreenNode * > GreenGEP:: getChildren() const { return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],Operands.size());  }


ArrayRef <const GreenNode * > GreenICmp:: getChildren() const  {
	return  ArrayRef<GreenNode*>((GreenNode**)&Operands[0],(size_t)2); 
}
