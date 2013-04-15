
set(FileUpdate_LIBS LLVMSupport)
if( MINGW )
  list(APPEND FileUpdate_LIBS imagehlp psapi)
endif( MINGW )
if( LLVM_ENABLE_THREADS AND HAVE_LIBPTHREAD )
  list(APPEND FileUpdate_LIBS pthread)
endif()

add_llvm_utility(FileUpdate
  FileUpdate.cpp
  LINK_LIBS ${FileUpdate_LIBS}
  )
