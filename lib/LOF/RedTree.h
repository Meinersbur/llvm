#ifndef LLVM_LOF_REDTREE_H
#define LLVM_LOF_REDTREE_H

#include "GreenTree.h"
#include <vector>

namespace llvm {

	/// Node in an immutable tree, contains reference to parent and corresponding green node (which stores the children) 
	class RedNode {
	private:
		RedNode *Parent;
		GreenNode *Green;
		
		bool ChildrenAvailable = false;
		mutable std::vector<RedNode *> Children;

	protected:
		RedNode(RedNode*Parent, GreenNode *Green): Parent(Parent),Green(Green) {
			auto NChildren = Green->getChildren().size();
			Children.resize(NChildren);
			for (int i = 0; i<NChildren;i+=1)
				Children[i] = nullptr;
		}

	public:
		virtual ~RedNode() {};

		virtual LoopHierarchyKind getKind() const { return getGreen()->getKind();}
		static bool classof(const RedNode *) {	return true; }

		void dump() const { printText(errs()); }
		virtual void printLine(raw_ostream &OS) const { getGreen()->printLine(OS); }
		virtual void printText(raw_ostream &OS) const { getGreen()->printText(OS); }

		RedNode  *getParent() const {return Parent;}
		GreenNode*getGreen()  const {return Green;}

		int getNumChildren() const {  return Green->getChildren().size(); }
		RedNode *getChild(int i) const { 
				auto &Child = Children[i];
				if (!Child) {
					Child = nullptr;
				}
				return Child;
		}
	};






	

	class RedSequence final : public RedNode {
	private:
	public:
		RedSequence(RedNode*Parent, GreenSequence *Green) : RedNode(Parent,Green) {}
		virtual ~RedSequence() {};

		static bool classof(const RedNode *Node) { return GreenSequence::classof(Node->getGreen()); }
		static bool classof(const RedSequence *) {	return true;	}

		GreenSequence* getGreen() const { return static_cast<GreenSequence*>( RedNode::getGreen());}
	};






	class RedRoot: public RedNode {
	private:
	public:
		RedRoot( GreenRoot *Green) : RedNode(nullptr, Green) {}
		virtual ~RedRoot() {};

		static bool classof(const RedNode *Node) { return GreenRoot::classof(Node->getGreen()); }
		static bool classof(const RedRoot *) {	return true;	}

		GreenRoot* getGreen() const {return static_cast<GreenRoot*>( RedNode::getGreen());}
	};







	
	class RedBlock : public RedNode {
	private:
	public:
		RedBlock(RedNode*Parent, GreenBlock *Green) : RedNode(Parent,Green) {}


		static bool classof(const RedNode *Node) { return GreenBlock::classof(Node->getGreen()); }
		static bool classof(const RedBlock *) {	return true;	}

		GreenBlock* getGreen() const {return static_cast<GreenBlock*>( RedNode::getGreen());}

	
	};





	class RedLoop final : public RedBlock {
	private:
	public:
		RedLoop(RedNode *Parent, GreenLoop*Green) : RedBlock(Parent,Green) {}

		static bool classof(const RedNode *Node) {return  GreenLoop::classof(Node->getGreen()); }
		static bool classof(const RedLoop *) {	return true;	}

		GreenLoop* getGreen() const {return static_cast<GreenLoop*>(RedBlock:: getGreen());}
	};





	class RedStmt final : public RedBlock {
	private:
	public:
		RedStmt(RedNode *Parent, GreenStmt*Green) : RedBlock(Parent,Green) {}

		static bool classof(const RedNode *Node) {return  GreenStmt::classof(Node->getGreen()); }
		static bool classof(const RedStmt *) {	return true;	}

		GreenStmt* getGreen() const {return static_cast<GreenStmt*>(RedBlock:: getGreen());}
	};




	class RedInst  : public RedNode {
	private:
	public:
		RedInst(RedNode *Parent, GreenInst*Green) : RedNode(Parent,Green) {}

		static bool classof(const RedNode *Node) {return  GreenInst::classof(Node->getGreen()); }
		static bool classof(const RedInst *) {	return true;	}

		GreenInst* getGreen() const {return static_cast<GreenInst*>(RedNode:: getGreen());}
	};






	class RedStore final : public RedInst {
	private:
	public:
		RedStore(RedNode *Parent, GreenStore*Green) : RedInst(Parent,Green) {}

		static bool classof(const RedNode *Node) {return  GreenStore::classof(Node->getGreen()); }
		static bool classof(const RedStore *) {	return true;	}

		GreenStore* getGreen() const {return static_cast<GreenStore*>( RedInst:: getGreen());}
	};






	class RedSet final : public RedInst {
	private:
	public:
		RedSet(RedNode *Parent, GreenStore*Green) : RedInst(Parent,Green) {}

		static bool classof(const RedNode *Node) {return  GreenSet::classof(Node->getGreen()); }
		static bool classof(const RedSet *) {	return true;	}

		GreenSet* getGreen() const {return static_cast<GreenSet*>(RedInst:: getGreen());}
	};








	class RedExpr : public RedNode {
	private: 
	public:
		RedExpr(RedNode *Parent, GreenExpr*Green) : RedNode(Parent,Green) {}

		static bool classof(const RedNode *Node) {return  GreenExpr::classof(Node->getGreen()); }
		static bool classof(const RedExpr *) {	return true;	}

		GreenExpr* getGreen() const {return static_cast<GreenExpr*>(RedNode:: getGreen());}
	};





	class RedConst final : public RedExpr {
	private:
	public:
		RedConst(RedNode *Parent, GreenConst*Green) : RedExpr(Parent,Green) {}

		static bool classof(const RedNode *Node) {return  GreenConst::classof(Node->getGreen()); }
		static bool classof(const RedConst *) {	return true;	}

		GreenConst* getGreen() const {return static_cast<GreenConst*>(RedExpr:: getGreen());}
	};





	class RedReg final : public RedExpr {
	private:
	public:
		RedReg(RedNode *Parent, GreenReg*Green) : RedExpr(Parent,Green) {}

		static bool classof(const RedReg *Node) { return GreenReg::classof(Node->getGreen()); }
		static bool classof(const RedConst *) {	return true;	}

		GreenReg* getGreen() const {return static_cast<GreenReg*>(RedExpr:: getGreen());}
	};








	class RedGEP final : public RedExpr {
	private:
	public:
		RedGEP(RedNode *Parent, GreenReg*Green) : RedExpr(Parent,Green) {}

		static bool classof(const RedReg *Node) { return GreenGEP::classof(Node->getGreen()); }
		static bool classof(const RedConst *) {	return true;	}

		GreenGEP* getGreen() const {return static_cast<GreenGEP*>(RedExpr:: getGreen());}
	};





	class RedICmp final : public RedExpr {
	private:
	public:
		RedICmp(RedNode *Parent, GreenReg*Green) : RedExpr(Parent,Green) {}

		static bool classof(const RedReg *Node) { return GreenICmp::classof(Node->getGreen()); }
		static bool classof(const RedConst *) {	return true;	}

		GreenICmp* getGreen() const {return static_cast<GreenICmp*>(RedExpr:: getGreen());}
	};
}

#endif /* LLVM_LOF_REDTREE_H */

