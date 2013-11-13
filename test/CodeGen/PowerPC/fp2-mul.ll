; RUN: llc < %s -march=ppc32 -mcpu=440fp2 | FileCheck %s

define <2 x double> @test1(<2 x double> %a, <2 x double> %b) nounwind readnone {
entry:
  %c = fmul <2 x double> %a, %b
  ret <2 x double> %c
; CHECK: fpmul
}

define <2 x double> @test2(<2 x double> %a, <2 x double> %b) nounwind readnone {
entry:
  %c = shufflevector < 2 x double> %b, <2 x double> undef, <2 x i32> <i32 1, i32 0>
  %d = fmul <2 x double> %a, %c
  ret <2 x double> %d
; CHECK: fxmul
}

define <2 x double> @test3(<2 x double> %a, <2 x double> %b) nounwind readnone {
entry:
  %c = shufflevector < 2 x double> %a, <2 x double> undef, <2 x i32> <i32 0, i32 0>
  %d = fmul <2 x double> %b, %c
  ret <2 x double> %d
; CHECK: fxpmul
}

define <2 x double> @test4(<2 x double> %a, <2 x double> %b) nounwind readnone {
entry:
  %c = shufflevector < 2 x double> %a, <2 x double> undef, <2 x i32> <i32 1, i32 1>
  %d = fmul <2 x double> %b, %c
  ret <2 x double> %d
; CHECK: fxsmul
}

