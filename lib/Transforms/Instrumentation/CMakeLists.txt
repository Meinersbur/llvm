if (NOT BUILD_INDEP_TABLEGEN)
set(LLVM_NEXT_DEPENDS intrinsics_gen)
endif ()

add_llvm_library(LLVMInstrumentation
  AddressSanitizer.cpp
  BoundsChecking.cpp
  DataFlowSanitizer.cpp
  DebugIR.cpp
  GCOVProfiling.cpp
  MemorySanitizer.cpp
  Instrumentation.cpp
  ThreadSanitizer.cpp
  )
