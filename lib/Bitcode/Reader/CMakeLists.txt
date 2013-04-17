set(LLVM_NEXT_DEPENDS intrinsics_gen)

add_llvm_library(LLVMBitReader
  BitReader.cpp
  BitcodeReader.cpp
  BitstreamReader.cpp
  )
