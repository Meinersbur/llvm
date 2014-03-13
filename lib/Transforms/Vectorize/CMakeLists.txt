if (NOT BUILD_INDEP_TABLEGEN)
set(LLVM_NEXT_DEPENDS intrinsics_gen)
endif()

add_llvm_library(LLVMVectorize
  BBVectorize.cpp
  Vectorize.cpp
  LoopVectorize.cpp
  SLPVectorizer.cpp
  )
