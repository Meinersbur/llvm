; RUN: llc -mcpu=a2q < %s
target datalayout = "E-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f128:128:128-v128:128:128-n32:64"
target triple = "powerpc64-bgq-linux"

@b = external global [16000 x double], align 32

define void @s291() nounwind {
entry:
  br label %for.body4

for.body4:                                        ; preds = %for.body4, %entry
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next.7.1, %for.body4 ]
  %indvars.iv.next.741 = or i64 %indvars.iv, 8
  %arrayidx.1 = getelementptr inbounds [16000 x double]* @b, i64 0, i64 %indvars.iv.next.741
  %0 = bitcast double* %arrayidx.1 to <4 x double>*
  %sext23.1 = shl i64 %indvars.iv.next.741, 32
  %idxprom5.1.1 = ashr exact i64 %sext23.1, 32
  %arrayidx6.1.1 = getelementptr inbounds [16000 x double]* @b, i64 0, i64 %idxprom5.1.1
  %1 = load double* %arrayidx6.1.1, align 32, !tbaa !0
  %2 = load <4 x double>* %0, align 32, !tbaa !0
  %indvars.iv.next.7.1 = add i64 %indvars.iv, 16
  %lftr.wideiv.7.1 = trunc i64 %indvars.iv.next.7.1 to i32
  %exitcond.7.1 = icmp eq i32 %lftr.wideiv.7.1, 16000
  br i1 %exitcond.7.1, label %for.end, label %for.body4

for.end:                                          ; preds = %for.body4
  unreachable
}

!0 = metadata !{metadata !"double", metadata !1}
!1 = metadata !{metadata !"omnipotent char", metadata !2}
!2 = metadata !{metadata !"Simple C/C++ TBAA"}
