//===- llvm/PassManager.h - Container for Passes ----------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the PassManager class.  This class is used to hold,
// maintain, and optimize execution of Passes.  The PassManager class ensures
// that analysis results are available before a pass runs, and that Pass's are
// destroyed when the PassManager is destroyed.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_PASSMANAGER_H
#define LLVM_PASSMANAGER_H

#include "llvm/Pass.h"
#include "llvm/Support/CBindingWrapping.h"

namespace llvm {

class Pass;
class Module;

class PassManagerImpl;
class FunctionPassManagerImpl;

/// PassManagerBase - An abstract interface to allow code to add passes to
/// a pass manager without having to hard-code what kind of pass manager
/// it is.
class PassManagerBase {
public:
  virtual ~PassManagerBase();

  /// add - Add a pass to the queue of passes to run.  This passes ownership of
  /// the Pass to the PassManager.  When the PassManager is destroyed, the pass
  /// will be destroyed as well, so there is no need to delete the pass.  This
  /// implies that all passes MUST be allocated with 'new'.
  virtual void add(Pass *P) = 0;
#ifdef MOLLY
  //FIXME: This is an extremely ugly hack to force other passes to preserve passes they don't know about (here e.g.: polly::IndependentBlocks preserving molly::FieldDetection)
  //virtual void add(Pass *P, bool preserve/* = false*/) = 0;
  //virtual void unpreserve(Pass*) = 0;
  //template<typename T>
  //void unpreserve() { unpreserve(&T::ID); }
#endif
};

/// PassManager manages ModulePassManagers
class PassManager : public PassManagerBase {
public:

  PassManager();
  ~PassManager();

  /// add - Add a pass to the queue of passes to run.  This passes ownership of
  /// the Pass to the PassManager.  When the PassManager is destroyed, the pass
  /// will be destroyed as well, so there is no need to delete the pass.  This
  /// implies that all passes MUST be allocated with 'new'.
  void add(Pass *P);

  /// run - Execute all of the passes scheduled for execution.  Keep track of
  /// whether any of the passes modifies the module, and if so, return true.
  bool run(Module &M);

private:
  /// PassManagerImpl_New is the actual class. PassManager is just the
  /// wraper to publish simple pass manager interface
  PassManagerImpl *PM;

#ifdef MOLLY
  void add(Pass *P, bool preserve/* = false*/);
  void unpreserve(Pass*);
#endif
};

/// FunctionPassManager manages FunctionPasses and BasicBlockPassManagers.
class FunctionPassManager : public PassManagerBase {
public:
  /// FunctionPassManager ctor - This initializes the pass manager.  It needs,
  /// but does not take ownership of, the specified Module.
  explicit FunctionPassManager(Module *M);
  ~FunctionPassManager();

  /// add - Add a pass to the queue of passes to run.  This passes
  /// ownership of the Pass to the PassManager.  When the
  /// PassManager_X is destroyed, the pass will be destroyed as well, so
  /// there is no need to delete the pass.
  /// This implies that all passes MUST be allocated with 'new'.
  void add(Pass *P);

  /// run - Execute all of the passes scheduled for execution.  Keep
  /// track of whether any of the passes modifies the function, and if
  /// so, return true.
  ///
  bool run(Function &F);

  /// doInitialization - Run all of the initializers for the function passes.
  ///
  bool doInitialization();

  /// doFinalization - Run all of the finalizers for the function passes.
  ///
  bool doFinalization();

private:
  FunctionPassManagerImpl *FPM;
  Module *M;

#ifdef MOLLY
public:
  void add(Pass *P, bool preserve/* = false*/) { assert(!preserve && "Not yet supported for FPM"); add(P); }
  //void unpreserve(Pass*) { }
#endif
};

// Create wrappers for C Binding types (see CBindingWrapping.h).
DEFINE_STDCXX_CONVERSION_FUNCTIONS(PassManagerBase, LLVMPassManagerRef)

} // End llvm namespace

#endif
