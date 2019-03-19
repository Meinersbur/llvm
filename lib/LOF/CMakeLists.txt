add_llvm_library(LLVMLOF
  GreenTree.cpp
  RedTree.cpp
  LoopOpt.cpp
  LoopOptPass.cpp

  ADDITIONAL_HEADER_DIRS
    ${LLVM_MAIN_INCLUDE_DIR}/llvm/LOF
)
