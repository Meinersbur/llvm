// RUN: clang -c -S %s -emit-llvm -o %t ; cat %t | llc -march=c | FileCheck %s
// CHECK: int glob
// CHECK: int foo(int
// CHECK: int bar(int
// CHECK: int main(void) {

int glob;

int foo(int arg) {
  int a = arg * 2;
  return a + glob;
}

int bar(int arg) {
  int a = foo(arg) * foo(arg * 2);
  return glob - foo(a);
}

int main() {
  glob = 23;
  return bar(10);
}
