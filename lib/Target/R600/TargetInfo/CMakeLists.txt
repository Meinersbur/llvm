include_directories( ${CMAKE_CURRENT_BINARY_DIR}/.. ${CMAKE_CURRENT_SOURCE_DIR}/.. )

set(LLVM_NEXT_DEPENDS intrinsics_gen)

add_llvm_library(LLVMR600Info
  AMDGPUTargetInfo.cpp
  )
