
set(FileCheck_LIBS LLVMSupport)
#target_link_libraries(FileCheck LLVMSupport)
if( MINGW )
  list(APPEND FileCheck_LIBS imagehlp psapi)
  #target_link_libraries(FileCheck imagehlp psapi)
endif( MINGW )
if( LLVM_ENABLE_THREADS AND HAVE_LIBPTHREAD )
  list(APPEND FileCheck_LIBS pthread)
  #target_link_libraries(FileCheck pthread)
endif()

add_llvm_utility(FileCheck
  FileCheck.cpp
  LINK_LIBS ${FileCheck_LIBS}
  )
