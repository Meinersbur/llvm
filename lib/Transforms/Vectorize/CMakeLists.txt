set(LLVM_NEXT_DEPENDS intrinsics_gen)

add_llvm_library(LLVMVectorize
  BBVectorize.cpp
  Vectorize.cpp
  LoopVectorize.cpp
  SLPVectorizer.cpp
  )
