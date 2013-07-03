; RUN: llc < %s -march=ppc32 -mcpu=440fp2 | FileCheck %s

declare <2 x double> @llvm.ppc.fp2.lfpd(double*)
declare <2 x double> @llvm.ppc.fp2.lfps(float*)
declare <2 x double> @llvm.ppc.fp2.lfxd(double*)
declare <2 x double> @llvm.ppc.fp2.lfxs(float*)

define <2 x double> @test1(double* %a) nounwind readnone {
entry:
  %b = call <2 x double> @llvm.ppc.fp2.lfpd(double* %a)
  ret <2 x double> %b
; CHECK: lfpdx
}

define <2 x double> @test2(float* %a) nounwind readnone {
entry:
  %b = call <2 x double> @llvm.ppc.fp2.lfps(float* %a)
  ret <2 x double> %b
; CHECK: lfpsx
}

define <2 x double> @test3(double* %a) nounwind readnone {
entry:
  %b = call <2 x double> @llvm.ppc.fp2.lfxd(double* %a)
  ret <2 x double> %b
; CHECK: lfxdx
}

define <2 x double> @test4(float* %a) nounwind readnone {
entry:
  %b = call <2 x double> @llvm.ppc.fp2.lfxs(float* %a)
  ret <2 x double> %b
; CHECK: lfxsx
}

