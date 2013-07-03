target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128"
; RUN: opt < %s -loop-data-prefetch -prefetch-loop-data -S | FileCheck %s

define i32 @nested(i32* nocapture %a, i32 %n, i32 %m) nounwind uwtable readonly {
entry:
  %cmp11 = icmp sgt i32 %n, 0
  br i1 %cmp11, label %for.cond1.preheader.lr.ph, label %for.end7

for.cond1.preheader.lr.ph:                        ; preds = %entry
  %cmp28 = icmp sgt i32 %m, 0
  br label %for.cond1.preheader

for.cond1.preheader:                              ; preds = %for.inc5, %for.cond1.preheader.lr.ph
  %indvars.iv16 = phi i64 [ 0, %for.cond1.preheader.lr.ph ], [ %indvars.iv.next17, %for.inc5 ]
  %sum.012 = phi i32 [ 0, %for.cond1.preheader.lr.ph ], [ %sum.1.lcssa, %for.inc5 ]
  br i1 %cmp28, label %for.body3, label %for.inc5
; CHECK: @nested
; CHECK: %0 = add i64 %indvars.iv16, 37

for.body3:                                        ; preds = %for.cond1.preheader, %for.body3
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body3 ], [ 0, %for.cond1.preheader ]
  %sum.19 = phi i32 [ %add4, %for.body3 ], [ %sum.012, %for.cond1.preheader ]
  %0 = add nsw i64 %indvars.iv, %indvars.iv16
  %arrayidx = getelementptr inbounds i32* %a, i64 %0
  %1 = load i32* %arrayidx, align 4
  %add4 = add nsw i32 %1, %sum.19
  %indvars.iv.next = add i64 %indvars.iv, 1
  %lftr.wideiv = trunc i64 %indvars.iv.next to i32
  %exitcond = icmp eq i32 %lftr.wideiv, %m
  br i1 %exitcond, label %for.inc5, label %for.body3

; CHECK: %1 = add i64 %0, %indvars.iv
; CHECK: %scevgep = getelementptr i32* %a, i64 %1
; CHECK: %scevgep1 = bitcast i32* %scevgep to i8*
; CHECK: %2 = add nsw i64 %indvars.iv, %indvars.iv16
; CHECK: %arrayidx = getelementptr inbounds i32* %a, i64 %2
; CHECK: call void @llvm.prefetch(i8* %scevgep1, i32 0, i32 3, i32 1)
; CHECK: %3 = load i32* %arrayidx, align 4

for.inc5:                                         ; preds = %for.body3, %for.cond1.preheader
  %sum.1.lcssa = phi i32 [ %sum.012, %for.cond1.preheader ], [ %add4, %for.body3 ]
  %indvars.iv.next17 = add i64 %indvars.iv16, 1
  %lftr.wideiv18 = trunc i64 %indvars.iv.next17 to i32
  %exitcond19 = icmp eq i32 %lftr.wideiv18, %n
  br i1 %exitcond19, label %for.end7, label %for.cond1.preheader

for.end7:                                         ; preds = %for.inc5, %entry
  %sum.0.lcssa = phi i32 [ 0, %entry ], [ %sum.1.lcssa, %for.inc5 ]
  ret i32 %sum.0.lcssa
}

