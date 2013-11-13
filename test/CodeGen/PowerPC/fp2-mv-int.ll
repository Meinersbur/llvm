; RUN: llc < %s -march=ppc32 -mcpu=440fp2 | FileCheck %s

declare <2 x double> @llvm.ppc.fp2.fpneg(<2 x double>)
declare <2 x double> @llvm.ppc.fp2.fpabs(<2 x double>)
declare <2 x double> @llvm.ppc.fp2.fpnabs(<2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxmr(<2 x double>)

define <2 x double> @test1(<2 x double> %a) nounwind readnone {
entry:
  %b = call <2 x double> @llvm.ppc.fp2.fpneg(<2 x double> %a)
  ret <2 x double> %b
; CHECK: fpneg
}

define <2 x double> @test2(<2 x double> %a) nounwind readnone {
entry:
  %b = call <2 x double> @llvm.ppc.fp2.fpabs(<2 x double> %a)
  ret <2 x double> %b
; CHECK: fpabs
}

define <2 x double> @test3(<2 x double> %a) nounwind readnone {
entry:
  %b = call <2 x double> @llvm.ppc.fp2.fpnabs(<2 x double> %a)
  ret <2 x double> %b
; CHECK: fpnabs
}

define <2 x double> @test4(<2 x double> %a) nounwind readnone {
entry:
  %b = call <2 x double> @llvm.ppc.fp2.fxmr(<2 x double> %a)
  ret <2 x double> %b
; CHECK: fxmr
}

