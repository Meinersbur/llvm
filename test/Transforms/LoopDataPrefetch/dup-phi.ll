; RUN: llc -mcpu=a2q < %s
target datalayout = "E-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f128:128:128-v128:128:128-n32:64"
target triple = "powerpc64-bgq-linux"

; Function Attrs: nounwind
define void @gsl_ieee_read_mode_string() #0 {
entry:
  br i1 undef, label %do.body, label %if.end

do.body:                                          ; preds = %entry
  unreachable

if.end:                                           ; preds = %entry
  br i1 undef, label %cond.false267.i, label %if.then5

if.then5:                                         ; preds = %if.end
  br label %do.body6

do.body6:                                         ; preds = %do.body6, %do.body6, %if.then5
  %end.0 = phi i8* [ undef, %if.then5 ], [ %incdec.ptr, %do.body6 ], [ %incdec.ptr, %do.body6 ]
  %incdec.ptr = getelementptr inbounds i8* %end.0, i64 1
  %0 = load i8* %incdec.ptr, align 1, !tbaa !0
  switch i8 %0, label %cond.false267.i [
    i8 32, label %do.body6
    i8 44, label %do.body6
  ]

cond.false267.i:                                  ; preds = %do.body6, %if.end
  unreachable
}

attributes #0 = { nounwind }

!0 = metadata !{metadata !"omnipotent char", metadata !1}
!1 = metadata !{metadata !"Simple C/C++ TBAA"}
