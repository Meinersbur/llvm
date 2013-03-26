

def int_molly_ptr : Intrinsic<[llvm_anyptr_ty], [llvm_anyptr_ty/*ptr to field*/, llvm_vararg_ty/*coordinates*/], [IntrNoMem/*Access itself done by explicit LoadInst/StoreInst*/]>;

// We do this in buffers because of trouble if the value is a StructType
def int_molly_get : Intrinsic<[], [llvm_anyptr_ty/*ptr to field*/, llvm_anyptr_ty/*target buffer*/, llvm_vararg_ty/*coordinates*/], [IntrReadWriteArgMem]>;
def int_molly_set : Intrinsic<[], [llvm_anyptr_ty/*ptr to field*/, llvm_anyptr_ty/*source buffer*/, llvm_vararg_ty/*coordinates*/], []>;

def int_molly_islocal : Intrinsic<[llvm_i1_ty], [llvm_anyptr_ty/*ptr to field*/, llvm_vararg_ty/*coordinates*/], [IntrNoMem]>;
def int_molly_rankof : Intrinsic<[llvm_i32_ty], [llvm_anyptr_ty/*ptr to field*/, llvm_vararg_ty/*coordinates*/], [IntrNoMem]>;




def int_molly_1d_ptr : Intrinsic<[llvm_ptr_ty], [llvm_ptr_ty/*ptr to field*/, llvm_i32_ty/*logical length of dim 0*/, llvm_i32_ty/*coord dim0*/], [IntrNoMem/*Access itself done by explicit LoadInst/StoreInst*/]>;

def int_molly_1d_islocal : Intrinsic<[llvm_i1_ty], [llvm_ptr_ty/*ptr to field*/, llvm_i32_ty/*logical length of dim 0*/, llvm_i32_ty/*coord dim0*/], [IntrNoMem]>;

def int_molly_1d_rankof : Intrinsic<[llvm_i32_ty], [llvm_ptr_ty/*ptr to field*/, llvm_i32_ty/*logical length of dim 0*/, llvm_i32_ty/*coord dim0*/], [IntrNoMem]>;
