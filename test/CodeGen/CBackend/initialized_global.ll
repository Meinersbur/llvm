; RUN: llc -march=c < %s | FileCheck %s

@a = global i32 1, align 4

; CHECK: int a = 1{{u?}};
