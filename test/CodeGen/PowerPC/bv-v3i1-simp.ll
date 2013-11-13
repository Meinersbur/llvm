target datalayout = "E-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-f128:128:128-v128:128:128-n32:64"
target triple = "powerpc64-bgq-linux"
; RUN: llc < %s -march=ppc64 -mcpu=a2q | FileCheck %s

%class.CosmoHaloFinder.16.196.628.664.700.1240.1263 = type { i32, float, float, i32, i32, i8, i8*, i8*, i8*, float*, float*, float*, float*, float*, float*, float*, i32*, i32*, i32, i32, i32, i32, [3 x float*], float, float, i32*, i32*, i32*, %"class.std::vector.15.195.627.663.699.1239.1262", float*, float* }
%"class.std::vector.15.195.627.663.699.1239.1262" = type { %"struct.std::_Vector_base.14.194.626.662.698.1238.1261" }
%"struct.std::_Vector_base.14.194.626.662.698.1238.1261" = type { %"struct.std::_Vector_base<int, std::allocator<int> >::_Vector_impl.13.193.625.661.697.1237.1260" }
%"struct.std::_Vector_base<int, std::allocator<int> >::_Vector_impl.13.193.625.661.697.1237.1260" = type { i32*, i32*, i32* }

@_ZN15CosmoHaloFinderC1Ev = alias void (%class.CosmoHaloFinder.16.196.628.664.700.1240.1263*)* @_ZN15CosmoHaloFinderC2Ev
@_ZN15CosmoHaloFinderD1Ev = alias void (%class.CosmoHaloFinder.16.196.628.664.700.1240.1263*)* @_ZN15CosmoHaloFinderD2Ev

declare void @_ZN15CosmoHaloFinderC2Ev(%class.CosmoHaloFinder.16.196.628.664.700.1240.1263* nocapture) unnamed_addr nounwind align 2

declare void @_ZN15CosmoHaloFinderD2Ev(%class.CosmoHaloFinder.16.196.628.664.700.1240.1263* nocapture) unnamed_addr align 2

define void @_ZN15CosmoHaloFinder5MergeEiiiii() nounwind align 2 {
; CHECK: @_ZN15CosmoHaloFinder5MergeEiiiii
entry:
  br i1 undef, label %for.cond101.preheader.lr.ph, label %return

for.cond101.preheader.lr.ph:                      ; preds = %entry
  br label %for.body103

for.body103:                                      ; preds = %for.inc234, %for.cond101.preheader.lr.ph
  br i1 undef, label %for.inc234, label %if.end122

if.end122:                                        ; preds = %for.body103
  br i1 undef, label %if.end174, label %if.then158

if.then158:                                       ; preds = %if.end122
  %cmp.i376 = fcmp olt <3 x float> undef, undef
  %.sroa.speculated404 = select <3 x i1> %cmp.i376, <3 x float> undef, <3 x float> undef
  %.sroa.speculated404.v.r2519 = extractelement <3 x float> %.sroa.speculated404, i32 2
  br label %if.end174

if.end174:                                        ; preds = %if.then158, %if.end122
  %call.i378433 = phi float [ %.sroa.speculated404.v.r2519, %if.then158 ], [ undef, %if.end122 ]
  br i1 undef, label %if.then183, label %for.inc234

if.then183:                                       ; preds = %if.end174
  br i1 undef, label %if.then194, label %for.inc234

if.then194:                                       ; preds = %if.then183
  br label %for.inc234

for.inc234:                                       ; preds = %if.then194, %if.then183, %if.end174, %for.body103
  br label %for.body103

return:                                           ; preds = %entry
  ret void
}
