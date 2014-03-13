if (NOT BUILD_INDEP_TABLEGEN)
set(LLVM_NEXT_DEPENDS intrinsics_gen)
endif ()

add_llvm_library(LLVMipa
  CallGraph.cpp
  CallGraphSCCPass.cpp
  CallPrinter.cpp
  FindUsedTypes.cpp
  GlobalsModRef.cpp
  IPA.cpp
  InlineCost.cpp
  )
