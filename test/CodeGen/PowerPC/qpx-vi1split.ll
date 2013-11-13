; RUN: llc < %s -mcpu=a2q | FileCheck %s

target datalayout = "E-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f128:128:128-v128:128:128-n32:64"
target triple = "powerpc64-bgq-linux"

define void @_Z9example25v() #0 {
; CHECK: @_Z9example25v

vector.ph:
  br label %vector.body

vector.body:                                      ; preds = %vector.body, %vector.ph
  %0 = fcmp olt <8 x float> zeroinitializer, undef
  %wide.load24.1 = load <8 x float>* null, align 4
  %1 = fcmp olt <8 x float> undef, %wide.load24.1
  %2 = and <8 x i1> %0, %1
  %3 = zext <8 x i1> %2 to <8 x i32>
  store <8 x i32> %3, <8 x i32>* undef, align 4
  br i1 undef, label %for.end, label %vector.body

for.end:                                          ; preds = %vector.body
  ret void
}

attributes #0 = { noinline nounwind "target-cpu"="a2q" "target-features"="-altivec,+qpx" }
