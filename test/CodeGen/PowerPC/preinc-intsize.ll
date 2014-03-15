; RUN: llc -disable-lsr < %s | FileCheck %s
target datalayout = "E-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f128:128:128-v128:128:128-n32:64"
target triple = "powerpc64-bgq-linux"

@e = external global [16000 x double], align 32

define void @s273() nounwind {
entry:
  br label %for.cond2.preheader

for.cond2.preheader:                              ; preds = %for.end, %entry
  br label %for.body4

for.body4:                                        ; preds = %if.end.3, %for.cond2.preheader
  %indvars.iv = phi i64 [ 0, %for.cond2.preheader ], [ %indvars.iv.next.3, %if.end.3 ]
  %arrayidx6 = getelementptr inbounds [16000 x double]* @e, i64 0, i64 %indvars.iv
  %0 = load double* %arrayidx6, align 32, !tbaa !0
  br i1 undef, label %if.then.1, label %if.end.1

; CHECK: @s273

for.end:                                          ; preds = %if.end.3
  br i1 undef, label %for.end31, label %for.cond2.preheader

for.end31:                                        ; preds = %for.end
  ret void

if.then.1:                                        ; preds = %for.body4
  br label %if.end.1

if.end.1:                                         ; preds = %if.then.1, %for.body4
  br i1 undef, label %if.then.3, label %if.end.3

if.then.3:                                        ; preds = %if.end.1
  br label %if.end.3

if.end.3:                                         ; preds = %if.then.3, %if.end.1
  %indvars.iv.next.3 = add i64 %indvars.iv, 4
  br i1 undef, label %for.end, label %for.body4
}

!0 = metadata !{metadata !"double", metadata !1}
!1 = metadata !{metadata !"omnipotent char", metadata !2}
!2 = metadata !{metadata !"Simple C/C++ TBAA"}
