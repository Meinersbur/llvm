; RUN: llc < %s -march=ppc32 -mcpu=440fp2 | FileCheck %s

declare <2 x double> @llvm.ppc.fp2.fpre(<2 x double>)
declare <2 x double> @llvm.ppc.fp2.fprsqrte(<2 x double>)

define <2 x double> @test1(<2 x double> %a) nounwind readnone {
entry:
  %c = call <2 x double> @llvm.ppc.fp2.fpre(<2 x double> %a)
  ret <2 x double> %c
; CHECK: fpre
}

define <2 x double> @test2(<2 x double> %a, <2 x double> %b) nounwind readnone {
entry:
  %c = call <2 x double> @llvm.ppc.fp2.fprsqrte(<2 x double> %a)
  ret <2 x double> %c
; CHECK: fprsqrte
}

