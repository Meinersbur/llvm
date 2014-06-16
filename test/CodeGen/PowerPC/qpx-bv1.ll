; RUN: llc < %s -mcpu=a2q | FileCheck %s
target datalayout = "E-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f128:128:128-v128:128:128-n32:64"
target triple = "powerpc64-bgq-linux"

define void @_Z27test_for_loop_unroll_factorILi10EdEvPKT0_iPKc(double* nocapture %first) #0 {
entry:
  br i1 undef, label %for.body.lr.ph, label %for.end12

for.body.lr.ph:                                   ; preds = %entry
  br label %for.body3

for.body3:                                        ; preds = %for.body3, %for.body.lr.ph
  %0 = add nsw i64 0, 8
  %1 = load double* null, align 8, !tbaa !0
  %arrayidx.i = getelementptr inbounds double* %first, i64 undef
  %2 = load double* %arrayidx.i, align 8, !tbaa !0
  %add.i.i.i.i.i.v.i0.2166 = insertelement <3 x double> zeroinitializer, double %1, i32 1
  %add.i.i.i.i.i.v.i0 = insertelement <3 x double> %add.i.i.i.i.i.v.i0.2166, double %2, i32 2
  %add.i.i.i.i.i = fadd <3 x double> %add.i.i.i.i.i.v.i0, <double 1.234500e+04, double 1.234500e+04, double 1.234500e+04>
  %mul.i.i.i.i.i = fmul <3 x double> %add.i.i.i.i.i, <double 9.142370e+05, double 9.142370e+05, double 9.142370e+05>
  %sub.i.i.i.i.i = fadd <3 x double> %mul.i.i.i.i.i, <double -1.300000e+01, double -1.300000e+01, double -1.300000e+01>
  %add.i6.i.i.i.i = fadd <3 x double> %sub.i.i.i.i.i, <double 1.234500e+04, double 1.234500e+04, double 1.234500e+04>
  %mul.i7.i.i.i.i = fmul <3 x double> %add.i6.i.i.i.i, <double 9.142370e+05, double 9.142370e+05, double 9.142370e+05>
  %sub.i8.i.i.i.i = fadd <3 x double> %mul.i7.i.i.i.i, <double -1.300000e+01, double -1.300000e+01, double -1.300000e+01>
  %add.i3.i.i.i.i = fadd <3 x double> %sub.i8.i.i.i.i, <double 1.234500e+04, double 1.234500e+04, double 1.234500e+04>
  %mul.i4.i.i.i.i = fmul <3 x double> %add.i3.i.i.i.i, <double 9.142370e+05, double 9.142370e+05, double 9.142370e+05>
  %sub.i5.i.i.i.i = fadd <3 x double> %mul.i4.i.i.i.i, <double -1.300000e+01, double -1.300000e+01, double -1.300000e+01>
  %sub.i5.i.i.i.i.v.r2 = extractelement <3 x double> %sub.i5.i.i.i.i, i32 1
  %add1.i.i = fadd double undef, %sub.i5.i.i.i.i.v.r2
  %add1.i = fadd double %add1.i.i, undef
  store double %add1.i, double* undef, align 8, !tbaa !0
  br label %for.body3

for.end12:                                        ; preds = %entry
  unreachable

; CHECK: @_Z27test_for_loop_unroll_factorILi10EdEvPKT0_iPKc
; CHECK: qvfperm
}

attributes #0 = { nounwind "target-cpu"="a2q" "target-features"="-altivec,+qpx" }

!0 = metadata !{metadata !"double", metadata !1}
!1 = metadata !{metadata !"omnipotent char", metadata !2}
!2 = metadata !{metadata !"Simple C/C++ TBAA"}
