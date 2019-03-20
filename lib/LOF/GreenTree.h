#ifndef LLVM_LOF_GREENTREE_H
#define LLVM_LOF_GREENTREE_H

#include "llvm/Support/raw_ostream.h"
#include <vector>
#include "llvm/ADT/ArrayRef.h"
#include "llvm/IR/Instruction.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/IRBuilder.h"


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



	using ActiveRegsTy = DenseMap<Value*,Value*>;


	



		// Immutable (sub-)tree, only contains references to its children
	class GreenNode {
	public:
		virtual ~GreenNode() {};

		virtual LoopHierarchyKind getKind() const = 0;
		static bool classof(const GreenNode *) {	return true;	}

		void dump() const { printText(errs()); }
		virtual void printLine(raw_ostream &OS) const {}
		virtual void printText(raw_ostream &OS) const { printLine(OS); OS << '\n'; }

		virtual ArrayRef <const  GreenNode * > getChildren() const = 0;
	};



	class GreenSequence final : public GreenNode {
	private:
		// TODO: Do the same allocation trick.; Sence GreenSequence is always part of either a GreenRoot or GreenLoop, can also allocate in their memory
		std::vector<const GreenBlock *> Blocks;

	public:
		GreenSequence (ArrayRef<const GreenBlock*> Blocks): Blocks(Blocks) {}
		virtual ~GreenSequence() {};

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Sequence; }
		static bool classof(const GreenNode *Node) { return  Node->getKind() == LoopHierarchyKind::Sequence; }
		static bool classof(const GreenSequence *) {	return true;	}

		virtual ArrayRef <const  GreenNode * > getChildren() const override ;

		iterator_range<	 decltype(Blocks)::const_iterator>  blocks() const { return llvm::make_range (Blocks.begin(), Blocks.end()) ; }

		static 	GreenSequence *create(ArrayRef<const GreenBlock*> Blocks) {  return new GreenSequence(Blocks); }

		 void codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const;
	};






	class GreenRoot : public GreenNode {
	private :
		const GreenSequence *Sequence;

	public:
		GreenRoot (const GreenSequence *Sequence): Sequence(Sequence) {}
		GreenRoot *clone() const { auto That =create(Sequence); return That; }
		virtual ~GreenRoot() {};

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Root; }
		static bool classof(const GreenNode *Node) { return  Node->getKind() == LoopHierarchyKind::Root; }
		static bool classof(const GreenRoot *) {	return true;	}

		virtual ArrayRef <const  GreenNode * > getChildren() const override ;

		const GreenSequence *getSequence()const { return Sequence; }
		void setSequence(const GreenSequence *Sequence) { this->Sequence=Sequence; }

		static 	GreenRoot *create(const  GreenSequence *Sequence) {  return new GreenRoot(  Sequence); }
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
	
		virtual void codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const=0;
	}; 



	class GreenLoop final : public GreenBlock {
	private:
		GreenExpr *Iterations;
		Instruction *IndVar;
		GreenSequence *Sequence;

		Loop *LoopInfoLoop;

		bool ExecuteInParallel = false;

		StructType *getIdentTy(Module *M) const;
		Function * codegenSubfunc(Module *M)const 			;
	public:
		GreenLoop (GreenExpr *Iterations, Instruction *IndVar,GreenSequence *Sequence,Loop* LoopInfoLoop): Iterations(Iterations), IndVar(IndVar), Sequence(Sequence), LoopInfoLoop(LoopInfoLoop) {}
		 GreenLoop *clone() const { auto That = create(Iterations,IndVar,Sequence,nullptr ); That->ExecuteInParallel= this->ExecuteInParallel; return That; }
		virtual ~GreenLoop() {};

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Loop; }
		static bool classof(const GreenNode *Node) {	return Node->getKind() == LoopHierarchyKind::Loop; 	}
		static bool classof(const GreenLoop *) {	return true;	}

		virtual ArrayRef <const GreenNode * > getChildren() const override ;
		Loop *getLoopInfoLoop() const {return LoopInfoLoop;}

		bool isExecutedInParallel() const {return ExecuteInParallel;}
		void setExecuteInParallel(bool ExecuteInParallel = true) { this->ExecuteInParallel= ExecuteInParallel;  }

		static 	GreenLoop *create(GreenExpr *Iterations,Instruction *IndVar,GreenSequence *Sequence,Loop* LoopInfoLoop) {  return new GreenLoop(Iterations,IndVar, Sequence, LoopInfoLoop); }
	
		void codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const override;
	};





	class GreenStmt final : public GreenBlock {
	private:
		std::vector<GreenInst*> Insts;
	public:
		GreenStmt(ArrayRef<GreenInst*> Insts) : Insts(Insts) {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Stmt; }
		static bool classof(const GreenNode *Node) {	return Node->getKind() == LoopHierarchyKind::Stmt; 	}
		static bool classof(const GreenStmt *) {	return true;	}

		virtual ArrayRef <const GreenNode * > getChildren() const override { return {}; };

		static GreenStmt*create(ArrayRef<GreenInst*> Insts) { return new GreenStmt(Insts); };

		void codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const override;
	};



	class GreenInst  : public GreenNode {
	private:
	public:
		static bool classof(const GreenNode *Node)  {	auto Kind =Node-> getKind(); return LoopHierarchyKind::Inst_First <= Kind && Kind <= LoopHierarchyKind::Inst_Last;	}
		static bool classof(const GreenInst *) {	return true;	}

		virtual void codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const =0;
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

		virtual ArrayRef <const GreenNode * > getChildren() const override ;

		static GreenStore*create(GreenExpr *Val, GreenExpr *Ptr) { return new GreenStore(Val, Ptr); };

		 void codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const override;
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

		virtual ArrayRef <const GreenNode * > getChildren() const override;

		static GreenSet*create(Instruction *Var, GreenExpr *Val) { return new GreenSet(Var, Val); };

		void codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const override;
	};








	class GreenExpr: public GreenNode {
	private:
	public:
		static bool classof(const GreenNode *Node)  {	auto Kind =Node-> getKind(); return LoopHierarchyKind::Expr_First <= Kind && Kind <= LoopHierarchyKind::Expr_Last;	}
		static bool classof(const GreenInst *) {	return true;	}

		virtual Value* codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const =0;
	};


	// Expression tree leaf
	class GreenConst final : public GreenExpr {
		Constant *Const;
	public:
		GreenConst(Constant *Const) : Const(Const) {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Const; }
		static bool classof(const GreenNode *Node) {	return Node->getKind() == LoopHierarchyKind::Const; 	}
		static bool classof(const GreenConst *) {	return true;	}

		virtual ArrayRef <const GreenNode * > getChildren() const override { return {}; };

		static  GreenConst *create(Constant *C) { return new GreenConst(C); }

		 Value* codegen(IRBuilder<> &Builder , ActiveRegsTy &ActiveRegs)const override;
	};




	// Expression tree leaf
	class GreenReg final : public GreenExpr {
		Value *Var; // Instruction, Global or Argument
	public:
		GreenReg(Value *Var) : Var(Var) {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::Reg; }
		static bool classof(const GreenNode *Node) {	return Node->getKind() == LoopHierarchyKind::Reg; 	}
		static bool classof(const GreenReg *) {	return true;	}

		virtual ArrayRef <const GreenNode * > getChildren() const override { return {}; };

		static  GreenReg *create(Value *Var) { return new GreenReg(Var); }

		Value* codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const override;
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

		virtual ArrayRef <const GreenNode * > getChildren() const override;

		static  GreenGEP *create(ArrayRef<GreenExpr*>Operands) { return new GreenGEP(Operands); }

		Value* codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const override;
	};







	class GreenICmp final : public GreenExpr {
	private:
		// TODO: Use a mixin for 
		GreenExpr *Operands [2];

		ICmpInst::Predicate Predicate;

	public:
		GreenICmp(ICmpInst::Predicate Predicate, GreenExpr *LHS, GreenExpr *RHS ) : Operands{LHS,RHS} , Predicate(Predicate) {}

		virtual LoopHierarchyKind getKind() const override {return LoopHierarchyKind::ICmp; }
		static bool classof(const GreenNode *Node) { return Node->getKind() == LoopHierarchyKind::ICmp; 	}
		static bool classof(const GreenICmp *) {	return true;	}

		GreenExpr * getLHS() const { return Operands[0]; }
		GreenExpr * getRHS() const { return Operands[1]; }

		virtual ArrayRef <const GreenNode * > getChildren() const override;

		static  GreenICmp *create(ICmpInst::Predicate Predicate, GreenExpr *LHS, GreenExpr *RHS) { return new GreenICmp(Predicate,LHS,RHS); }

		Value* codegen(IRBuilder<> &Builder, ActiveRegsTy &ActiveRegs )const override;
	};
}

#endif /* LLVM_LOF_GREENTREE_H */

