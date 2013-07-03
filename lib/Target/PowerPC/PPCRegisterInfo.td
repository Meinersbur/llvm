//===-- PPCRegisterInfo.td - The PowerPC Register File -----*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//
//===----------------------------------------------------------------------===//

let Namespace = "PPC" in {
def sub_lt : SubRegIndex<1>;
def sub_gt : SubRegIndex<1, 1>;
def sub_eq : SubRegIndex<1, 2>;
def sub_un : SubRegIndex<1, 3>;
def sub_32 : SubRegIndex<32>;
def sub_64 : SubRegIndex<64>;
def sub_fext : SubRegIndex<192, 64>;
}

class PPCReg<string n> : Register<n> {
  let Namespace = "PPC";
}

// We identify all our registers with a 5-bit ID, for consistency's sake.

// GPR - One of the 32 32-bit general-purpose registers
class GPR<bits<5> num, string n> : PPCReg<n> {
  let HWEncoding{4-0} = num;
}

// GP8 - One of the 32 64-bit general-purpose registers
class GP8<GPR SubReg, string n> : PPCReg<n> {
  let HWEncoding = SubReg.HWEncoding;
  let SubRegs = [SubReg];
  let SubRegIndices = [sub_32];
}

// SPR - One of the 32-bit special-purpose registers
class SPR<bits<10> num, string n> : PPCReg<n> {
  let HWEncoding{9-0} = num;
}

// FPR - One of the 32 64-bit floating-point registers
class FPR<bits<5> num, string n> : PPCReg<n> {
  let HWEncoding{4-0} = num;
}

// The extended part of the FP2 or QPX registers (these are call-clobbered)
class FPR_ext<string n> : PPCReg<n>;

// DFPR - One of the 32 128-bit floating-point vector registers (used for FP2)
class DFPR<FPR SubReg, FPR_ext SubReg_ext, string n> : PPCReg<n> {
  let HWEncoding = SubReg.HWEncoding;
  let SubRegs = [SubReg, SubReg_ext];
  let SubRegIndices = [sub_64, sub_fext];
}

// QFPR - One of the 32 256-bit floating-point vector registers (used for QPX)
class QFPR<FPR SubReg, FPR_ext SubReg_ext, string n> : PPCReg<n> {
  let HWEncoding = SubReg.HWEncoding;
  let SubRegs = [SubReg, SubReg_ext];
  let SubRegIndices = [sub_64, sub_fext];
}

// VR - One of the 32 128-bit vector registers
class VR<bits<5> num, string n> : PPCReg<n> {
  let HWEncoding{4-0} = num;
}

// CR - One of the 8 4-bit condition registers
class CR<bits<3> num, string n, list<Register> subregs> : PPCReg<n> {
  let HWEncoding{2-0} = num;
  let SubRegs = subregs;
}

// CRBIT - One of the 32 1-bit condition register fields
class CRBIT<bits<5> num, string n> : PPCReg<n> {
  let HWEncoding{4-0} = num;
}

// General-purpose registers
foreach Index = 0-31 in {
  def R#Index : GPR<Index, "r"#Index>, DwarfRegNum<[-2, Index]>;
}

// 64-bit General-purpose registers
foreach Index = 0-31 in {
  def X#Index : GP8<!cast<GPR>("R"#Index), "r"#Index>,
                    DwarfRegNum<[Index, -2]>;
}

// Floating-point registers
foreach Index = 0-31 in {
  def F#Index : FPR<Index, "f"#Index>,
                DwarfRegNum<[!add(Index, 32), !add(Index, 32)]>;
}

// Extended FPR parts (used for FP2 and QPX)
def F0_ext  : FPR_ext<"f0_ext">;
def F1_ext  : FPR_ext<"f1_ext">;
def F2_ext  : FPR_ext<"f2_ext">;
def F3_ext  : FPR_ext<"f3_ext">;
def F4_ext  : FPR_ext<"f4_ext">;
def F5_ext  : FPR_ext<"f5_ext">;
def F6_ext  : FPR_ext<"f6_ext">;
def F7_ext  : FPR_ext<"f7_ext">;
def F8_ext  : FPR_ext<"f8_ext">;
def F9_ext  : FPR_ext<"f9_ext">;
def F10_ext : FPR_ext<"f10_ext">;
def F11_ext : FPR_ext<"f11_ext">;
def F12_ext : FPR_ext<"f12_ext">;
def F13_ext : FPR_ext<"f13_ext">;
def F14_ext : FPR_ext<"f14_ext">;
def F15_ext : FPR_ext<"f15_ext">;
def F16_ext : FPR_ext<"f16_ext">;
def F17_ext : FPR_ext<"f17_ext">;
def F18_ext : FPR_ext<"f18_ext">;
def F19_ext : FPR_ext<"f19_ext">;
def F20_ext : FPR_ext<"f20_ext">;
def F21_ext : FPR_ext<"f21_ext">;
def F22_ext : FPR_ext<"f22_ext">;
def F23_ext : FPR_ext<"f23_ext">;
def F24_ext : FPR_ext<"f24_ext">;
def F25_ext : FPR_ext<"f25_ext">;
def F26_ext : FPR_ext<"f26_ext">;
def F27_ext : FPR_ext<"f27_ext">;
def F28_ext : FPR_ext<"f28_ext">;
def F29_ext : FPR_ext<"f29_ext">;
def F30_ext : FPR_ext<"f30_ext">;
def F31_ext : FPR_ext<"f31_ext">;

// FP2 (Double Hummer) Floating-point registers
def DF0  : DFPR< F0,  F0_ext,  "df0">, DwarfRegNum<[32, 32]>;
def DF1  : DFPR< F1,  F1_ext,  "df1">, DwarfRegNum<[33, 33]>;
def DF2  : DFPR< F2,  F2_ext,  "df2">, DwarfRegNum<[34, 34]>;
def DF3  : DFPR< F3,  F3_ext,  "df3">, DwarfRegNum<[35, 35]>;
def DF4  : DFPR< F4,  F4_ext,  "df4">, DwarfRegNum<[36, 36]>;
def DF5  : DFPR< F5,  F5_ext,  "df5">, DwarfRegNum<[37, 37]>;
def DF6  : DFPR< F6,  F6_ext,  "df6">, DwarfRegNum<[38, 38]>;
def DF7  : DFPR< F7,  F7_ext,  "df7">, DwarfRegNum<[39, 39]>;
def DF8  : DFPR< F8,  F8_ext,  "df8">, DwarfRegNum<[40, 40]>;
def DF9  : DFPR< F9,  F9_ext,  "df9">, DwarfRegNum<[41, 41]>;
def DF10 : DFPR<F10, F10_ext, "df10">, DwarfRegNum<[42, 42]>;
def DF11 : DFPR<F11, F11_ext, "df11">, DwarfRegNum<[43, 43]>;
def DF12 : DFPR<F12, F12_ext, "df12">, DwarfRegNum<[44, 44]>;
def DF13 : DFPR<F13, F13_ext, "df13">, DwarfRegNum<[45, 45]>;
def DF14 : DFPR<F14, F14_ext, "df14">, DwarfRegNum<[46, 46]>;
def DF15 : DFPR<F15, F15_ext, "df15">, DwarfRegNum<[47, 47]>;
def DF16 : DFPR<F16, F16_ext, "df16">, DwarfRegNum<[48, 48]>;
def DF17 : DFPR<F17, F17_ext, "df17">, DwarfRegNum<[49, 49]>;
def DF18 : DFPR<F18, F18_ext, "df18">, DwarfRegNum<[50, 50]>;
def DF19 : DFPR<F19, F19_ext, "df19">, DwarfRegNum<[51, 51]>;
def DF20 : DFPR<F20, F20_ext, "df20">, DwarfRegNum<[52, 52]>;
def DF21 : DFPR<F21, F21_ext, "df21">, DwarfRegNum<[53, 53]>;
def DF22 : DFPR<F22, F22_ext, "df22">, DwarfRegNum<[54, 54]>;
def DF23 : DFPR<F23, F23_ext, "df23">, DwarfRegNum<[55, 55]>;
def DF24 : DFPR<F24, F24_ext, "df24">, DwarfRegNum<[56, 56]>;
def DF25 : DFPR<F25, F25_ext, "df25">, DwarfRegNum<[57, 57]>;
def DF26 : DFPR<F26, F26_ext, "df26">, DwarfRegNum<[58, 58]>;
def DF27 : DFPR<F27, F27_ext, "df27">, DwarfRegNum<[59, 59]>;
def DF28 : DFPR<F28, F28_ext, "df28">, DwarfRegNum<[60, 60]>;
def DF29 : DFPR<F29, F29_ext, "df29">, DwarfRegNum<[61, 61]>;
def DF30 : DFPR<F30, F30_ext, "df30">, DwarfRegNum<[62, 62]>;
def DF31 : DFPR<F31, F31_ext, "df31">, DwarfRegNum<[63, 63]>;

// QPX Floating-point registers
def QF0  : QFPR< F0,  F0_ext,  "qf0">, DwarfRegNum<[32, 32]>;
def QF1  : QFPR< F1,  F1_ext,  "qf1">, DwarfRegNum<[33, 33]>;
def QF2  : QFPR< F2,  F2_ext,  "qf2">, DwarfRegNum<[34, 34]>;
def QF3  : QFPR< F3,  F3_ext,  "qf3">, DwarfRegNum<[35, 35]>;
def QF4  : QFPR< F4,  F4_ext,  "qf4">, DwarfRegNum<[36, 36]>;
def QF5  : QFPR< F5,  F5_ext,  "qf5">, DwarfRegNum<[37, 37]>;
def QF6  : QFPR< F6,  F6_ext,  "qf6">, DwarfRegNum<[38, 38]>;
def QF7  : QFPR< F7,  F7_ext,  "qf7">, DwarfRegNum<[39, 39]>;
def QF8  : QFPR< F8,  F8_ext,  "qf8">, DwarfRegNum<[40, 40]>;
def QF9  : QFPR< F9,  F9_ext,  "qf9">, DwarfRegNum<[41, 41]>;
def QF10 : QFPR<F10, F10_ext, "qf10">, DwarfRegNum<[42, 42]>;
def QF11 : QFPR<F11, F11_ext, "qf11">, DwarfRegNum<[43, 43]>;
def QF12 : QFPR<F12, F12_ext, "qf12">, DwarfRegNum<[44, 44]>;
def QF13 : QFPR<F13, F13_ext, "qf13">, DwarfRegNum<[45, 45]>;
def QF14 : QFPR<F14, F14_ext, "qf14">, DwarfRegNum<[46, 46]>;
def QF15 : QFPR<F15, F15_ext, "qf15">, DwarfRegNum<[47, 47]>;
def QF16 : QFPR<F16, F16_ext, "qf16">, DwarfRegNum<[48, 48]>;
def QF17 : QFPR<F17, F17_ext, "qf17">, DwarfRegNum<[49, 49]>;
def QF18 : QFPR<F18, F18_ext, "qf18">, DwarfRegNum<[50, 50]>;
def QF19 : QFPR<F19, F19_ext, "qf19">, DwarfRegNum<[51, 51]>;
def QF20 : QFPR<F20, F20_ext, "qf20">, DwarfRegNum<[52, 52]>;
def QF21 : QFPR<F21, F21_ext, "qf21">, DwarfRegNum<[53, 53]>;
def QF22 : QFPR<F22, F22_ext, "qf22">, DwarfRegNum<[54, 54]>;
def QF23 : QFPR<F23, F23_ext, "qf23">, DwarfRegNum<[55, 55]>;
def QF24 : QFPR<F24, F24_ext, "qf24">, DwarfRegNum<[56, 56]>;
def QF25 : QFPR<F25, F25_ext, "qf25">, DwarfRegNum<[57, 57]>;
def QF26 : QFPR<F26, F26_ext, "qf26">, DwarfRegNum<[58, 58]>;
def QF27 : QFPR<F27, F27_ext, "qf27">, DwarfRegNum<[59, 59]>;
def QF28 : QFPR<F28, F28_ext, "qf28">, DwarfRegNum<[60, 60]>;
def QF29 : QFPR<F29, F29_ext, "qf29">, DwarfRegNum<[61, 61]>;
def QF30 : QFPR<F30, F30_ext, "qf30">, DwarfRegNum<[62, 62]>;
def QF31 : QFPR<F31, F31_ext, "qf31">, DwarfRegNum<[63, 63]>;

// Vector registers
foreach Index = 0-31 in {
  def V#Index : VR<Index, "v"#Index>,
                DwarfRegNum<[!add(Index, 77), !add(Index, 77)]>;
}

// The reprsentation of r0 when treated as the constant 0.
def ZERO  : GPR<0, "0">;
def ZERO8 : GP8<ZERO, "0">;

// Representations of the frame pointer used by ISD::FRAMEADDR.
def FP   : GPR<0 /* arbitrary */, "**FRAME POINTER**">;
def FP8  : GP8<FP, "**FRAME POINTER**">;

// Condition register bits
def CR0LT : CRBIT< 0, "0">;
def CR0GT : CRBIT< 1, "1">;
def CR0EQ : CRBIT< 2, "2">;
def CR0UN : CRBIT< 3, "3">;
def CR1LT : CRBIT< 4, "4">;
def CR1GT : CRBIT< 5, "5">;
def CR1EQ : CRBIT< 6, "6">;
def CR1UN : CRBIT< 7, "7">;
def CR2LT : CRBIT< 8, "8">;
def CR2GT : CRBIT< 9, "9">;
def CR2EQ : CRBIT<10, "10">;
def CR2UN : CRBIT<11, "11">;
def CR3LT : CRBIT<12, "12">;
def CR3GT : CRBIT<13, "13">;
def CR3EQ : CRBIT<14, "14">;
def CR3UN : CRBIT<15, "15">;
def CR4LT : CRBIT<16, "16">;
def CR4GT : CRBIT<17, "17">;
def CR4EQ : CRBIT<18, "18">;
def CR4UN : CRBIT<19, "19">;
def CR5LT : CRBIT<20, "20">;
def CR5GT : CRBIT<21, "21">;
def CR5EQ : CRBIT<22, "22">;
def CR5UN : CRBIT<23, "23">;
def CR6LT : CRBIT<24, "24">;
def CR6GT : CRBIT<25, "25">;
def CR6EQ : CRBIT<26, "26">;
def CR6UN : CRBIT<27, "27">;
def CR7LT : CRBIT<28, "28">;
def CR7GT : CRBIT<29, "29">;
def CR7EQ : CRBIT<30, "30">;
def CR7UN : CRBIT<31, "31">;

// Condition registers
let SubRegIndices = [sub_lt, sub_gt, sub_eq, sub_un] in {
def CR0 : CR<0, "cr0", [CR0LT, CR0GT, CR0EQ, CR0UN]>, DwarfRegNum<[68, 68]>;
def CR1 : CR<1, "cr1", [CR1LT, CR1GT, CR1EQ, CR1UN]>, DwarfRegNum<[69, 69]>;
def CR2 : CR<2, "cr2", [CR2LT, CR2GT, CR2EQ, CR2UN]>, DwarfRegNum<[70, 70]>;
def CR3 : CR<3, "cr3", [CR3LT, CR3GT, CR3EQ, CR3UN]>, DwarfRegNum<[71, 71]>;
def CR4 : CR<4, "cr4", [CR4LT, CR4GT, CR4EQ, CR4UN]>, DwarfRegNum<[72, 72]>;
def CR5 : CR<5, "cr5", [CR5LT, CR5GT, CR5EQ, CR5UN]>, DwarfRegNum<[73, 73]>;
def CR6 : CR<6, "cr6", [CR6LT, CR6GT, CR6EQ, CR6UN]>, DwarfRegNum<[74, 74]>;
def CR7 : CR<7, "cr7", [CR7LT, CR7GT, CR7EQ, CR7UN]>, DwarfRegNum<[75, 75]>;
}

// Link register
def LR  : SPR<8, "lr">, DwarfRegNum<[-2, 65]>;
//let Aliases = [LR] in
def LR8 : SPR<8, "lr">, DwarfRegNum<[65, -2]>;

// Count register
def CTR  : SPR<9, "ctr">, DwarfRegNum<[-2, 66]>;
def CTR8 : SPR<9, "ctr">, DwarfRegNum<[66, -2]>;

// VRsave register
def VRSAVE: SPR<256, "vrsave">, DwarfRegNum<[109]>;

// Carry bit.  In the architecture this is really bit 0 of the XER register
// (which really is SPR register 1);  this is the only bit interesting to a
// compiler.
def CARRY: SPR<1, "ca">;

// FP rounding mode:  bits 30 and 31 of the FP status and control register
// This is not allocated as a normal register; it appears only in
// Uses and Defs.  The ABI says it needs to be preserved by a function,
// but this is not achieved by saving and restoring it as with
// most registers, it has to be done in code; to make this work all the
// return and call instructions are described as Uses of RM, so instructions
// that do nothing but change RM will not get deleted.
// Also, in the architecture it is not really a SPR; 512 is arbitrary.
def RM: SPR<512, "**ROUNDING MODE**">;

/// Register classes
// Allocate volatiles first
// then nonvolatiles in reverse order since stmw/lmw save from rN to r31
def GPRC : RegisterClass<"PPC", [i32], 32, (add (sequence "R%u", 2, 12),
                                                (sequence "R%u", 30, 13),
                                                R31, R0, R1, FP)>;

def G8RC : RegisterClass<"PPC", [i64], 64, (add (sequence "X%u", 2, 12),
                                                (sequence "X%u", 30, 14),
                                                X31, X13, X0, X1, FP8)>;

// For some instructions r0 is special (representing the value 0 instead of
// the value in the r0 register), and we use these register subclasses to
// prevent r0 from being allocated for use by those instructions.
def GPRC_NOR0 : RegisterClass<"PPC", [i32], 32, (add (sub GPRC, R0), ZERO)>;
def G8RC_NOX0 : RegisterClass<"PPC", [i64], 64, (add (sub G8RC, X0), ZERO8)>;

// Allocate volatiles first, then non-volatiles in reverse order. With the SVR4
// ABI the size of the Floating-point register save area is determined by the
// allocated non-volatile register with the lowest register number, as FP
// register N is spilled to offset 8 * (32 - N) below the back chain word of the
// previous stack frame. By allocating non-volatiles in reverse order we make
// sure that the Floating-point register save area is always as small as
// possible because there aren't any unused spill slots.
def F8RC : RegisterClass<"PPC", [f64], 64, (add (sequence "F%u", 0, 13),
                                                (sequence "F%u", 31, 14))>;
def F4RC : RegisterClass<"PPC", [f32], 32, (add F8RC)>;

def VRRC : RegisterClass<"PPC", [v16i8,v8i16,v4i32,v4f32], 128,
                         (add V2, V3, V4, V5, V0, V1, V6, V7, V8, V9, V10, V11,
                             V12, V13, V14, V15, V16, V17, V18, V19, V31, V30,
                             V29, V28, V27, V26, V25, V24, V23, V22, V21, V20)>;

// For FP2
def DFRC : RegisterClass<"PPC", [v2f64], 64, (add (sequence "DF%u", 0, 13),
                                                (sequence "DF%u", 31, 14))>;

// For QPX
def QFRC : RegisterClass<"PPC", [v4f64], 256, (add (sequence "QF%u", 0, 13),
                                                (sequence "QF%u", 31, 14))>;
def QSRC : RegisterClass<"PPC", [v4f32], 128, (add QFRC)>;
def QBRC : RegisterClass<"PPC", [v4i1], 256, (add QFRC)> {
  // These are actually stored as floating-point values where a positive
  // number is true and anything else (including NaN) is false.
  let Size = 256;
}

def CRBITRC : RegisterClass<"PPC", [i32], 32,
  (add CR0LT, CR0GT, CR0EQ, CR0UN,
       CR1LT, CR1GT, CR1EQ, CR1UN,
       CR2LT, CR2GT, CR2EQ, CR2UN,
       CR3LT, CR3GT, CR3EQ, CR3UN,
       CR4LT, CR4GT, CR4EQ, CR4UN,
       CR5LT, CR5GT, CR5EQ, CR5UN,
       CR6LT, CR6GT, CR6EQ, CR6UN,
       CR7LT, CR7GT, CR7EQ, CR7UN)>
{
  let CopyCost = -1;
}

def CRRC : RegisterClass<"PPC", [i32], 32, (add CR0, CR1, CR5, CR6,
                                                CR7, CR2, CR3, CR4)>;

// The CTR registers are not allocatable because they're used by the
// decrement-and-branch instructions, and thus need to stay live across
// multiple basic blocks.
def CTRRC : RegisterClass<"PPC", [i32], 32, (add CTR)> {
  let isAllocatable = 0;
}
def CTRRC8 : RegisterClass<"PPC", [i64], 64, (add CTR8)> {
  let isAllocatable = 0;
}

def VRSAVERC : RegisterClass<"PPC", [i32], 32, (add VRSAVE)>;
def CARRYRC : RegisterClass<"PPC", [i32], 32, (add CARRY)> {
  let CopyCost = -1;
}
