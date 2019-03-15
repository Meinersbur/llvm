#ifndef LLVM_LOF_LOOPOPT_H
#define LLVM_LOF_LOOPOPT_H

#include "GreenTree.h"
#include "RedTree.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/Analysis/ScalarEvolution.h"



namespace {
class StagedLoop;
class StagedBlock;
}


namespace llvm {


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



		GreenLoop* createGreenLoop(StagedLoop *Staged ) ;

		GreenSequence* createGreenSequence(StagedBlock *Sequence) ;

		GreenRoot *createGreenRoot(StagedBlock *TopLoop) ;


	public:
		LoopOptimizer(Function *Func, LoopInfo*LI) : Func(Func), LI(LI) {}

		bool optimize();
		void print(raw_ostream &OS) {}
	};


}


#endif /* LLVM_LOF_LOOPOPT_H */
