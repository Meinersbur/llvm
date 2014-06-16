target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128"
; RUN: opt < %s -S -loop-data-prefetch -prefetch-loop-data | FileCheck %s

define i32 @test(i32* nocapture %a, i32 %n) nounwind uwtable readonly {
entry:
  %cmp1 = icmp eq i32 %n, 0
  br i1 %cmp1, label %for.end, label %for.body

; CHECK: @test
; CHECK: %0 = add i64 %indvars.iv, 42
; CHECK: %scevgep = getelementptr i32* %a, i64 %0
; CHECK: %scevgep1 = bitcast i32* %scevgep to i8*
; CHECK: %arrayidx = getelementptr inbounds i32* %a, i64 %indvars.iv
; CHECK: call void @llvm.prefetch(i8* %scevgep1, i32 0, i32 3, i32 1)
; CHECK: %1 = load i32* %arrayidx, align 4

for.body:                                         ; preds = %for.body, %entry
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body ], [ 0, %entry ]
  %sum.02 = phi i32 [ %add, %for.body ], [ 0, %entry ]
  %arrayidx = getelementptr inbounds i32* %a, i64 %indvars.iv
  %0 = load i32* %arrayidx, align 4
  %add = add nsw i32 %0, %sum.02
  %indvars.iv.next = add i64 %indvars.iv, 1
  %lftr.wideiv = trunc i64 %indvars.iv.next to i32
  %exitcond = icmp eq i32 %lftr.wideiv, %n
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body, %entry
  %sum.0.lcssa = phi i32 [ 0, %entry ], [ %add, %for.body ]
  ret i32 %sum.0.lcssa
}

; Make sure that we don't prefetch the second load because it is within one
; cache line size of the first load.
define i32 @test1(i32* nocapture %a) nounwind uwtable readonly {
entry:
  br label %for.body

; CHECK: @test1
; CHECK: %0 = add i64 %indvars.iv, 37
; CHECK-NOT: add i64 %indvars.iv, 38
; CHECK: ret i32

for.body:                                         ; preds = %for.body, %entry
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.body ]
  %sum.01 = phi i32 [ 0, %entry ], [ %add, %for.body ]
  %arrayidx = getelementptr inbounds i32* %a, i64 %indvars.iv
  %0 = load i32* %arrayidx, align 4
  %arrayidx1 = getelementptr inbounds i32* %arrayidx, i64 1
  %1 = load i32* %arrayidx1, align 4
  %add = add nsw i32 %0, %sum.01
  %indvars.iv.next = add i64 %indvars.iv, 1
  %lftr.wideiv = trunc i64 %indvars.iv.next to i32
  %exitcond = icmp eq i32 %lftr.wideiv, 5
  br i1 %exitcond, label %for.end, label %for.body

for.end:                                          ; preds = %for.body
  ret i32 %add
}

