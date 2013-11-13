; RUN: llc < %s -march=ppc64 -mcpu=a2q | FileCheck %s

define <4 x double> @foo(<4 x double>* %p) {
entry:
  %v = load <4 x double>* %p, align 8
  ret <4 x double> %v
}

; CHECK: @foo
; CHECK: lfd
; CHECK: lfd
; CHECK: lfd
; CHECK: lfd
; CHECK: blr

define <4 x double> @bar(<4 x double>* %p) {
entry:
  %v = load <4 x double>* %p, align 32
  ret <4 x double> %v
}

; CHECK: @bar
; CHECK: qvlfdx

