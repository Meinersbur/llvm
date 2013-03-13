; RUN: llc -march=c < %s | FileCheck %s
@array = common global [10 x i32] zeroinitializer, align 16

; CHECK: typedef int array[10] array_t;
