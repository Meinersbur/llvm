; RUN: llc < %s -march=ppc32 -mcpu=440fp2 | FileCheck %s

declare <2 x double> @llvm.ppc.fp2.fpmadd(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fpnmadd(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fpmsub(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fpnmsub(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxmadd(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxnmadd(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxmsub(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxnmsub(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxcpmadd(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxcsmadd(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxcpnmadd(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxcsnmadd(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxcpmsub(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxcsmsub(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxcpnmsub(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxcsnmsub(<2 x double>, <2 x double>, <2 x double>)

define <2 x double> @test1(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fpmadd(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fpmadd
}

define <2 x double> @test2(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fpnmadd(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fpnmadd
}

define <2 x double> @test3(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fpmsub(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fpmsub
}

define <2 x double> @test4(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fpnmsub(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fpnmsub
}

define <2 x double> @test5(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxmadd(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxmadd
}

define <2 x double> @test6(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxnmadd(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxnmadd
}

define <2 x double> @test7(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxmsub(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxmsub
}

define <2 x double> @test8(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxnmsub(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxnmsub
}

define <2 x double> @test9(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcpmadd(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcpmadd
}

define <2 x double> @test10(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcsmadd(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcsmadd
}

define <2 x double> @test11(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcpnmadd(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcpnmadd
}

define <2 x double> @test12(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcsnmadd(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcsnmadd
}

define <2 x double> @test13(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcpmsub(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcpmsub
}

define <2 x double> @test14(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcsmsub(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcsmsub
}

define <2 x double> @test15(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcpnmsub(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcpnmsub
}

define <2 x double> @test16(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcsnmsub(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcsnmsub
}

