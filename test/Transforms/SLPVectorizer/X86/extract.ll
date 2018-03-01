; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -basicaa -slp-vectorizer -dce -S -mtriple=x86_64-apple-macosx10.8.0 -mcpu=corei7-avx | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.8.0"
define void @fextr(double* %ptr) {
; CHECK-LABEL: @fextr(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[LD:%.*]] = load <2 x double>, <2 x double>* undef
; CHECK-NEXT:    [[P0:%.*]] = getelementptr inbounds double, double* [[PTR:%.*]], i64 0
; CHECK-NEXT:    [[TMP0:%.*]] = fadd <2 x double> <double 0.000000e+00, double 1.100000e+00>, [[LD]]
; CHECK-NEXT:    [[TMP1:%.*]] = bitcast double* [[P0]] to <2 x double>*
; CHECK-NEXT:    store <2 x double> [[TMP0]], <2 x double>* [[TMP1]], align 4
; CHECK-NEXT:    ret void
;
entry:
  %LD = load <2 x double>, <2 x double>* undef
  %V0 = extractelement <2 x double> %LD, i32 0
  %V1 = extractelement <2 x double> %LD, i32 1
  %P0 = getelementptr inbounds double, double* %ptr, i64 0
  %P1 = getelementptr inbounds double, double* %ptr, i64 1
  %A0 = fadd double %V0, 0.0
  %A1 = fadd double %V1, 1.1
  store double %A0, double* %P0, align 4
  store double %A1, double* %P1, align 4
  ret void
}

define void @fextr1(double* %ptr) {
; CHECK-LABEL: @fextr1(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[LD:%.*]] = load <2 x double>, <2 x double>* undef
; CHECK-NEXT:    [[V0:%.*]] = extractelement <2 x double> [[LD]], i32 0
; CHECK-NEXT:    [[V1:%.*]] = extractelement <2 x double> [[LD]], i32 1
; CHECK-NEXT:    [[P1:%.*]] = getelementptr inbounds double, double* [[PTR:%.*]], i64 0
; CHECK-NEXT:    [[TMP0:%.*]] = insertelement <2 x double> undef, double [[V1]], i32 0
; CHECK-NEXT:    [[TMP1:%.*]] = insertelement <2 x double> [[TMP0]], double [[V0]], i32 1
; CHECK-NEXT:    [[TMP2:%.*]] = fadd <2 x double> <double 3.400000e+00, double 1.200000e+00>, [[TMP1]]
; CHECK-NEXT:    [[TMP3:%.*]] = bitcast double* [[P1]] to <2 x double>*
; CHECK-NEXT:    store <2 x double> [[TMP2]], <2 x double>* [[TMP3]], align 4
; CHECK-NEXT:    ret void
;
entry:
  %LD = load <2 x double>, <2 x double>* undef
  %V0 = extractelement <2 x double> %LD, i32 0
  %V1 = extractelement <2 x double> %LD, i32 1
  %P0 = getelementptr inbounds double, double* %ptr, i64 1  ; <--- incorrect order
  %P1 = getelementptr inbounds double, double* %ptr, i64 0
  %A0 = fadd double %V0, 1.2
  %A1 = fadd double %V1, 3.4
  store double %A0, double* %P0, align 4
  store double %A1, double* %P1, align 4
  ret void
}

define void @fextr2(double* %ptr) {
; CHECK-LABEL: @fextr2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[LD:%.*]] = load <4 x double>, <4 x double>* undef
; CHECK-NEXT:    [[V0:%.*]] = extractelement <4 x double> [[LD]], i32 0
; CHECK-NEXT:    [[V1:%.*]] = extractelement <4 x double> [[LD]], i32 1
; CHECK-NEXT:    [[P0:%.*]] = getelementptr inbounds double, double* [[PTR:%.*]], i64 0
; CHECK-NEXT:    [[TMP0:%.*]] = insertelement <2 x double> undef, double [[V0]], i32 0
; CHECK-NEXT:    [[TMP1:%.*]] = insertelement <2 x double> [[TMP0]], double [[V1]], i32 1
; CHECK-NEXT:    [[TMP2:%.*]] = fadd <2 x double> <double 5.500000e+00, double 6.600000e+00>, [[TMP1]]
; CHECK-NEXT:    [[TMP3:%.*]] = bitcast double* [[P0]] to <2 x double>*
; CHECK-NEXT:    store <2 x double> [[TMP2]], <2 x double>* [[TMP3]], align 4
; CHECK-NEXT:    ret void
;
entry:
  %LD = load <4 x double>, <4 x double>* undef
  %V0 = extractelement <4 x double> %LD, i32 0  ; <--- invalid size.
  %V1 = extractelement <4 x double> %LD, i32 1
  %P0 = getelementptr inbounds double, double* %ptr, i64 0
  %P1 = getelementptr inbounds double, double* %ptr, i64 1
  %A0 = fadd double %V0, 5.5
  %A1 = fadd double %V1, 6.6
  store double %A0, double* %P0, align 4
  store double %A1, double* %P1, align 4
  ret void
}

