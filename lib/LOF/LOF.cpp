
#include "llvm/LOF/LOF.h"
#include "llvm/Pass.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/Loads.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/MemoryLocation.h"
#include "llvm/Analysis/OptimizationRemarkEmitter.h"
#include "llvm/Analysis/RegionInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpressions.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/DiagnosticPrinter.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"
#include "llvm/Pass.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/Regex.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <cassert>
#include <memory>
#include <stack>
#include <string>
#include <utility>
#include <vector>


using namespace llvm;

namespace {

	enum class LoopHierarchyKind {
		Root,

		// Blocks
		Stmt,
		Loop,

		// Instructions
		Load,
		Store,
		Call,

		// Expressions
		Const,
		Op,

		Block_First= Stmt,
		Block_Last = Loop,

		Inst_First = Load,
		Inst_Last = Call,

		Expr_First = Const,
		Expr_Last = Op,
	};


	class GreenInst;
	class GreenExpr;
	class GreenBlock;

	// Immutable (sub-)tree, only contains references to its children
	class GreenNode {
	public:
		virtual ~GreenNode() {};

		virtual LoopHierarchyKind getKind() const = 0;
		static bool classof(const GreenNode *) {	return true;	}

		void dump() const { printText(errs()); }
		virtual void printLine(raw_ostream &OS) const {}
		virtual void printText(raw_ostream &OS) const { printLine(OS); OS << '\n'; }

		virtual ArrayRef <GreenNode * > getChildren() const = 0;
	};


	/// Node in an immutable tree, contains reference to parent and corresponding green node (which stores the children) 
	/// TODO: Make it a stack object
	class RedNode {
	private:
		RedNode *Parent;
		GreenNode *Green;

	protected:
		RedNode(RedNode*Parent, GreenNode *Green): Parent(Parent),Green(Green) {}

	public:
		virtual ~RedNode() {};

		virtual LoopHierarchyKind getKind() const {return getGreen()->getKind();}
		static bool classof(const RedNode *) {	return true; }

		void dump() const { printText(errs()); }
		virtual void printLine(raw_ostream &OS) const { getGreen()->printLine(OS); }
		virtual void printText(raw_ostream &OS) const { getGreen()->printText(OS); }

		 RedNode *getParent() const {return Parent;}
		 GreenNode* getGreen() const {return Green;}
	};




	class GreenRoot : public GreenNode {
	private :
		GreenBlock *Block;

	public:
		GreenRoot (GreenBlock *Block): Block(Block) {}
		virtual ~GreenRoot() {};

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Root; }
		static bool classof(const GreenNode *Node) { return  Node->getKind() == LoopHierarchyKind::Root; }
		static bool classof(const GreenRoot *) {	return true;	}

		virtual ArrayRef < GreenNode * > getChildren() const override ;
	}; 


	class RedRoot:public RedNode {
	private:
	public:
		RedRoot(RedNode*Parent, GreenRoot *Green) : RedNode(Parent,Green) {}
		virtual ~RedRoot() {};

		static bool classof(const RedNode *Node) { GreenRoot::classof(Node->getGreen()); }
		static bool classof(const RedRoot *) {	return true;	}

		GreenRoot* getGreen() const {return static_cast<GreenRoot*>( getGreen());}
	};


#if 0
	class GreenSequence final : public GreenNode {
	private:
		std::vector<GreenBlock *> Blocks;
	public:
		
	};

	class RedSequence final : public RedNode {
	private:
	public:
	};
#endif


// A statement or loop (abstract class)
	class GreenBlock  : public GreenNode  {
	private :

	public:
		//GreenBlock (ArrayRef<const GreenSequence*const> Stmts): Stmts(Stmts) {}
		//virtual ~GreenBlock() {};

		// virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Block; }
		static bool classof(const GreenNode *Node) {	auto Kind =Node-> getKind(); return LoopHierarchyKind::Block_First <= Kind && Kind <= LoopHierarchyKind::Block_Last;	}
		static bool classof(const GreenBlock *) {	return true;	}


	//	virtual ArrayRef <const GreenNode * const> getChildren() const override { return Stmts;}// ArrayRef<const GreenNode * const>( Stmts.data(), Stmts.size()); };
	}; 

	class RedBlock : public RedNode {
	private:
	public:
		RedBlock(RedNode*Parent, GreenBlock *Green) : RedNode(Parent,Green) {}


		static bool classof(const RedNode *Node) { GreenBlock::classof(Node->getGreen()); }
		static bool classof(const RedBlock *) {	return true;	}

		GreenRoot* getGreen() const {return static_cast<GreenRoot*>( getGreen());}
	};



	class GreenLoop final : public GreenBlock {
	private:
	public:
		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Loop; }
		static bool classof(const GreenNode *Node) {	return Node->getKind() == LoopHierarchyKind::Loop; 	}
		static bool classof(const GreenLoop *) {	return true;	}

		virtual ArrayRef <GreenNode * > getChildren() const { return {}; };
	};

	class RedLoop final : public RedBlock {
	private:
	public:
		RedLoop(RedNode *Parent, GreenLoop*Green) : RedBlock(Parent,Green) {}

		static bool classof(const RedNode *Node) { GreenLoop::classof(Node->getGreen()); }
		static bool classof(const RedLoop *) {	return true;	}

		GreenLoop* getGreen() const {return static_cast<GreenLoop*>( getGreen());}
	};



	class GreenStmt final : public GreenBlock {
	private:
		std::vector<GreenInst*> Insts;
	public:
		GreenStmt(ArrayRef<GreenInst*> Insts) : Insts(Insts) {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Stmt; }
		static bool classof(const GreenNode *Node) {	return Node->getKind() == LoopHierarchyKind::Stmt; 	}
		static bool classof(const GreenStmt *) {	return true;	}

		virtual ArrayRef <GreenNode * > getChildren() const { return {}; };
	};


	class RedStmt final : public RedBlock {
	private:
	public:
		RedStmt(RedNode *Parent, GreenStmt*Green) : RedBlock(Parent,Green) {}

		static bool classof(const RedNode *Node) { GreenStmt::classof(Node->getGreen()); }
		static bool classof(const RedStmt *) {	return true;	}

		GreenStmt* getGreen() const {return static_cast<GreenStmt*>( getGreen());}
	};



	class GreenInst  : public GreenNode {
	private:
	public:
		static bool classof(const GreenNode *Node)  {	auto Kind =Node-> getKind(); return LoopHierarchyKind::Inst_First <= Kind && Kind <= LoopHierarchyKind::Inst_Last;	}
		static bool classof(const GreenInst *) {	return true;	}
	};

	class RedInst final : public RedNode {
	private:
	public:
		RedInst(RedNode *Parent, GreenStmt*Green) : RedNode(Parent,Green) {}

		static bool classof(const RedNode *Node) { GreenInst::classof(Node->getGreen()); }
		static bool classof(const RedInst *) {	return true;	}

		GreenInst* getGreen() const {return static_cast<GreenInst*>( getGreen());}
	};





	class GreenExpr: public GreenNode {
		private:
		public:
			static bool classof(const GreenNode *Node)  {	auto Kind =Node-> getKind(); return LoopHierarchyKind::Expr_First <= Kind && Kind <= LoopHierarchyKind::Expr_Last;	}
			static bool classof(const GreenInst *) {	return true;	}
	};

	class RedExpr : public RedNode {
	private: 
	public:
		RedExpr(RedNode *Parent, GreenExpr*Green) : RedNode(Parent,Green) {}

		static bool classof(const RedNode *Node) { GreenExpr::classof(Node->getGreen()); }
		static bool classof(const RedExpr *) {	return true;	}

		GreenExpr* getGreen() const {return static_cast<GreenExpr*>( getGreen());}
	};



	// Expression tree leaf
	class GreenConst final : public GreenExpr {
		Constant *Const;
	public:
		GreenConst(Constant *Const) : Const(Const) {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Const; }
		static bool classof(const GreenNode *Node) {	return Node->getKind() == LoopHierarchyKind::Const; 	}
		static bool classof(const GreenConst *) {	return true;	}

		virtual ArrayRef <GreenNode * > getChildren() const { return {}; };

		static  GreenConst *create(Constant *C) { return new GreenConst(C); }
	};


	class RedConst final : public RedExpr {
	private:
	public:
		RedConst(RedNode *Parent, GreenConst*Green) : RedExpr(Parent,Green) {}

		static bool classof(const RedNode *Node) { GreenConst::classof(Node->getGreen()); }
		static bool classof(const RedConst *) {	return true;	}

		GreenConst* getGreen() const {return static_cast<GreenConst*>( getGreen());}
	};




#if 0
	class RedLoop : public RedBlock {
		GreenLoop *Green;
	public:
	};





	// Something executable: a loop or statement
	class GreenBlock : public GreenNode {

	public :
		static bool classof(const GreenNode *Node) { return LoopHierarchyKind::Block_First <= Node->getKind() && Node->getKind() <= LoopHierarchyKind::Block_Last; }
		static bool classof(const GreenBlock *) { return true; }
	};


	class GreenLoop : public GreenBlock   {
		SmallVector<GreenBlock*,4> Blocks;

		Loop * OriginalLoop;
	public:
		virtual LoopHierarchyKind getKind() const { return LoopHierarchyKind::Loop;  }
		static bool classof(const GreenNode *Node) { return LoopHierarchyKind::Loop == Node->getKind() ; }
		static bool classof(const GreenBlock *) { return true; }

		ArrayRef <const GreenNode * const> getChildren() const override { return ArrayRef<const GreenNode* const>(reinterpret_cast< GreenNode*const*  >( Blocks.data()) , Blocks .size()); }
	};

	// Group of statements
	class GreenStmt : public GreenBlock {	
		SmallVector<GreenInst*, 8> Insts;

		BasicBlock * OriginalBB;
	public:
		virtual LoopHierarchyKind getKind() const { return LoopHierarchyKind::Statement; }
		static bool classof(const GreenNode *Node) { return LoopHierarchyKind::Statement == Node->getKind(); }
		static bool classof(const GreenBlock *) { return true; }

		ArrayRef <const GreenNode * const> getChildren() const override;
	};

	// Instruction with side-effect
	class GreenInst : public GreenNode {
		unsigned InstType;
		SmallVector<GreenExpr*, 2> Operands;

		Instruction *OriginalInst;

		GreenInst(unsigned Ty, ArrayRef<const GreenExpr*> Ops, Instruction *Original) : InstType(Ty), Operands(Ops.begin(), Ops.end()), OriginalInst(Original) {}
	public:
		virtual LoopHierarchyKind getKind() const { return LoopHierarchyKind::Instruction; }
		static bool classof(const GreenNode *Node) { return LoopHierarchyKind::Instruction == Node->getKind(); }
		static bool classof(const GreenBlock *) { return true; }

		static const GreenInst *create(unsigned Ty, ArrayRef<const GreenExpr*> Ops, Instruction *Original = nullptr) { return new GreenInst(Ty, Ops, Original ); }

		ArrayRef <const GreenNode * const> getChildren() const override;
	};



	// Side-effect free instruction, SCEV, or isl::pw_aff
	class GreenExpr : public GreenNode {
		Instruction *OriginalInst;
	public:
		static bool classof(const GreenNode *Node) { return LoopHierarchyKind::Instruction == Node->getKind(); }
		static bool classof(const GreenExpr *) { return true; }
	};

	class GreenInstExpr : public GreenExpr {
		Instruction::ValueTy InstType;
		SmallVector<GreenExpr*, 2> Operands;
	public:
		virtual LoopHierarchyKind getKind() const { return LoopHierarchyKind::InstExpression; }
		static bool classof(const GreenNode *Node) { return LoopHierarchyKind::InstExpression == Node->getKind(); }
		static bool classof(const GreenInstExpr *) { return true; }
	};

	class GreenSCEVExpr : public GreenExpr {
		const SCEV*Expr;
	public:
		virtual LoopHierarchyKind getKind() const { return LoopHierarchyKind::SCEVExpression; }
		static bool classof(const GreenNode *Node) { return LoopHierarchyKind::SCEVExpression == Node->getKind(); }
		static bool classof(const GreenInstExpr *) { return true; }
	};

	// Expression tree leaf
	class GreenConstExpr : public GreenExpr {
		Constant *Const;

		GreenConstExpr(Constant *Const) : Const(Const) {}
	public:
		static const GreenConstExpr *create(Constant *Const) { return new GreenConstExpr(Const); }
		
		LoopHierarchyKind getKind() const override { return LoopHierarchyKind::ConstExpr; }
		static bool classof(const GreenNode *Node) { return LoopHierarchyKind::ConstExpr == Node->getKind(); }
		static bool classof(const GreenConstExpr *) { return true; }

		 ArrayRef <const GreenNode * const> getChildren() const { return ArrayRef <const GreenNode * const>(); }
	};


	

	class	RedBlock : public RedNode {
		RedLoop *Parent;
	public:
		 RedNode *getParent() const override { return Parent; };
 };

	class RedStmt : public RedBlock {
		RedStmt *Green;
	public:
	};





	class RedUser : public RedNode {
	public:
	};


	class RedInst : public RedUser {
		GreenInst *Green;
		RedStmt *Parent;
	public:
		RedNode * getParent() const override { return Parent; };
	};

	class RedExpr :  public RedUser {
		RedStmt *Stmt;
		RedExpr *Parent;
		int ParentOperandNo;
	public:
		 RedNode *getParent() const override { return Parent; };
	};


	class RedConstExpr : public RedExpr {
		GreenConstExpr *Green;

		RedConstExpr(GreenConstExpr *Green) : Green(Green) {}
	public:
		const RedConstExpr *create(GreenConstExpr *Green) { return new RedConstExpr(Green); }
	};
#endif



	 ArrayRef < GreenNode * >  GreenRoot::getChildren() const  {		
		GreenNode *X = Block;
		return   {X};		
	};



	class LoopOptimizer {
	private:
		Function *F;

		LoopInfo *LI;
		ScalarEvolution *SE;

		GreenLoop *createHierarchy(Function *F) const;
		GreenLoop *createHierarchy(Loop *L) const;
		GreenStmt *createHierarchy(BasicBlock *BB) const;
		GreenInst *createInst(Instruction *I) const;
		GreenExpr *createExpr(Value *I) const;


		DenseMap <Constant *, GreenConst*> ConstCache;
		GreenConst *createGreen(Constant *C) ;


	public:
		LoopOptimizer(Function *F) : F(F) {}

		bool optimize();
		void print(raw_ostream &OS) {}
	};

	class LoopOptimizationFramework : public FunctionPass {
	private:
		std::unique_ptr<LoopOptimizer> lo;

	public :
		static char ID;
		
		LoopOptimizationFramework() : FunctionPass(ID){}

		/// @name FunctionPass interface
		//@{
		void getAnalysisUsage(AnalysisUsage &AU) const override {
			AU.addRequired<LoopInfoWrapperPass>();
			AU.addRequiredTransitive<ScalarEvolutionWrapperPass>();
			AU.addRequired<DominatorTreeWrapperPass>();
			AU.addRequired<OptimizationRemarkEmitterWrapperPass>();
			AU.addRequiredTransitive<AAResultsWrapperPass>();
		}
		void releaseMemory() override { lo.reset(); }
		bool runOnFunction(Function &F) override {
			lo = make_unique<LoopOptimizer>(&F);
			return lo->optimize();
		}
		void print(raw_ostream &OS, const Module *) const override {
			lo->print(OS);
		}
		//@}
	};


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

GreenInst *LoopOptimizer::createInst(Instruction *I) const {
	if (auto Store = dyn_cast<Instruction>(I)) {
		auto *Op1 = createExpr(I->getOperand(0));
		auto *Op2 = createExpr(I->getOperand(0));
		//auto *Stmt = GreenInst::create(I->getOpcode(), { Op1, Op2 }, I);
	}
	llvm_unreachable("unimplemented");
}

GreenExpr *LoopOptimizer::createExpr(Value *I) const {
	if (auto C = dyn_cast<Constant>(I)) {
		// TODO: Lookup cache
		//auto Green = GreenExpr::create(C);
		//return Green;
	}
	llvm_unreachable("unimplemented");
}


GreenConst *LoopOptimizer::createGreen(Constant *C) {
	auto &Result =	ConstCache[C];
	if (!Result)
		 Result= GreenConst::create(C);
return Result;
}

bool LoopOptimizer::optimize() {
	return true;
}


INITIALIZE_PASS_BEGIN(LoopOptimizationFramework, "lof",	"Loop Optimization Framework", false,	false);
INITIALIZE_PASS_DEPENDENCY(AAResultsWrapperPass);
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass);
INITIALIZE_PASS_DEPENDENCY(DominatorTreeWrapperPass);
INITIALIZE_PASS_DEPENDENCY(ScalarEvolutionWrapperPass);
INITIALIZE_PASS_DEPENDENCY(OptimizationRemarkEmitterWrapperPass);
INITIALIZE_PASS_END(LoopOptimizationFramework, "lof", "Loop Optimization Framework", false, false); 
