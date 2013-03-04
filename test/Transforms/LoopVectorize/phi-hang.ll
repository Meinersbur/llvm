; RUN: opt -S -loop-vectorize < %s

; PR15384
define void @test1(i32 %arg) {
bb:
  br label %bb1

bb1:                                              ; preds = %bb5, %bb
  %tmp = phi i32 [ 1, %bb ], [ %tmp7, %bb5 ]
  %tmp2 = phi i32 [ %arg, %bb ], [ %tmp9, %bb5 ]
  br i1 true, label %bb5, label %bb3

bb3:                                              ; preds = %bb1
  br label %bb4

bb4:                                              ; preds = %bb3
  br label %bb5

bb5:                                              ; preds = %bb4, %bb1
  %tmp6 = phi i32 [ 0, %bb4 ], [ %tmp, %bb1 ]
  %tmp7 = phi i32 [ 0, %bb4 ], [ %tmp6, %bb1 ]
  %tmp8 = phi i32 [ 0, %bb4 ], [ %tmp, %bb1 ]
  %tmp9 = add nsw i32 %tmp2, 1
  %tmp10 = icmp eq i32 %tmp9, 0
  br i1 %tmp10, label %bb11, label %bb1

bb11:                                             ; preds = %bb5
  ret void
}
