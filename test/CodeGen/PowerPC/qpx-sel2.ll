; RUN: llc < %s -march=ppc64 -mcpu=a2q | FileCheck %s

define <4 x double> @test1(<4 x double>* %aa, <4 x double>* %bb, i32 %c1i, i32 %c2i, i32 %c3i, i32 %c4i) nounwind readnone {
entry:
  %c1 = trunc i32 %c1i to i1
  %c2 = trunc i32 %c2i to i1
  %c3 = trunc i32 %c3i to i1
  %c4 = trunc i32 %c4i to i1
  %a = load <4 x double>* %aa, align 16
  %b = load <4 x double>* %bb, align 16
  %v = insertelement <4 x i1> undef, i1 %c1, i32 0
  %v2 = insertelement <4 x i1> %v, i1 %c2, i32 1
  %v3 = insertelement <4 x i1> %v2, i1 %c3, i32 2
  %v4 = insertelement <4 x i1> %v3, i1 %c4, i32 3
  %r = select <4 x i1> %v4, <4 x double> %a, <4 x double> %b
  ret <4 x double> %r
; CHECK: @test1
}

