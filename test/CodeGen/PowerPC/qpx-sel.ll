; RUN: llc < %s -march=ppc64 -mcpu=a2q | FileCheck %s

@Q = constant <4 x i1> <i1 0, i1 undef, i1 1, i1 1>, align 16
@R = global <4 x i1> <i1 0, i1 0, i1 0, i1 0>, align 16

define <4 x double> @test1(<4 x double> %a, <4 x double> %b, <4 x i1> %c) nounwind readnone {
entry:
  %r = select <4 x i1> %c, <4 x double> %a, <4 x double> %b
  ret <4 x double> %r
; CHECK: @test1
}

define <4 x double> @test2(<4 x double> %a, <4 x double> %b, i1 %c1, i1 %c2, i1 %c3, i1 %c4) nounwind readnone {
entry:
  %v = insertelement <4 x i1> undef, i1 %c1, i32 0
  %v2 = insertelement <4 x i1> %v, i1 %c2, i32 1
  %v3 = insertelement <4 x i1> %v2, i1 %c3, i32 2
  %v4 = insertelement <4 x i1> %v3, i1 %c4, i32 3
  %r = select <4 x i1> %v4, <4 x double> %a, <4 x double> %b
  ret <4 x double> %r
; CHECK: @test2
}

define <4 x i1> @test3(<4 x i1> %a) nounwind readnone {
entry:
  %v = and <4 x i1> %a, <i1 0, i1 undef, i1 1, i1 1>
  ret <4 x i1> %v
}

define <4 x i1> @test4(<4 x i1> %a) nounwind {
entry:
  %q = load <4 x i1>* @Q, align 16
  %v = and <4 x i1> %a, %q
  ret <4 x i1> %v
}

define void @test5(<4 x i1> %a) nounwind {
entry:
  store <4 x i1> %a, <4 x i1>* @R
  ret void
}

define i1 @test6(<4 x i1> %a) nounwind {
entry:
  %r = extractelement <4 x i1> %a, i32 2
  ret i1 %r
}

define i1 @test7(<4 x i1> %a) nounwind {
entry:
  %r = extractelement <4 x i1> %a, i32 2
  %s = extractelement <4 x i1> %a, i32 3
  %q = and i1 %r, %s
  ret i1 %q
}

define i1 @test8(<3 x i1> %a) nounwind {
entry:
  %r = extractelement <3 x i1> %a, i32 2
  ret i1 %r
}

define <3 x double> @test9(<3 x double> %a, <3 x double> %b, i1 %c1, i1 %c2, i1 %c3) nounwind readnone {
entry:
  %v = insertelement <3 x i1> undef, i1 %c1, i32 0
  %v2 = insertelement <3 x i1> %v, i1 %c2, i32 1
  %v3 = insertelement <3 x i1> %v2, i1 %c3, i32 2
  %r = select <3 x i1> %v3, <3 x double> %a, <3 x double> %b
  ret <3 x double> %r
; CHECK: @test2
}

