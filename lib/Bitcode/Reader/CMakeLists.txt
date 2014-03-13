if (NOT BUILD_INDEP_TABLEGEN)
set(LLVM_NEXT_DEPENDS intrinsics_gen)
endif ()

add_llvm_library(LLVMBitReader
  BitReader.cpp
  BitcodeReader.cpp
  BitstreamReader.cpp
  )
