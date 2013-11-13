; RUN: llc -mcpu=a2 < %s | FileCheck %s
target datalayout = "E-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f128:128:128-v128:128:128-n32:64"
target triple = "powerpc64-bgq-linux"

%"class.std::__1::basic_streambuf.15.39.1334.2342.3063.4793.5087.5234.5526.5818.6544.6981.8688.9407" = type { i32 (...)**, i32*, i32*, i32*, i32*, i32*, i32* }

; CHECK: @_ZNSt3__114__scan_keywordINS_19istreambuf_iteratorIwNS_11char_traitsIwEEEEPKNS_12basic_stringIwS3_NS_9allocatorIwEEEENS_5ctypeIwEEEET0_RT_SE_SD_SD_RKT1_Rjb
define hidden void @_ZNSt3__114__scan_keywordINS_19istreambuf_iteratorIwNS_11char_traitsIwEEEEPKNS_12basic_stringIwS3_NS_9allocatorIwEEEENS_5ctypeIwEEEET0_RT_SE_SD_SD_RKT1_Rjb(i1 zeroext %__case_sensitive) #1 {
entry:
  br i1 undef, label %if.then, label %if.end4

if.then:                                          ; preds = %entry
  unreachable

if.end4:                                          ; preds = %entry
  br i1 undef, label %for.cond10.preheader, label %for.body

for.cond10.preheader:                             ; preds = %for.body, %if.end4
  br label %for.cond10

for.body:                                         ; preds = %for.body, %if.end4
  br i1 undef, label %for.cond10.preheader, label %for.body

for.cond10:                                       ; preds = %if.end20, %for.cond10.preheader
  %__indx.0 = phi i64 [ 0, %for.cond10.preheader ], [ %inc76.pre, %if.end20 ]
  %tobool.i5.i.i = icmp eq %"class.std::__1::basic_streambuf.15.39.1334.2342.3063.4793.5087.5234.5526.5818.6544.6981.8688.9407"* undef, null
  br i1 %tobool.i5.i.i, label %invoke.cont11, label %if.then.i.i13.i.i

if.then.i.i13.i.i:                                ; preds = %for.cond10
  unreachable

invoke.cont11:                                    ; preds = %for.cond10
  %cmp13. = and i1 undef, undef
  br i1 %cmp13., label %for.body14, label %if.then.i.i.i.i198

for.body14:                                       ; preds = %invoke.cont11
  br i1 false, label %if.then.i.i, label %if.end.i.i

if.then.i.i:                                      ; preds = %for.body14
  unreachable

if.end.i.i:                                       ; preds = %for.body14
  br i1 %__case_sensitive, label %if.end20, label %if.then17

if.then17:                                        ; preds = %if.end.i.i
  unreachable

if.end20:                                         ; preds = %if.end.i.i
  %inc76.pre = add i64 %__indx.0, 1
  br i1 undef, label %for.cond10, label %for.body24

for.body24:                                       ; preds = %for.inc46, %if.end20
  br i1 undef, label %cond.true.i.i.i, label %for.inc46

cond.true.i.i.i:                                  ; preds = %for.body24
  %0 = load i32** undef, align 8
  %add.ptr.i = getelementptr inbounds i32* %0, i64 %__indx.0
  %1 = load i32* %add.ptr.i, align 4
  br i1 undef, label %for.inc46, label %if.else42

if.else42:                                        ; preds = %cond.true.i.i.i
  br label %for.inc46

for.inc46:                                        ; preds = %if.else42, %cond.true.i.i.i, %for.body24
  br label %for.body24

if.then.i.i.i.i198:                               ; preds = %invoke.cont11
  unreachable
}

