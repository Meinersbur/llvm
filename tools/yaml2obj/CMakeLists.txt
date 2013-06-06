set(LLVM_LINK_COMPONENTS object)

add_llvm_utility(yaml2obj
  yaml2obj.cpp
  yaml2coff.cpp
  LINK_LIBS LLVMSupport
  )
