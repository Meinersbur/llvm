; RUN: opt -lof -analyze < %s | FileCheck %s
;
; for (int j = 0; j < n; j += 1)
;   A[j] = j;
;
define void @func(i64 %n, i64* noalias nonnull %A) {
entry:
  br label %for

for:
  %j = phi i64 [0, %entry], [%j.inc, %inc]
  %j.cmp = icmp slt i64 %j, %n
  br i1 %j.cmp, label %body, label %exit

    body:
      %arrayidx = getelementptr inbounds i64* %A, i64 %j
      store i64 %j, double* %arrayidx
      br label %inc

inc:
  %j.inc = add nuw nsw i64 %j, 1
  br label %for

exit:
  br label %return

return:
  ret void
}
