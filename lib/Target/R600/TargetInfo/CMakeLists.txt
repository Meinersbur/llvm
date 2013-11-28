set(LLVM_NEXT_DEPENDS intrinsics_gen)

add_llvm_library(LLVMR600Info
  AMDGPUTargetInfo.cpp
  )
