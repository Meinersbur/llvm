add_llvm_library(LLVMOption
  Arg.cpp
  ArgList.cpp
  Option.cpp
  OptTable.cpp
  LINK_LIBS LLVMSupport
  )

#target_link_libraries(LLVMOption LLVMSupport)
