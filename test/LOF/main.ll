; RUN: opt -lof -analyze -debug-pass=Executions -debug-only=lof < %s

; ModuleID = '<stdin>'
source_filename = "main.c"
target datalayout = "e-m:w-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.20.27404"

@A = common dso_local global [32 x i64] zeroinitializer, align 16

; Function Attrs: nounwind uwtable
define dso_local i32 @main(i32 %argc, i8** %argv) #0 {
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.inc, %entry
  %j.0 = phi i64 [ 0, %entry ], [ %add, %for.inc ]
  %cmp = icmp slt i64 %j.0, 32
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.cond
  br label %for.end

for.body:                                         ; preds = %for.cond
  %arrayidx = getelementptr inbounds [32 x i64], [32 x i64]* @A, i64 0, i64 %j.0
  store i64 %j.0, i64* %arrayidx, align 8, !tbaa !3, !llvm.access.group !7
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %add = add nsw i64 %j.0, 1
  br label %for.cond, !llvm.loop !8

for.end:                                          ; preds = %for.cond.cleanup
  ret i32 0
}

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #1

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #1

attributes #0 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { argmemonly nounwind }

!llvm.module.flags = !{!0, !1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 2}
!1 = !{i32 7, !"PIC Level", i32 2}
!2 = !{!"clang version 9.0.0 (trunk 354698) (llvm/trunk 355865)"}
!3 = !{!4, !4, i64 0}
!4 = !{!"long long", !5, i64 0}
!5 = !{!"omnipotent char", !6, i64 0}
!6 = !{!"Simple C/C++ TBAA"}
!7 = distinct !{}
!8 = distinct !{!8, !9, !10}
!9 = !{!"llvm.loop.vectorize.enable", i1 true}
!10 = !{!"llvm.loop.parallel_accesses", !7}
