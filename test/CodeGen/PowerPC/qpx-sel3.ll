; RUN: llc < %s -march=ppc64 -mcpu=a2q | FileCheck %s

define <4 x double> @test1(<4 x double> %a, <4 x double> %b, <4 x double> %e, <4 x double> %f) nounwind readnone {
entry:
  %c = fcmp oeq <4 x double> %e, %f
  %r = select <4 x i1> %c, <4 x double> %a, <4 x double> %b
  ret <4 x double> %r
; CHECK: @test1
}

