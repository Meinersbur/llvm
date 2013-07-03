; RUN: llc < %s -march=ppc32 -mcpu=440fp2 | FileCheck %s

define <2 x double> @test1(<2 x double> %a, <2 x double> %b) nounwind readnone {
entry:
  %c = fadd <2 x double> %a, %b
  ret <2 x double> %c
; CHECK: fpadd
}

define <2 x double> @test2(<2 x double> %a, <2 x double> %b) nounwind readnone {
entry:
  %c = fsub <2 x double> %a, %b
  ret <2 x double> %c
; CHECK: fpsub
}

