//===- PPCInstrFP2.td - The PowerPC FP2 (Double Hummer) Extension --*- tablegen -*-===//
// 
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
// 
//===----------------------------------------------------------------------===//
//
// This file describes the FP2 (Double Hummer) extension to the PowerPC instruction set.
// Reference:
// PPC440 FP2 Architecture. IBM (as updated in) 2011.
// Available from: https://wiki.alcf.anl.gov/index.php/References
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Helpers for defining instructions that directly correspond to intrinsics.

// FP2A1_Int - A AForm_1 intrinsic definition.
class FP2A1_Int<bits<6> opcode, bits<5> xo, string opc, Intrinsic IntID>
  : AForm_1<opcode, xo, (outs DFRC:$FRT), (ins DFRC:$FRA, DFRC:$FRB, DFRC:$FRC),
              !strconcat(opc, " $FRT, $FRA, $FRC, $FRB"), FPGeneral,
                       [(set DFRC:$FRT, (IntID DFRC:$FRA, DFRC:$FRB, DFRC:$FRC))]>;
// FP2A3_Int - A AForm_3 intrinsic definition.
class FP2A3_Int<bits<6> opcode, bits<5> xo, string opc, Intrinsic IntID>
  : AForm_3<opcode, xo, (outs DFRC:$FRT), (ins DFRC:$FRA, DFRC:$FRC),
              !strconcat(opc, " $FRT, $FRA, $FRC"), FPGeneral,
                       [(set DFRC:$FRT, (IntID DFRC:$FRA, DFRC:$FRC))]>;
// FP2A4_Int - A AForm_4a intrinsic definition.
class FP2A4_Int<bits<6> opcode, bits<5> xo, string opc, Intrinsic IntID>
  : AForm_4a<opcode, xo, (outs DFRC:$FRT), (ins DFRC:$FRB),
              !strconcat(opc, " $FRT, $FRB"), FPGeneral,
                       [(set DFRC:$FRT, (IntID DFRC:$FRB))]>;
// FP2X18_Int - A XForm_18 intrinsic definition.
class FP2X18_Int<bits<6> opcode, bits<10> xo, string opc, Intrinsic IntID>
  : XForm_18<opcode, xo, (outs DFRC:$FRT), (ins DFRC:$FRB),
              !strconcat(opc, " $FRT, $FRB"), FPGeneral,
                       [(set DFRC:$FRT, (IntID DFRC:$FRB))]>;
// FP2X19_Int - A XForm_19 intrinsic definition.
class FP2X19_Int<bits<6> opcode, bits<10> xo, string opc, Intrinsic IntID>
  : XForm_19<opcode, xo, (outs DFRC:$FRT), (ins DFRC:$FRB),
              !strconcat(opc, " $FRT, $FRB"), FPGeneral,
                       [(set DFRC:$FRT, (IntID DFRC:$FRB))]>;

//===----------------------------------------------------------------------===//
// Pattern Frags.

def extloadv2f32 : PatFrag<(ops node:$ptr), (extload node:$ptr), [{
  return cast<LoadSDNode>(N)->getMemoryVT() == MVT::v2f32;
}]>;

def truncstorev2f32 : PatFrag<(ops node:$val, node:$ptr),
                            (truncstore node:$val, node:$ptr), [{
  return cast<StoreSDNode>(N)->getMemoryVT() == MVT::v2f32;
}]>;

def vector_shuffle_0_0 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 0 && SV->getMaskElt(1) == 0;
}]>;

def vector_shuffle_1_1 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 1 && SV->getMaskElt(1) == 1;
}]>;

def vector_shuffle_1_0 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 1 && SV->getMaskElt(1) == 0;
}]>;

def vector_shuffle_1_u : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 1 && SV->getMaskElt(1) < 0;
}]>;

def vector_shuffle_0_2 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 0 && SV->getMaskElt(1) == 2;
}]>;

def vector_shuffle_2_0 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 2 && SV->getMaskElt(1) == 0;
}]>;

def vector_shuffle_0_3 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 0 && SV->getMaskElt(1) == 3;
}]>;

def vector_shuffle_3_0 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 3 && SV->getMaskElt(1) == 0;
}]>;

def vector_shuffle_1_2 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 1 && SV->getMaskElt(1) == 2;
}]>;

def vector_shuffle_2_1 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 2 && SV->getMaskElt(1) == 1;
}]>;

def vector_shuffle_1_3 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 1 && SV->getMaskElt(1) == 3;
}]>;

def vector_shuffle_3_1 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getMaskElt(0) == 3 && SV->getMaskElt(1) == 1;
}]>;

def build_vector_1_neg1 : PatLeaf<(build_vector), [{
  if (N->getNumOperands() < 2) return false;
  SDValue v1 = N->getOperand(0);
  SDValue v2 = N->getOperand(1);

  if (isa<ConstantSDNode>(v1)) {
    if (cast<ConstantSDNode>(v1)->getAPIntValue() != 1)
      return false;
  } else if (isa<ConstantFPSDNode>(v1)) {
    if (!cast<ConstantFPSDNode>(v1)->isExactlyValue(1.0))
      return false;
  } else return false;

  if (isa<ConstantSDNode>(v2)) {
    if (-cast<ConstantSDNode>(v2)->getAPIntValue() != 1)
      return false;
  } else if (isa<ConstantFPSDNode>(v2)) {
    if (!cast<ConstantFPSDNode>(v2)->isExactlyValue(-1.0))
      return false;
  } else return false;

  return true;
}]>;

def build_vector_neg1_1 : PatLeaf<(build_vector), [{
  if (N->getNumOperands() < 2) return false;
  SDValue v1 = N->getOperand(0);
  SDValue v2 = N->getOperand(1);

  if (isa<ConstantSDNode>(v1)) {
    if (-cast<ConstantSDNode>(v1)->getAPIntValue() != 1)
      return false;
  } else if (isa<ConstantFPSDNode>(v1)) {
    if (!cast<ConstantFPSDNode>(v1)->isExactlyValue(-1.0))
      return false;
  } else return false;

  if (isa<ConstantSDNode>(v2)) {
    if (cast<ConstantSDNode>(v2)->getAPIntValue() != 1)
      return false;
  } else if (isa<ConstantFPSDNode>(v2)) {
    if (!cast<ConstantFPSDNode>(v2)->isExactlyValue(1.0))
      return false;
  } else return false;

  return true;
}]>;

//===----------------------------------------------------------------------===//
// Instruction Definitions.

def HasFP2 : Predicate<"PPCSubTarget.hasFP2()">;
let Predicates = [HasFP2] in {

let Uses = [RM] in {
  // Add Instructions
  let isCommutable = 1 in {
    def FPADD : AForm_2<0, 12,
                        (outs DFRC:$FRT), (ins DFRC:$FRA, DFRC:$FRB),
                        "fpadd $FRT, $FRA, $FRB", FPGeneral,
                        [(set DFRC:$FRT, (fadd DFRC:$FRA, DFRC:$FRB))]>;
    }
  def FPSUB : AForm_2<0, 13,
                      (outs DFRC:$FRT), (ins DFRC:$FRA, DFRC:$FRB),
                      "fpsub $FRT, $FRA, $FRB", FPGeneral,
                      [(set DFRC:$FRT, (fsub DFRC:$FRA, DFRC:$FRB))]>;

  // Estimate Instructions
  def FPRE : FP2A4_Int<0, 14, "fpre", int_ppc_fp2_fpre>;
  def FPRSQRTE : FP2A4_Int<0, 15, "fprsqrte", int_ppc_fp2_fpre>;

  // Multiply Instructions
  let isCommutable = 1 in {
    def FPMUL : AForm_3<0, 8,
                        (outs DFRC:$FRT), (ins DFRC:$FRA, DFRC:$FRB),
                        "fpmul $FRT, $FRA, $FRB", FPGeneral,
                        [(set DFRC:$FRT, (fmul DFRC:$FRA, DFRC:$FRB))]>;
  }
  def FXMUL : FP2A3_Int<0, 9, "fxmul", int_ppc_fp2_fxmul>;
  def FXPMUL : FP2A3_Int<0, 10, "fxpmul", int_ppc_fp2_fxpmul>;
  def FXSMUL : FP2A3_Int<0, 11, "fxsmul", int_ppc_fp2_fxsmul>;

  // Multiply-add instructions
  def FPMADD : AForm_1<0, 16,
                      (outs DFRC:$FRT), (ins DFRC:$FRA, DFRC:$FRB, DFRC:$FRC),
                      "fpmadd $FRT, $FRA, $FRC, $FRB", FPGeneral,
                      [(set DFRC:$FRT, (fma DFRC:$FRA, DFRC:$FRC, DFRC:$FRB))]>;
  def FPNMADD : AForm_1<0, 20,
                      (outs DFRC:$FRT), (ins DFRC:$FRA, DFRC:$FRB, DFRC:$FRC),
                      "fpnmadd $FRT, $FRA, $FRC, $FRB", FPGeneral,
                      [(set DFRC:$FRT, (fneg (fma DFRC:$FRA, DFRC:$FRC,
                                             DFRC:$FRB)))]>;
  def FPMSUB : AForm_1<0, 24,
                      (outs DFRC:$FRT), (ins DFRC:$FRA, DFRC:$FRB, DFRC:$FRC),
                      "fpmsub $FRT, $FRA, $FRC, $FRB", FPGeneral,
                      [(set DFRC:$FRT, (fma DFRC:$FRA, DFRC:$FRC,
                                             (fneg DFRC:$FRB)))]>;
  def FPNMSUB : AForm_1<0, 28,
                      (outs DFRC:$FRT), (ins DFRC:$FRA, DFRC:$FRB, DFRC:$FRC),
                      "fpnmsub $FRT, $FRA, $FRC, $FRB", FPGeneral,
                      [(set DFRC:$FRT, (fneg (fma DFRC:$FRA, DFRC:$FRC,
                                             (fneg DFRC:$FRB))))]>;
  def FXMADD : FP2A1_Int<0, 17, "fxmadd", int_ppc_fp2_fxmadd>;
  def FXNMADD : FP2A1_Int<0, 21, "fxnmadd", int_ppc_fp2_fxnmadd>;
  def FXMSUB : FP2A1_Int<0, 25, "fxmsub", int_ppc_fp2_fxmsub>;
  def FXNMSUB : FP2A1_Int<0, 29, "fxnmsub", int_ppc_fp2_fxnmsub>;
  def FXCPMADD : FP2A1_Int<0, 18, "fxcpmadd", int_ppc_fp2_fxcpmadd>;
  def FXCSMADD : FP2A1_Int<0, 19, "fxcsmadd", int_ppc_fp2_fxcsmadd>;
  def FXCPNMADD : FP2A1_Int<0, 22, "fxcpnmadd", int_ppc_fp2_fxcpnmadd>;
  def FXCSNMADD : FP2A1_Int<0, 23, "fxcsnmadd", int_ppc_fp2_fxcsnmadd>;
  def FXCPMSUB : FP2A1_Int<0, 26, "fxcpmsub", int_ppc_fp2_fxcpmsub>;
  def FXCSMSUB : FP2A1_Int<0, 27, "fxcsmsub", int_ppc_fp2_fxcsmsub>;
  def FXCPNMSUB : FP2A1_Int<0, 30, "fxcpnmsub", int_ppc_fp2_fxcpnmsub>;
  def FXCSNMSUB : FP2A1_Int<0, 31, "fxcsnmsub", int_ppc_fp2_fxcsnmsub>;

  // Asymmetric multiply-add instructions
  def FXCPNPMA : FP2A1_Int<4, 24, "fxcpnpma", int_ppc_fp2_fxcpnpma>;
  def FXCSNPMA : FP2A1_Int<4, 25, "fxcsnpma", int_ppc_fp2_fxcsnpma>;
  def FXCPNSMA : FP2A1_Int<4, 26, "fxcpnsma", int_ppc_fp2_fxcpnsma>;
  def FXCSNSMA : FP2A1_Int<4, 27, "fxcsnsma", int_ppc_fp2_fxcsnsma>;

  // Complex multiply-add instructions
  def FXCXNPMA : FP2A1_Int<4, 29, "fxcxnpma", int_ppc_fp2_fxcxnpma>;
  def FXCXNSMA : FP2A1_Int<4, 30, "fxcxnsma", int_ppc_fp2_fxcxnsma>;
  def FXCXMA : FP2A1_Int<4, 28, "fxcxma", int_ppc_fp2_fxcxma>;
  def FXCXNMS : FP2A1_Int<4, 31, "fxcxnms", int_ppc_fp2_fxcxnms>;

  // Select Instruction
  def FPSEL : FP2A1_Int<0, 5, "fpsel", int_ppc_fp2_fpsel>;

  // Convert and Round Instructions
  def FPCTIW : FP2X19_Int<0, 576, "fpctiw", int_ppc_fp2_fpctiw>;
  def FPCTIWZ : FP2X19_Int<0, 704, "fpctiwz", int_ppc_fp2_fpctiwz>;
  def FPRSP : FP2X19_Int<0, 192, "fprsp", int_ppc_fp2_fprsp>;

  // Move Instructions
  def FPMR : XForm_19<0, 32,
                      (outs DFRC:$FRT), (ins DFRC:$FRB),
                      "fpmr $FRT, $FRB", FPGeneral,
                      [/* (set DFRC:$FRT, DFRC:$FRB) */]>;
  def FPNEG : XForm_19<0, 160,
                      (outs DFRC:$FRT), (ins DFRC:$FRB),
                      "fpneg $FRT, $FRB", FPGeneral,
                      [(set DFRC:$FRT, (fneg DFRC:$FRB))]>;
  def FPABS : XForm_19<0, 96,
                      (outs DFRC:$FRT), (ins DFRC:$FRB),
                      "fpabs $FRT, $FRB", FPGeneral,
                      [(set DFRC:$FRT, (fabs DFRC:$FRB))]>;
  def FPNABS : XForm_19<0, 224,
                      (outs DFRC:$FRT), (ins DFRC:$FRB),
                      "fpnabs $FRT, $FRB", FPGeneral,
                      [(set DFRC:$FRT, (fneg (fabs DFRC:$FRB)))]>;
  let Constraints = "$FRTi = $FRT" in {
    def FSMR : XForm_19<0, 288,
                        (outs DFRC:$FRT), (ins DFRC:$FRTi, DFRC:$FRB),
                        "fsmr $FRT, $FRB", FPGeneral, []>;
    def FSNEG : XForm_19<0, 416,
                        (outs DFRC:$FRT), (ins DFRC:$FRTi, DFRC:$FRB),
                        "fsneg $FRT, $FRB", FPGeneral, []>;
    def FSABS : XForm_19<0, 352,
                        (outs DFRC:$FRT), (ins DFRC:$FRTi, DFRC:$FRB),
                        "fsabs $FRT, $FRB", FPGeneral, []>;
    def FSNABS : XForm_19<0, 480,
                        (outs DFRC:$FRT), (ins DFRC:$FRTi, DFRC:$FRB),
                        "fsnabs $FRT, $FRB", FPGeneral, []>;
  }
  def FXMR : XForm_19<0, 544,
                      (outs DFRC:$FRT), (ins DFRC:$FRB),
                      "fxmr $FRT, $FRB", FPGeneral,
                      [(set DFRC:$FRT, (vector_shuffle_1_0 DFRC:$FRB, undef))]>;
  let Constraints = "$FRTi = $FRT" in {
    def FSMFP : XForm_19<0, 928,
                        (outs DFRC:$FRT), (ins DFRC:$FRTi, DFRC:$FRB),
                        "fsmfp $FRT, $FRB", FPGeneral, []>;
    def FSMTP : XForm_19<0, 800,
                        (outs DFRC:$FRT), (ins DFRC:$FRTi, DFRC:$FRB),
                        "fsmtp $FRT, $FRB", FPGeneral, []>;
  }

  // Compare Instruction
  def FSCMP : XForm_17<0, 320,
                      (outs CRRC:$crD), (ins DFRC:$FRA, DFRC:$FRB),
                      "fscmp $crD, $FRA, $FRB", FPCompare>;

  // Load indexed instructions
  let canFoldAsLoad = 1 in {
    def LFPDX : XForm_1<31, 462,
                        (outs DFRC:$FRT), (ins memrr:$src),
                        "lfpdx $FRT, $src", LdStLoad,
                        [(set DFRC:$FRT, (load xoaddr:$src))]>;
    def LFPDUX : XForm_1<31, 494,
                        (outs DFRC:$FRT), (ins memrr:$src),
                        "lfpdux $FRT, $src", LdStLoad, []>;
    def LFPSX : XForm_1<31, 398,
                        (outs DFRC:$FRT), (ins memrr:$src),
                        "lfpsx $FRT, $src", LdStLoad,
                        [(set DFRC:$FRT, (extloadv2f32 xoaddr:$src))]>;
    def LFPSUX : XForm_1<31, 430,
                        (outs DFRC:$FRT), (ins memrr:$src),
                        "lfpsux $FRT, $src", LdStLoad, []>;
    let Constraints = "$FRTi = $FRT" in {
      def LFSDX : XForm_1<31, 206,
                          (outs DFRC:$FRT), (ins DFRC:$FRTi, memrr:$src),
                          "lfsdx $FRT, $src", LdStLoad, []>;
      def LFSDUX : XForm_1<31, 238,
                          (outs DFRC:$FRT), (ins DFRC:$FRTi, memrr:$src),
                          "lfsdux $FRT, $src", LdStLoad, []>;
      def LFSSX : XForm_1<31, 142,
                          (outs DFRC:$FRT), (ins DFRC:$FRTi, memrr:$src),
                          "lfssx $FRT, $src", LdStLoad, []>;
      def LFSSUX : XForm_1<31, 174,
                          (outs DFRC:$FRT), (ins DFRC:$FRTi, memrr:$src),
                          "lfssux $FRT, $src", LdStLoad, []>;
    }
    def LFXDX : XForm_1<31, 334,
                        (outs DFRC:$FRT), (ins memrr:$src),
                        "lfxdx $FRT, $src", LdStLoad,
                        [(set DFRC:$FRT, (vector_shuffle_1_0 (load xoaddr:$src), undef))]>;
    def LFXDUX : XForm_1<31, 366,
                        (outs DFRC:$FRT), (ins memrr:$src),
                        "lfxdux $FRT, $src", LdStLoad, []>;
    def LFXSX : XForm_1<31, 270,
                        (outs DFRC:$FRT), (ins memrr:$src),
                        "lfxsx $FRT, $src", LdStLoad,
                        [(set DFRC:$FRT, (vector_shuffle_1_0 (extloadv2f32 xoaddr:$src), undef))]>;
    def LFXSUX : XForm_1<31, 302,
                        (outs DFRC:$FRT), (ins memrr:$src),
                        "lfxsux $FRT, $src", LdStLoad, []>;
  }

  // Store indexed instructions
  def STFPDX : XForm_8<31, 974,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfpdx $FRT, $dst", LdStStore,
                      [(store DFRC:$FRT, xoaddr:$dst)]>;
  def STFPDUX : XForm_8<31, 1006,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfpdux $FRT, $dst", LdStStore, []>;
  def STFPSX : XForm_8<31, 910,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfpsx $FRT, $dst", LdStStore,
                      [(truncstorev2f32 DFRC:$FRT, xoaddr:$dst)]>;
  def STFPSUX : XForm_8<31, 942,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfpsux $FRT, $dst", LdStStore, []>;
  def STFPIWX : XForm_8<31, 526,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfpiwx $FRT, $dst", LdStStore,
                      [/* (store DFRC:$FRT, xoaddr:$dst) */]>;
  def STFSDX : XForm_8<31, 718,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfpdx $FRT, $dst", LdStStore,
                      [(store (f64 (vector_extract DFRC:$FRT, 1)), xoaddr:$dst)]>;
  def STFSDUX : XForm_8<31, 750,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfpdux $FRT, $dst", LdStStore, []>;
  def STFSSX : XForm_8<31, 654,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfssx $FRT, $dst", LdStStore,
                      [(truncstoref32 (f64 (vector_extract DFRC:$FRT, 1)), xoaddr:$dst)]>;
  def STFSSUX : XForm_8<31, 654,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfssux $FRT, $dst", LdStStore, []>;
  def STFXDX : XForm_8<31, 846,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfxdx $FRT, $dst", LdStStore,
                      [(store (vector_shuffle_1_0 DFRC:$FRT, undef), xoaddr:$dst)]>;
  def STFXDUX : XForm_8<31, 878,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfxdux $FRT, $dst", LdStStore, []>;
  def STFXSX : XForm_8<31, 782,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfxsx $FRT, $dst", LdStStore,
                      [(truncstorev2f32 (vector_shuffle_1_0 DFRC:$FRT, undef), xoaddr:$dst)]>;
  def STFXSUX : XForm_8<31, 814,
                      (outs), (ins DFRC:$FRT, memrr:$dst),
                      "stfxsux $FRT, $dst", LdStStore, []>;
}

//===----------------------------------------------------------------------===//
// Additional FP2 (Double Hummer) Patterns
//

def : Pat<(v2f64 (scalar_to_vector F8RC:$A)),
          (INSERT_SUBREG (v2f64 (IMPLICIT_DEF)), F8RC:$A, sub_64)>;

def : Pat<(f64 (vector_extract DFRC:$S, 0)),
          (EXTRACT_SUBREG DFRC:$S, sub_64)>;

def : Pat<(f64 (vector_extract DFRC:$S, 1)),
          (EXTRACT_SUBREG (FXMR DFRC:$S), sub_64)>;

def : Pat<(vector_shuffle_0_0 DFRC:$A, undef),
          (FSMFP DFRC:$A, DFRC:$A)>;

def : Pat<(vector_shuffle_1_1 DFRC:$A, undef),
          (FSMTP DFRC:$A, DFRC:$A)>;

def : Pat<(vector_shuffle_1_u DFRC:$A, undef),
          (FSMTP DFRC:$A, DFRC:$A)>;

def : Pat<(vector_shuffle_0_2 DFRC:$A, DFRC:$B),
          (FSMFP DFRC:$A, DFRC:$B)>;

def : Pat<(vector_shuffle_2_0 DFRC:$A, DFRC:$B),
          (FSMFP DFRC:$B, DFRC:$A)>;

def : Pat<(vector_shuffle_0_3 DFRC:$A, DFRC:$B),
          (FSMR DFRC:$A, DFRC:$B)>;

def : Pat<(vector_shuffle_3_0 DFRC:$A, DFRC:$B),
          (FXMR (FSMR DFRC:$A, DFRC:$B))>;

def : Pat<(vector_shuffle_1_2 DFRC:$A, DFRC:$B),
          (FXMR (FSMR DFRC:$B, DFRC:$A))>;

def : Pat<(vector_shuffle_2_1 DFRC:$A, DFRC:$B),
          (FSMR DFRC:$B, DFRC:$A)>;

def : Pat<(vector_shuffle_1_3 DFRC:$A, DFRC:$B),
          (FSMR (FXMR DFRC:$A), DFRC:$B)>;

def : Pat<(vector_shuffle_3_1 DFRC:$A, DFRC:$B),
          (FSMR (FXMR DFRC:$B), DFRC:$A)>;

// Add Instructions
def : Pat<(int_ppc_fp2_fpadd DFRC:$A, DFRC:$B),
          (FPADD DFRC:$A, DFRC:$B)>;
def : Pat<(int_ppc_fp2_fpsub DFRC:$A, DFRC:$B),
          (FPSUB DFRC:$A, DFRC:$B)>;

// Multiply Instructions
def : Pat<(int_ppc_fp2_fpmul DFRC:$A, DFRC:$B),
          (FPMUL DFRC:$A, DFRC:$B)>;

def : Pat<(fmul (vector_shuffle_1_0 DFRC:$A, undef), DFRC:$B),
          (FXMUL DFRC:$A, DFRC:$B)>;

def : Pat<(fmul (vector_shuffle_0_0 DFRC:$A, undef), DFRC:$B),
          (FXPMUL DFRC:$A, DFRC:$B)>;

def : Pat<(fmul (vector_shuffle_1_1 DFRC:$A, undef), DFRC:$B),
          (FXSMUL DFRC:$A, DFRC:$B)>;

// Multiply-add instructions
def : Pat<(int_ppc_fp2_fpmadd DFRC:$A, DFRC:$B, DFRC:$C),
          (FPMADD DFRC:$A, DFRC:$B, DFRC:$C)>;
def : Pat<(int_ppc_fp2_fpnmadd DFRC:$A, DFRC:$B, DFRC:$C),
          (FPNMADD DFRC:$A, DFRC:$B, DFRC:$C)>;
def : Pat<(int_ppc_fp2_fpmsub DFRC:$A, DFRC:$B, DFRC:$C),
          (FPMSUB DFRC:$A, DFRC:$B, DFRC:$C)>;
def : Pat<(int_ppc_fp2_fpnmsub DFRC:$A, DFRC:$B, DFRC:$C),
          (FPNMSUB DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fadd (fmul (vector_shuffle_1_0 DFRC:$A, undef), DFRC:$C), DFRC:$B),
          (FXMADD DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fneg (fadd (fmul (vector_shuffle_1_0 DFRC:$A, undef), DFRC:$C), DFRC:$B)),
          (FXNMADD DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fsub (fmul (vector_shuffle_1_0 DFRC:$A, undef), DFRC:$C), DFRC:$B),
          (FXMSUB DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fneg (fsub (fmul (vector_shuffle_1_0 DFRC:$A, undef), DFRC:$C), DFRC:$B)),
          (FXNMSUB DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fadd (fmul (vector_shuffle_0_0 DFRC:$A, undef), DFRC:$C), DFRC:$B),
          (FXCPMADD DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fadd (fmul (vector_shuffle_1_1 DFRC:$A, undef), DFRC:$C), DFRC:$B),
          (FXCSMADD DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fneg (fadd (fmul (vector_shuffle_0_0 DFRC:$A, undef), DFRC:$C), DFRC:$B)),
          (FXCPNMADD DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fneg (fadd (fmul (vector_shuffle_1_1 DFRC:$A, undef), DFRC:$C), DFRC:$B)),
          (FXCSNMADD DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fsub (fmul (vector_shuffle_0_0 DFRC:$A, undef), DFRC:$C), DFRC:$B),
          (FXCPMSUB DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fsub (fmul (vector_shuffle_1_1 DFRC:$A, undef), DFRC:$C), DFRC:$B),
          (FXCSMSUB DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fneg (fsub (fmul (vector_shuffle_0_0 DFRC:$A, undef), DFRC:$C), DFRC:$B)),
          (FXCPNMSUB DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fneg (fsub (fmul (vector_shuffle_1_1 DFRC:$A, undef), DFRC:$C), DFRC:$B)),
          (FXCSNMSUB DFRC:$A, DFRC:$B, DFRC:$C)>;

// Asymmetric multiply-add instructions
def : Pat<(fmul (fadd (fmul (vector_shuffle_0_0 DFRC:$A, undef), DFRC:$C),
            (fmul DFRC:$B, (v2f64 build_vector_neg1_1))), (v2f64 build_vector_neg1_1)),
          (FXCPNPMA DFRC:$A, DFRC:$B, DFRC:$C)>;
def : Pat<(fmul (fsub (fmul (vector_shuffle_0_0 DFRC:$A, undef), DFRC:$C),
            (fmul DFRC:$B, (v2f64 build_vector_1_neg1))), (v2f64 build_vector_neg1_1)),
          (FXCPNPMA DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fmul (fadd (fmul (vector_shuffle_1_1 DFRC:$A, undef), DFRC:$C),
            (fmul DFRC:$B, (v2f64 build_vector_neg1_1))), (v2f64 build_vector_neg1_1)),
          (FXCSNPMA DFRC:$A, DFRC:$B, DFRC:$C)>;
def : Pat<(fmul (fsub (fmul (vector_shuffle_1_1 DFRC:$A, undef), DFRC:$C),
            (fmul DFRC:$B, (v2f64 build_vector_1_neg1))), (v2f64 build_vector_neg1_1)),
          (FXCSNPMA DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fmul (fadd (fmul (vector_shuffle_0_0 DFRC:$A, undef), DFRC:$C),
            (fmul DFRC:$B, (v2f64 build_vector_1_neg1))), (v2f64 build_vector_1_neg1)),
          (FXCPNSMA DFRC:$A, DFRC:$B, DFRC:$C)>;
def : Pat<(fmul (fsub (fmul (vector_shuffle_0_0 DFRC:$A, undef), DFRC:$C),
            (fmul DFRC:$B, (v2f64 build_vector_neg1_1))), (v2f64 build_vector_1_neg1)),
          (FXCPNSMA DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fmul (fadd (fmul (vector_shuffle_1_1 DFRC:$A, undef), DFRC:$C),
            (fmul DFRC:$B, (v2f64 build_vector_1_neg1))), (v2f64 build_vector_1_neg1)),
          (FXCSNSMA DFRC:$A, DFRC:$B, DFRC:$C)>;
def : Pat<(fmul (fsub (fmul (vector_shuffle_1_1 DFRC:$A, undef), DFRC:$C),
            (fmul DFRC:$B, (v2f64 build_vector_neg1_1))), (v2f64 build_vector_1_neg1)),
          (FXCSNSMA DFRC:$A, DFRC:$B, DFRC:$C)>;

// Complex multiply-add instructions
def : Pat<(fmul (fadd (fmul (vector_shuffle_1_1 DFRC:$A, undef),
                            (vector_shuffle_1_0 DFRC:$C, undef)),
            (fmul DFRC:$B, (v2f64 build_vector_neg1_1))), (v2f64 build_vector_neg1_1)),
          (FXCXNPMA DFRC:$A, DFRC:$B, DFRC:$C)>;
def : Pat<(fmul (fsub (fmul (vector_shuffle_1_1 DFRC:$A, undef),
                            (vector_shuffle_1_0 DFRC:$C, undef)),
            (fmul DFRC:$B, (v2f64 build_vector_1_neg1))), (v2f64 build_vector_neg1_1)),
          (FXCXNPMA DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fmul (fadd (fmul (vector_shuffle_1_1 DFRC:$A, undef),
                            (vector_shuffle_1_0 DFRC:$C, undef)),
            (fmul DFRC:$B, (v2f64 build_vector_1_neg1))), (v2f64 build_vector_1_neg1)),
          (FXCXNSMA DFRC:$A, DFRC:$B, DFRC:$C)>;
def : Pat<(fmul (fsub (fmul (vector_shuffle_1_1 DFRC:$A, undef),
                            (vector_shuffle_1_0 DFRC:$C, undef)),
            (fmul DFRC:$B, (v2f64 build_vector_neg1_1))), (v2f64 build_vector_1_neg1)),
          (FXCXNSMA DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fadd (fmul (vector_shuffle_1_1 DFRC:$A, undef),
                            (vector_shuffle_1_0 DFRC:$C, undef)), DFRC:$B),
          (FXCXMA DFRC:$A, DFRC:$B, DFRC:$C)>;

def : Pat<(fneg (fsub (fmul (vector_shuffle_1_1 DFRC:$A, undef),
                            (vector_shuffle_1_0 DFRC:$C, undef)), DFRC:$B)),
          (FXCXNMS DFRC:$A, DFRC:$B, DFRC:$C)>;

// Convert and Round Instructions
def : Pat<(int_ppc_fp2_fpctiw DFRC:$A),
          (FPCTIW DFRC:$A)>;

// Move Instructions
def : Pat<(int_ppc_fp2_fpneg DFRC:$A),
          (FPNEG DFRC:$A)>;
def : Pat<(int_ppc_fp2_fpabs DFRC:$A),
          (FPABS DFRC:$A)>;
def : Pat<(int_ppc_fp2_fpnabs DFRC:$A),
          (FPNABS DFRC:$A)>;
def : Pat<(int_ppc_fp2_fxmr DFRC:$A),
          (FXMR DFRC:$A)>;

// Load indexed instructions
def : Pat<(int_ppc_fp2_lfpd xoaddr:$src),
          (LFPDX xoaddr:$src)>;
def : Pat<(int_ppc_fp2_lfps xoaddr:$src),
          (LFPSX xoaddr:$src)>;
def : Pat<(int_ppc_fp2_lfxd xoaddr:$src),
          (LFXDX xoaddr:$src)>;
def : Pat<(int_ppc_fp2_lfxs xoaddr:$src),
          (LFXSX xoaddr:$src)>;

// Store indexed instructions
def : Pat<(int_ppc_fp2_stfpd DFRC:$T, xoaddr:$dst),
          (STFPDX DFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_fp2_stfps DFRC:$T, xoaddr:$dst),
          (STFPSX DFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_fp2_stfpiw DFRC:$T, xoaddr:$dst),
          (STFPIWX DFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_fp2_stfxd DFRC:$T, xoaddr:$dst),
          (STFXDX DFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_fp2_stfxs DFRC:$T, xoaddr:$dst),
          (STFXSX DFRC:$T, xoaddr:$dst)>;

} // end HasFP2

