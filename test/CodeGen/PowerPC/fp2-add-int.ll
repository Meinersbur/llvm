; RUN: llc < %s -march=ppc32 -mcpu=440fp2 | FileCheck %s

declare <2 x double> @llvm.ppc.fp2.fpadd(<2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fpsub(<2 x double>, <2 x double>)

define <2 x double> @test1(<2 x double> %a, <2 x double> %b) nounwind readnone {
entry:
  %c = call <2 x double> @llvm.ppc.fp2.fpadd(<2 x double> %a, <2 x double> %b)
  ret <2 x double> %c
; CHECK: fpadd
}

define <2 x double> @test2(<2 x double> %a, <2 x double> %b) nounwind readnone {
entry:
  %c = call <2 x double> @llvm.ppc.fp2.fpsub(<2 x double> %a, <2 x double> %b)
  ret <2 x double> %c
; CHECK: fpsub
}

