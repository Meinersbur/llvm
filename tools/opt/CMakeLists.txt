set(LLVM_LINK_COMPONENTS bitreader asmparser bitwriter instrumentation scalaropts ipo vectorize polly molly)
include_directories( ${LLVM_EXTERNAL_POLLY_SOURCE_DIR}/include ${LLVM_BINARY_DIR}/tools/polly/include )

add_llvm_tool(opt
  AnalysisWrappers.cpp
  GraphPrinters.cpp
  PrintSCC.cpp
  opt.cpp
  )
