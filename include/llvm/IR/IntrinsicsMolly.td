

def int_molly_ptr : Intrinsic<[llvm_anyptr_ty], [llvm_anyptr_ty/*ptr to field*/, llvm_vararg_ty/*coordinates*/], [IntrNoMem/*Access itself done by explicit LoadInst/StoreInst*/]>;

// We do this in buffers because of trouble if the value is a StructType
def int_molly_get : Intrinsic<[], [llvm_anyptr_ty/*ptr to field*/, llvm_anyptr_ty/*target buffer*/, llvm_vararg_ty/*coordinates*/], [IntrReadWriteArgMem]>;
def int_molly_set : Intrinsic<[], [llvm_anyptr_ty/*ptr to field*/, llvm_anyptr_ty/*source buffer*/, llvm_vararg_ty/*coordinates*/], []>;

def int_molly_islocal : Intrinsic<[llvm_i1_ty], [llvm_anyptr_ty/*ptr to field*/, llvm_vararg_ty/*coordinates*/], [IntrNoMem]>;
def int_molly_rankof : Intrinsic<[llvm_i64_ty], [llvm_anyptr_ty/*ptr to field*/, llvm_vararg_ty/*coordinates*/], [IntrNoMem]>;

def int_molly_locallength : Intrinsic<[llvm_i64_ty], [llvm_anyptr_ty/*ptr to field*/, llvm_i64_ty/*dimension*/], [IntrNoMem]>;
def int_molly_localoffset : Intrinsic<[llvm_i64_ty], [llvm_anyptr_ty/*ptr to field*/, llvm_i64_ty/*dimension*/], [IntrNoMem]>;

def int_molly_1d_ptr : Intrinsic<[llvm_ptr_ty], [llvm_ptr_ty/*ptr to field*/, llvm_i64_ty/*logical length of dim 0*/, llvm_i64_ty/*coord dim0*/], [IntrNoMem/*Access itself done by explicit LoadInst/StoreInst*/]>;
def int_molly_1d_islocal : Intrinsic<[llvm_i1_ty], [llvm_ptr_ty/*ptr to field*/, llvm_i64_ty/*logical length of dim 0*/, llvm_i64_ty/*coord dim0*/], [IntrNoMem]>;
def int_molly_1d_rankof : Intrinsic<[llvm_i64_ty], [llvm_ptr_ty/*ptr to field*/, llvm_i64_ty/*logical length of dim 0*/, llvm_i64_ty/*coord dim0*/], [IntrNoMem]>;

def int_molly_get_local : Intrinsic<[], [llvm_anyptr_ty/*ptr to field*/, llvm_anyptr_ty/*target buffer*/, llvm_vararg_ty/*coordinates*/], [IntrReadWriteArgMem]>;
def int_molly_set_local : Intrinsic<[], [llvm_anyptr_ty/*ptr to field*/, llvm_anyptr_ty/*source buffer*/, llvm_vararg_ty/*coordinates*/], []>;
def int_molly_ptr_local : Intrinsic<[llvm_anyptr_ty], [llvm_anyptr_ty/*ptr to field*/, llvm_vararg_ty/*coordinates*/], [IntrNoMem/*access itself done by following load/store*/]>;

def int_molly_combuf_send : Intrinsic<[], [llvm_anyptr_ty/*ptr to combuf*/]>;
//def int_molly_combuf_send_wait : Intrinsic<[], [llvm_ptr_ty/*ptr to combuf*/]>;
def int_molly_combuf_recv: Intrinsic<[], [llvm_anyptr_ty/*ptr to combuf*/]>;
//def int_molly_combuf_recv_wait: Intrinsic<[], [llvm_ptr_ty/*ptr to combuf*/]>;

// Get a pointer to the first element into a buffer that sends to dst
def int_molly_combuf_sendbuf_ptr : Intrinsic<[llvm_anyptr_ty/*ptr to buf elts*/], [llvm_anyptr_ty/*ptr to combuf*/, llvm_i64_ty/*rank of dst*/]>;
// Get a pointer to the first element into the buffer that receives from src
def int_molly_combuf_recvbuf_ptr : Intrinsic<[llvm_anyptr_ty/*ptr to buf elts*/], [llvm_anyptr_ty/*ptr to combuf*/, llvm_i64_ty/*rank of src*/]>;

def int_molly_cluster_dimensions : Intrinsic<[llvm_i64_ty/*number of dimensions*/]>;
def int_molly_cluster_current_coordinate : Intrinsic<[llvm_i64_ty/*coordinate*/], [llvm_i64_ty/*dimension*/]>;

//def int_molly : Intrinsic<[], [], []>;
