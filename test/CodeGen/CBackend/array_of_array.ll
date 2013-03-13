; RUN: llc -march=c < %s | FileCheck %s

@array = common global [10 x [20 x i32]] zeroinitializer, align 16
; CHECK: int array[10][20];
