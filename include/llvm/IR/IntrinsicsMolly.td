
// TODO: Using 32-bit coordinates for now to avoid fuss with overloading

def int_molly_1d_ptr : Intrinsic<[llvm_ptr_ty], [llvm_ptr_ty/*ptr to field*/, llvm_i32_ty/*logical length of dim 0*/, llvm_i32_ty/*coord dim0*/], [IntrNoMem/*Access itself done by explicit LoadInst/StoreInst*/]>;

def int_molly_1d_islocal : Intrinsic<[llvm_i1_ty], [llvm_ptr_ty/*ptr to field*/, llvm_i32_ty/*logical length of dim 0*/, llvm_i32_ty/*coord dim0*/], [IntrNoMem]>;

def int_molly_1d_rankof : Intrinsic<[llvm_i32_ty], [llvm_ptr_ty/*ptr to field*/, llvm_i32_ty/*logical length of dim 0*/, llvm_i32_ty/*coord dim0*/], [IntrNoMem]>;
