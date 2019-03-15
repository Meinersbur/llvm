#ifndef LLVM_LOF_GREENTREE_H
#define LLVM_LOF_GREENTREE_H

#include "llvm/Support/raw_ostream.h"
#include <vector>
#include "llvm/ADT/ArrayRef.h"
#include "llvm/IR/Instruction.h"


namespace llvm {
	enum class LoopHierarchyKind {
		Root,
		Sequence,

		// Blocks
		Stmt,
		Loop,

		// Instructions
		Set,
		Load,
		Store,
		Call,

		// Expressions
		Const, // Constant/Literal
		Reg,  // Register/Value read
		GEP,
		ICmp,
		Op, // Operation

		Block_First= Stmt,
		Block_Last = Loop,

		Inst_First = Set,
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



	class GreenSequence final : public GreenNode {
	private:
		// TODO: Do the same allocation trick.; Sence GreenSequence is always part of either a GreenRoot or GreenLoop, can also allocate in their memory
		std::vector<GreenBlock *> Blocks;

	public:
		GreenSequence (ArrayRef<GreenBlock*> Blocks): Blocks(Blocks) {}
		virtual ~GreenSequence() {};

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Sequence; }
		static bool classof(const GreenNode *Node) { return  Node->getKind() == LoopHierarchyKind::Sequence; }
		static bool classof(const GreenSequence *) {	return true;	}

		virtual ArrayRef < GreenNode * > getChildren() const override ;

		static 	GreenSequence *create(ArrayRef<GreenBlock*> Blocks) {  return new GreenSequence(Blocks); }
	};






	class GreenRoot : public GreenNode {
	private :
		GreenSequence *Sequence;

	public:
		GreenRoot (GreenSequence *Sequence): Sequence(Sequence) {}
		virtual ~GreenRoot() {};

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Root; }
		static bool classof(const GreenNode *Node) { return  Node->getKind() == LoopHierarchyKind::Root; }
		static bool classof(const GreenRoot *) {	return true;	}

		virtual ArrayRef < GreenNode * > getChildren() const override ;

		static 	GreenRoot *create(GreenSequence *Sequence) {  return new GreenRoot(Sequence); }
	}; 









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



	class GreenLoop final : public GreenBlock {
	private:
		GreenSequence *Sequence;

	public:
		GreenLoop (GreenSequence *Sequence): Sequence(Sequence) {}
		virtual ~GreenLoop() {};

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Loop; }
		static bool classof(const GreenNode *Node) {	return Node->getKind() == LoopHierarchyKind::Loop; 	}
		static bool classof(const GreenLoop *) {	return true;	}

		virtual ArrayRef <GreenNode * > getChildren() const override ;

		static 	GreenLoop *create(GreenSequence *Sequence) {  return new GreenLoop(Sequence); }
	};





	class GreenStmt final : public GreenBlock {
	private:
		std::vector<GreenInst*> Insts;
	public:
		GreenStmt(ArrayRef<GreenInst*> Insts) : Insts(Insts) {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Stmt; }
		static bool classof(const GreenNode *Node) {	return Node->getKind() == LoopHierarchyKind::Stmt; 	}
		static bool classof(const GreenStmt *) {	return true;	}

		virtual ArrayRef <GreenNode * > getChildren() const override { return {}; };

		static GreenStmt*create(ArrayRef<GreenInst*> Insts) { return new GreenStmt(Insts); };
	};



	class GreenInst  : public GreenNode {
	private:
	public:
		static bool classof(const GreenNode *Node)  {	auto Kind =Node-> getKind(); return LoopHierarchyKind::Inst_First <= Kind && Kind <= LoopHierarchyKind::Inst_Last;	}
		static bool classof(const GreenInst *) {	return true;	}
	};



	class GreenStore  : public GreenInst {
	private:
		GreenExpr *Operands [2];


	public:
		GreenStore(GreenExpr *Val, GreenExpr *Ptr) : Operands{Val,Ptr} {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Store; }
		static bool classof(const GreenNode *Node) { return Node->getKind() == LoopHierarchyKind::Store; }
		static bool classof(const GreenStore *) { return true; }

		GreenExpr * getVal() const {return Operands[0]; }
		//GreenExpr * &getVal()  {return Operands[0]; }
		GreenExpr * getPtr() const {return Operands[1]; }
		//GreenExpr * &getPtr()  {return Operands[1]; }

		virtual ArrayRef <GreenNode * > getChildren() const override ;

		static GreenStore*create(GreenExpr *Val, GreenExpr *Ptr) { return new GreenStore(Val, Ptr); };
	};





	class GreenSet  : public GreenInst {
	private:
		// For now, the llvm::Instruction is the 'name' of the register that is set.
		Instruction *Var;

		GreenExpr *Val;


	public:
		GreenSet(Instruction *Var, GreenExpr *Val) : Var{Var}, Val{Val} {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Set; }
		static bool classof(const GreenNode *Node) { return Node->getKind() == LoopHierarchyKind::Set; }
		static bool classof(const GreenStore *) { return true; }

		GreenExpr * getVal() const { return Val; }
		//GreenExpr * &getVal()  {return Val; }

		virtual ArrayRef <GreenNode * > getChildren() const override;

		static GreenSet*create(Instruction *Var, GreenExpr *Val) { return new GreenSet(Var, Val); };
	};








	class GreenExpr: public GreenNode {
	private:
	public:
		static bool classof(const GreenNode *Node)  {	auto Kind =Node-> getKind(); return LoopHierarchyKind::Expr_First <= Kind && Kind <= LoopHierarchyKind::Expr_Last;	}
		static bool classof(const GreenInst *) {	return true;	}
	};

	// Expression tree leaf
	class GreenConst final : public GreenExpr {
		Constant *Const;
	public:
		GreenConst(Constant *Const) : Const(Const) {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Const; }
		static bool classof(const GreenNode *Node) {	return Node->getKind() == LoopHierarchyKind::Const; 	}
		static bool classof(const GreenConst *) {	return true;	}

		virtual ArrayRef <GreenNode * > getChildren() const override { return {}; };

		static  GreenConst *create(Constant *C) { return new GreenConst(C); }
	};




	// Expression tree leaf
	class GreenReg final : public GreenExpr {
		Value *Val;
	public:
		GreenReg(Value *V) : Val(V) {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Reg; }
		static bool classof(const GreenNode *Node) {	return Node->getKind() == LoopHierarchyKind::Reg; 	}
		static bool classof(const GreenReg *) {	return true;	}

		virtual ArrayRef <GreenNode * > getChildren() const override { return {}; };

		static  GreenReg *create(Value *V) { return new GreenReg(V); }
	};




	class GreenGEP final : public GreenExpr {
	private:
		// TODO: Do the trick to allocate the variable array after the object
		SmallVector<GreenExpr *, 3> Operands;

	public:
		// TODO: Make private
		GreenGEP(ArrayRef<GreenExpr*>Operands ) : Operands(Operands.begin(), Operands.end()) {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::GEP; }
		static bool classof(const GreenNode *Node) { return Node->getKind() == LoopHierarchyKind::GEP; 	}
		static bool classof(const GreenGEP *) {	return true;	}

		ArrayRef<GreenExpr*> getOperands() const { return Operands; }
		GreenExpr *getBase() const { assert(Operands.size() >=1); return Operands[0]; }
		ArrayRef<GreenExpr*> getIndices() const { return ArrayRef<GreenExpr*>(Operands).drop_front(1) ; }

		virtual ArrayRef <GreenNode * > getChildren() const override;

		static  GreenGEP *create(ArrayRef<GreenExpr*>Operands) { return new GreenGEP(Operands); }
	};







	class GreenICmp final : public GreenExpr {
	private:
		// TODO: Use a mixin for 
		GreenExpr *Operands [2];
	public:
		GreenICmp(GreenExpr *LHS, GreenExpr *RHS) : Operands{LHS,RHS} {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::ICmp; }
		static bool classof(const GreenNode *Node) { return Node->getKind() == LoopHierarchyKind::ICmp; 	}
		static bool classof(const GreenICmp *) {	return true;	}

		GreenExpr * getLHS() const { return Operands[0]; }
		GreenExpr * getRHS() const { return Operands[1]; }

		virtual ArrayRef <GreenNode * > getChildren() const override;

		static  GreenICmp *create(GreenExpr *LHS, GreenExpr *RHS) { return new GreenICmp(LHS,RHS); }
	};



}

#endif /* LLVM_LOF_GREENTREE_H */

