// RUN: clang -c -S %s -emit-llvm -o %t ; cat %t | llc -march=c > %t.c; clang %t.c -o %t.c.runme; %t.c.runme | FileCheck %s
// CHECK: hello CBackend

#include <stdio.h>

int main() {
  printf("hello CBackend!\n");
  return 0;
}
