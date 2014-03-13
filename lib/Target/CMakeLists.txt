add_llvm_library(LLVMTarget
  Target.cpp
  TargetIntrinsicInfo.cpp
  TargetJITInfo.cpp
  TargetLibraryInfo.cpp
  TargetLoweringObjectFile.cpp
  TargetMachine.cpp
  TargetMachineC.cpp
  TargetSubtargetInfo.cpp
  )

if (NOT BUILD_INDEP_TABLEGEN)
list(APPEND LLVM_COMMON_DEPENDS intrinsics_gen)
endif ()

foreach(t ${LLVM_TARGETS_TO_BUILD})
  message(STATUS "Targeting ${t}")
  add_subdirectory(${t})
endforeach()
