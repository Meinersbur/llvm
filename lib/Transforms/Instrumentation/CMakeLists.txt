set(LLVM_NEXT_DEPENDS intrinsics_gen)

add_llvm_library(LLVMInstrumentation
  AddressSanitizer.cpp
  BoundsChecking.cpp
  DataFlowSanitizer.cpp
  DebugIR.cpp
  GCOVProfiling.cpp
  MemorySanitizer.cpp
  Instrumentation.cpp
  ProfilingUtils.cpp
  ThreadSanitizer.cpp
  )
