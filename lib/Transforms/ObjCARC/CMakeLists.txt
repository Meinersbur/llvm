set(LLVM_NEXT_DEPENDS intrinsics_gen)

add_llvm_library(LLVMObjCARCOpts
  ObjCARC.cpp
  ObjCARCOpts.cpp
  ObjCARCExpand.cpp
  ObjCARCAPElim.cpp
  ObjCARCAliasAnalysis.cpp
  ObjCARCUtil.cpp
  ObjCARCContract.cpp
  DependencyAnalysis.cpp
  ProvenanceAnalysis.cpp
  )
