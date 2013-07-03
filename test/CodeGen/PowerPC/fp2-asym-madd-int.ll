; RUN: llc < %s -march=ppc32 -mcpu=440fp2 | FileCheck %s

declare <2 x double> @llvm.ppc.fp2.fxcpnpma(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxcsnpma(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxcpnsma(<2 x double>, <2 x double>, <2 x double>)
declare <2 x double> @llvm.ppc.fp2.fxcsnsma(<2 x double>, <2 x double>, <2 x double>)

define <2 x double> @test1(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcpnpma(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcpnpma
}

define <2 x double> @test2(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcsnpma(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcsnpma
}

define <2 x double> @test3(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcpnsma(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcpnsma
}

define <2 x double> @test4(<2 x double> %a, <2 x double> %b, <2 x double> %c) nounwind readnone {
entry:
  %d = call <2 x double> @llvm.ppc.fp2.fxcsnsma(<2 x double> %a, <2 x double> %b, <2 x double> %c)
  ret <2 x double> %d
; CHECK: fxcsnsma
}

