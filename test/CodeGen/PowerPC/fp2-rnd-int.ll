; RUN: llc < %s -march=ppc32 -mcpu=440fp2 | FileCheck %s

declare <2 x double> @llvm.ppc.fp2.fpctiw(<2 x double>)
declare <2 x double> @llvm.ppc.fp2.fpctiwz(<2 x double>)
declare <2 x double> @llvm.ppc.fp2.fprsp(<2 x double>)

define <2 x double> @test1(<2 x double> %a) nounwind readnone {
entry:
  %b = call <2 x double> @llvm.ppc.fp2.fpctiw(<2 x double> %a)
  ret <2 x double> %b
; CHECK: fpctiw
}

define <2 x double> @test2(<2 x double> %a) nounwind readnone {
entry:
  %b = call <2 x double> @llvm.ppc.fp2.fpctiwz(<2 x double> %a)
  ret <2 x double> %b
; CHECK: fpctiwz
}

define <2 x double> @test3(<2 x double> %a) nounwind readnone {
entry:
  %b = call <2 x double> @llvm.ppc.fp2.fprsp(<2 x double> %a)
  ret <2 x double> %b
; CHECK: fprsp
}

