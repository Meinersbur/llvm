; RUN: llc -march=c < %s | FileCheck %s

@array = common global [10 x [20 x i32]] zeroinitializer, align 16
; CHECK: typedef int array[20][10] array_t;
