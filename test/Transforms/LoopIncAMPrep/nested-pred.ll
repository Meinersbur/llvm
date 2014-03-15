; RUN: llc -mcpu=a2 < %s | FileCheck %s
target datalayout = "E-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f128:128:128-v128:128:128-n32:64"
target triple = "powerpc64-bgq-linux"

@e = external global [16000 x double], align 32

define void @s274() nounwind {
entry:
  br label %for.body4

for.body4:                                        ; preds = %for.inc.1, %entry
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next.3, %for.inc.1 ]
  %arrayidx6 = getelementptr inbounds [16000 x double]* @e, i64 0, i64 %indvars.iv
  %0 = load double* %arrayidx6, align 32, !tbaa !0
  br i1 undef, label %if.then.1, label %if.else.1

for.end:                                          ; preds = %for.inc.1
  unreachable

if.else.1:                                        ; preds = %for.body4
  br label %for.inc.1

if.then.1:                                        ; preds = %for.body4
  br label %for.inc.1

for.inc.1:                                        ; preds = %if.then.1, %if.else.1
  %indvars.iv.next.3 = add i64 %indvars.iv, 4
  br i1 undef, label %for.end, label %for.body4
}

; CHECK: dcbt

!0 = metadata !{metadata !"double", metadata !1}
!1 = metadata !{metadata !"omnipotent char", metadata !2}
!2 = metadata !{metadata !"Simple C/C++ TBAA"}
