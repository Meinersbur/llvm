; RUN: llc -march=c < %s | FileCheck %s

@array = common global [10 x [20 x i32]] zeroinitializer, align 16
; CHECK: typedef struct { struct { unsigned int array[20]; } array[10] ; } array_t
; CHECK: array_t array;
