set(LLVM_LINK_COMPONENTS ${LLVM_TARGETS_TO_BUILD} bitreader asmparser bitwriter instrumentation scalaropts ipo vectorize polly molly)
include_directories( ${LLVM_EXTERNAL_POLLY_SOURCE_DIR}/include ${LLVM_BINARY_DIR}/tools/polly/include )
include_directories( ${LLVM_EXTERNAL_MOLLY_SOURCE_DIR}/include )

add_llvm_tool(opt
  AnalysisWrappers.cpp
  GraphPrinters.cpp
  PrintSCC.cpp
  opt.cpp
  )
