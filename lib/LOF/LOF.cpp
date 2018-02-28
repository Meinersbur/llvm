
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

	class LoopOptimizer {
		Function *F;

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
		void print(raw_ostream &OS, const Module *) const override{
			lo->print(OS);
		}
		//@}
	};

	bool LoopOptimizer::optimize() {
		return true;
	}
}



INITIALIZE_PASS_BEGIN(LoopOptimizationFramework, "lof",	"Loop Optimization Framework", false,	false);
INITIALIZE_PASS_DEPENDENCY(AAResultsWrapperPass);
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass);
INITIALIZE_PASS_DEPENDENCY(DominatorTreeWrapperPass);
INITIALIZE_PASS_DEPENDENCY(ScalarEvolutionWrapperPass);
INITIALIZE_PASS_DEPENDENCY(OptimizationRemarkEmitterWrapperPass);
INITIALIZE_PASS_END(LoopOptimizationFramework, "lof", "Loop Optimization Framework", false, false); 
