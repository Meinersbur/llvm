; RUN: llc < %s -march=ppc32 -mcpu=440fp2 | FileCheck %s

declare void @llvm.ppc.fp2.stfpd(<2 x double>, double*)
declare void @llvm.ppc.fp2.stfps(<2 x double>, float*)
declare void @llvm.ppc.fp2.stfxd(<2 x double>, double*)
declare void @llvm.ppc.fp2.stfxs(<2 x double>, float*)
declare void @llvm.ppc.fp2.stfpiw(<2 x double>, i32*)

define void @test1(<2 x double> %a, double* %b) nounwind readnone {
entry:
  call void @llvm.ppc.fp2.stfpd(<2 x double> %a, double* %b)
  ret void
; CHECK: stfpdx
}

define void @test2(<2 x double> %a, float* %b) nounwind readnone {
entry:
  call void @llvm.ppc.fp2.stfps(<2 x double> %a, float* %b)
  ret void
; CHECK: stfpsx
}

define void @test3(<2 x double> %a, double* %b) nounwind readnone {
entry:
  call void @llvm.ppc.fp2.stfxd(<2 x double> %a, double* %b)
  ret void
; CHECK: stfxdx
}

define void @test4(<2 x double> %a, float* %b) nounwind readnone {
entry:
  call void @llvm.ppc.fp2.stfxs(<2 x double> %a, float* %b)
  ret void
; CHECK: stfxsx
}

define void @test5(<2 x double> %a, i32* %b) nounwind readnone {
entry:
  call void @llvm.ppc.fp2.stfpiw(<2 x double> %a, i32* %b)
  ret void
; CHECK: stfpiwx
}

