; RUN: llc -march=c < %s | FileCheck %s

@array = common global [5 x [10 x [20 x i32]]] zeroinitializer, align 16
; CHECK: typedef struct { struct { struct { unsigned int array[20]; } array[10] ; } array[5] ; } array_t
; CHECK: array_t array;