
set(not_LIBS LLVMSupport)
if( MINGW )
  list(APPEND not_LIBS imagehlp psapi)
endif( MINGW )
if( LLVM_ENABLE_THREADS AND HAVE_LIBPTHREAD )
  list(APPEND not_LIBS pthread)
endif()

add_llvm_utility(not
  not.cpp
  LINK_LIBS ${not_LIBS}
  )
