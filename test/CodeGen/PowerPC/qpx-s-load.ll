; RUN: llc < %s -march=ppc64 -mcpu=a2q | FileCheck %s

define <4 x float> @foo(<4 x float>* %p) {
entry:
  %v = load <4 x float>* %p, align 4
  ret <4 x float> %v
}

; CHECK: @foo
; CHECK: lfs
; CHECK: lfs
; CHECK: lfs
; CHECK: lfs
; CHECK: blr

define <4 x float> @bar(<4 x float>* %p) {
entry:
  %v = load <4 x float>* %p, align 16
  ret <4 x float> %v
}

; CHECK: @bar
; CHECK: qvlfsx

