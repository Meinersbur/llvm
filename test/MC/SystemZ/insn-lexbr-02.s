# RUN: not llvm-mc -triple s390x-linux-gnu < %s 2> %t
# RUN: FileCheck < %t %s

#CHECK: error: invalid register
#CHECK: lexbr	%f0, %f2
#CHECK: error: invalid register
#CHECK: lexbr	%f0, %f14
#CHECK: error: invalid register
#CHECK: lexbr	%f2, %f0
#CHECK: error: invalid register
#CHECK: lexbr	%f14, %f0

	lexbr	%f0, %f2
	lexbr	%f0, %f14
	lexbr	%f2, %f0
	lexbr	%f14, %f0
