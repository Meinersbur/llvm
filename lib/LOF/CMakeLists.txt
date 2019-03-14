add_llvm_library(LLVMLOF
  LoopTree.cpp
  LOF.cpp

  ADDITIONAL_HEADER_DIRS
    ${LLVM_MAIN_INCLUDE_DIR}/llvm/LOF
)
