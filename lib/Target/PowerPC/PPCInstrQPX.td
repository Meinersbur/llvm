//===- PPCInstrQPX.td - The PowerPC QPX Extension --*- tablegen -*-===//
// 
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
// 
//===----------------------------------------------------------------------===//
//
// This file describes the QPX extension to the PowerPC instruction set.
// Reference:
// Book Q: QPX Architecture Definition. IBM (as updated in) 2011.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Helpers for defining instructions that directly correspond to intrinsics.

// QPXA1_Int - A AForm_1 intrinsic definition.
class QPXA1_Int<bits<6> opcode, bits<5> xo, string opc, Intrinsic IntID>
  : AForm_1<opcode, xo, (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB, QFRC:$FRC),
              !strconcat(opc, " $FRT, $FRA, $FRC, $FRB"), FPGeneral,
                       [(set QFRC:$FRT, (IntID QFRC:$FRA, QFRC:$FRB, QFRC:$FRC))]>;
// QPXA2_Int - A AForm_2 intrinsic definition.
class QPXA2_Int<bits<6> opcode, bits<5> xo, string opc, Intrinsic IntID>
  : AForm_2<opcode, xo, (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRC),
              !strconcat(opc, " $FRT, $FRA, $FRC"), FPGeneral,
                       [(set QFRC:$FRT, (IntID QFRC:$FRA, QFRC:$FRC))]>;
// QPXA3_Int - A AForm_3 intrinsic definition.
class QPXA3_Int<bits<6> opcode, bits<5> xo, string opc, Intrinsic IntID>
  : AForm_3<opcode, xo, (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRC),
              !strconcat(opc, " $FRT, $FRA, $FRC"), FPGeneral,
                       [(set QFRC:$FRT, (IntID QFRC:$FRA, QFRC:$FRC))]>;
// QPXA4_Int - A AForm_4a intrinsic definition.
class QPXA4_Int<bits<6> opcode, bits<5> xo, string opc, Intrinsic IntID>
  : AForm_4a<opcode, xo, (outs QFRC:$FRT), (ins QFRC:$FRB),
              !strconcat(opc, " $FRT, $FRB"), FPGeneral,
                       [(set QFRC:$FRT, (IntID QFRC:$FRB))]>;
// QPXX18_Int - A XForm_18 intrinsic definition.
class QPXX18_Int<bits<6> opcode, bits<10> xo, string opc, Intrinsic IntID>
  : XForm_18<opcode, xo, (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB),
              !strconcat(opc, " $FRT, $FRA, $FRB"), FPCompare,
                       [(set QFRC:$FRT, (IntID QFRC:$FRA, QFRC:$FRB))]>;
// QPXX19_Int - A XForm_19 intrinsic definition.
class QPXX19_Int<bits<6> opcode, bits<10> xo, string opc, Intrinsic IntID>
  : XForm_19<opcode, xo, (outs QFRC:$FRT), (ins QFRC:$FRB),
              !strconcat(opc, " $FRT, $FRB"), FPGeneral,
                       [(set QFRC:$FRT, (IntID QFRC:$FRB))]>;

//===----------------------------------------------------------------------===//
// Pattern Frags.

def extloadv4f32 : PatFrag<(ops node:$ptr), (extload node:$ptr), [{
  return cast<LoadSDNode>(N)->getMemoryVT() == MVT::v4f32;
}]>;

def truncstorev4f32 : PatFrag<(ops node:$val, node:$ptr),
                            (truncstore node:$val, node:$ptr), [{
  return cast<StoreSDNode>(N)->getMemoryVT() == MVT::v4f32;
}]>;

def vector_shuffle_0_1_0_1 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getValueType(0).getVectorNumElements() == 4 &&
         SV->getMaskElt(0) == 0 && SV->getMaskElt(1) == 1 &&
         SV->getMaskElt(2) == 0 && SV->getMaskElt(3) == 1;
}]>;

def vector_shuffle_0_1 : PatFrag<(ops node:$lhs, node:$rhs),
                              (vector_shuffle node:$lhs, node:$rhs), [{
  ShuffleVectorSDNode *SV = cast<ShuffleVectorSDNode>(N);
  return SV->getValueType(0).getVectorNumElements() == 2 &&
         SV->getMaskElt(0) == 0 && SV->getMaskElt(1) == 1;
}]>;

//===----------------------------------------------------------------------===//
// Instruction Definitions.

def HasQPX : Predicate<"PPCSubTarget.hasQPX()">;
let Predicates = [HasQPX] in {
let neverHasSideEffects = 1 in { // QPX instructions don't have side effects.
let Uses = [RM] in {
  // Add Instructions
  let isCommutable = 1 in {
    def QVFADD : AForm_2<4, 21,
                        (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB),
                        "qvfadd $FRT, $FRA, $FRB", FPGeneral,
                        [(set QFRC:$FRT, (fadd QFRC:$FRA, QFRC:$FRB))]>;
    let isCodeGenOnly = 1 in
      def QVFADDS : QPXA2_Int<0, 21, "qvfadds", int_ppc_qpx_qvfadds>;
    def QVFADDSs : AForm_2<0, 21,
                          (outs QSRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB),
                          "qvfadds $FRT, $FRA, $FRB", FPGeneral,
                          [(set QSRC:$FRT, (fadd QSRC:$FRA, QSRC:$FRB))]>;
  }
  def QVFSUB : AForm_2<4, 20,
                      (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB),
                      "qvfsub $FRT, $FRA, $FRB", FPGeneral,
                      [(set QFRC:$FRT, (fsub QFRC:$FRA, QFRC:$FRB))]>;
  let isCodeGenOnly = 1 in
    def QVFSUBS : QPXA2_Int<0, 20, "qvfsubs", int_ppc_qpx_qvfsubs>;
  def QVFSUBSs : AForm_2<0, 20,
                        (outs QSRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB),
                        "qvfsubs $FRT, $FRA, $FRB", FPGeneral,
                        [(set QSRC:$FRT, (fsub QSRC:$FRA, QSRC:$FRB))]>;

  // Estimate Instructions
  def QVFRE : AForm_4a<4, 24, (outs QFRC:$FRT), (ins QFRC:$FRB),
                       "qvfre $FRT, $FRB", FPGeneral,
                       [(set v4f64:$FRT, (PPCfre v4f64:$FRB))]>;
  def QVFRES : QPXA4_Int<0, 24, "qvfres", int_ppc_qpx_qvfres>;
  let isCodeGenOnly = 1 in
  def QVFRESs : AForm_4a<0, 24, (outs QSRC:$FRT), (ins QSRC:$FRB),
                         "qvfres $FRT, $FRB", FPGeneral,
                         [(set v4f32:$FRT, (PPCfre v4f32:$FRB))]>;

  def QVFRSQRTE : AForm_4a<4, 26, (outs QFRC:$FRT), (ins QFRC:$FRB),
                           "qvfrsqrte $FRT, $FRB", FPGeneral,
                           [(set v4f64:$FRT, (PPCfrsqrte v4f64:$FRB))]>;
  def QVFRSQRTES : QPXA4_Int<0, 26, "qvfrsqrtes", int_ppc_qpx_qvfrsqrtes>;
  let isCodeGenOnly = 1 in
  def QVFRSQRTESs : AForm_4a<0, 26, (outs QSRC:$FRT), (ins QSRC:$FRB),
                             "qvfrsqrtes $FRT, $FRB", FPGeneral,
                             [(set v4f32:$FRT, (PPCfrsqrte v4f32:$FRB))]>;

  // Multiply Instructions
  let isCommutable = 1 in {
    def QVFMUL : AForm_3<4, 25,
                        (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB),
                        "qvfmul $FRT, $FRA, $FRB", FPGeneral,
                        [(set QFRC:$FRT, (fmul QFRC:$FRA, QFRC:$FRB))]>;
    let isCodeGenOnly = 1 in
      def QVFMULS : QPXA3_Int<0, 25, "qvfmuls", int_ppc_qpx_qvfmuls>;
    def QVFMULSs : AForm_3<0, 25,
                          (outs QSRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB),
                          "qvfmuls $FRT, $FRA, $FRB", FPGeneral,
                          [(set QSRC:$FRT, (fmul QSRC:$FRA, QSRC:$FRB))]>;
  }
  def QVFXMUL : QPXA3_Int<4, 17, "qvfxmul", int_ppc_qpx_qvfxmul>;
  def QVFXMULS : QPXA3_Int<0, 17, "qvfxmul", int_ppc_qpx_qvfxmuls>;

  // Multiply-add instructions
  def QVFMADD : AForm_1<4, 29,
                      (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB, QFRC:$FRC),
                      "qvfmadd $FRT, $FRA, $FRC, $FRB", FPGeneral,
                      [(set QFRC:$FRT, (fma QFRC:$FRA, QFRC:$FRC, QFRC:$FRB))]>;
  let isCodeGenOnly = 1 in
    def QVFMADDS : QPXA1_Int<0, 29, "qvfmadds", int_ppc_qpx_qvfmadds>;
  def QVFMADDSs : AForm_1<0, 29,
                        (outs QSRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB, QSRC:$FRC),
                        "qvfmadds $FRT, $FRA, $FRC, $FRB", FPGeneral,
                        [(set QSRC:$FRT, (fma QSRC:$FRA, QSRC:$FRC, QSRC:$FRB))]>;
  def QVFNMADD : AForm_1<4, 31,
                      (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB, QFRC:$FRC),
                      "qvfnmadd $FRT, $FRA, $FRC, $FRB", FPGeneral,
                      [(set QFRC:$FRT, (fneg (fma QFRC:$FRA, QFRC:$FRC,
                                             QFRC:$FRB)))]>;
  let isCodeGenOnly = 1 in
    def QVFNMADDS : QPXA1_Int<0, 31, "qvfnmadds", int_ppc_qpx_qvfnmadds>;
  def QVFNMADDSs : AForm_1<0, 31,
                        (outs QSRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB, QSRC:$FRC),
                        "qvfnmadds $FRT, $FRA, $FRC, $FRB", FPGeneral,
                        [(set QSRC:$FRT, (fneg (fma QSRC:$FRA, QSRC:$FRC,
                                               QSRC:$FRB)))]>;
  def QVFMSUB : AForm_1<4, 28,
                      (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB, QFRC:$FRC),
                      "qvfmsub $FRT, $FRA, $FRC, $FRB", FPGeneral,
                      [(set QFRC:$FRT, (fma QFRC:$FRA, QFRC:$FRC,
                                             (fneg QFRC:$FRB)))]>;
  let isCodeGenOnly = 1 in
    def QVFMSUBS : QPXA1_Int<0, 28, "qvfmsubs", int_ppc_qpx_qvfmsubs>;
  def QVFMSUBSs : AForm_1<0, 28,
                      (outs QSRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB, QSRC:$FRC),
                      "qvfmsubs $FRT, $FRA, $FRC, $FRB", FPGeneral,
                      [(set QSRC:$FRT, (fma QSRC:$FRA, QSRC:$FRC,
                                             (fneg QSRC:$FRB)))]>;
  def QVFNMSUB : AForm_1<4, 30,
                      (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB, QFRC:$FRC),
                      "qvfnmsub $FRT, $FRA, $FRC, $FRB", FPGeneral,
                      [(set QFRC:$FRT, (fneg (fma QFRC:$FRA, QFRC:$FRC,
                                             (fneg QFRC:$FRB))))]>;
  let isCodeGenOnly = 1 in
    def QVFNMSUBS : QPXA1_Int<0, 30, "qvfnmsubs", int_ppc_qpx_qvfnmsubs>;
  def QVFNMSUBSs : AForm_1<0, 30,
                      (outs QSRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB, QSRC:$FRC),
                      "qvfnmsubs $FRT, $FRA, $FRC, $FRB", FPGeneral,
                      [(set QSRC:$FRT, (fneg (fma QSRC:$FRA, QSRC:$FRC,
                                             (fneg QSRC:$FRB))))]>;
  def QVFXMADD : QPXA1_Int<4, 9, "qvfxmadd", int_ppc_qpx_qvfxmadd>;
  def QVFXMADDS : QPXA1_Int<0, 9, "qvfxmadds", int_ppc_qpx_qvfxmadds>;
  def QVFXXNPMADD : QPXA1_Int<4, 11, "qvfxxnpmadd", int_ppc_qpx_qvfxxnpmadd>;
  def QVFXXNPMADDS : QPXA1_Int<0, 11, "qvfxxnpmadds", int_ppc_qpx_qvfxxnpmadds>;
  def QVFXXCPNMADD : QPXA1_Int<4, 3, "qvfxxcpnmadd", int_ppc_qpx_qvfxxcpnmadd>;
  def QVFXXCPNMADDS : QPXA1_Int<0, 3, "qvfxxcpnmadds", int_ppc_qpx_qvfxxcpnmadds>;
  def QVFXXMADD : QPXA1_Int<4, 1, "qvfxxmadd", int_ppc_qpx_qvfxxmadd>;
  def QVFXXMADDS : QPXA1_Int<4, 1, "qvfxxmadds", int_ppc_qpx_qvfxxmadds>;

  // Select Instruction
  let isCodeGenOnly = 1 in
    def QVFSEL : QPXA1_Int<4, 23, "qvfsel", int_ppc_qpx_qvfsel>;
  def QVFSELb : AForm_1<4, 23, (outs QFRC:$FRT),
                        (ins QBRC:$FRA, QFRC:$FRB, QFRC:$FRC),
                        "qvfsel $FRT, $FRA, $FRC, $FRB", FPGeneral,
                        [(set QFRC:$FRT, (vselect QBRC:$FRA,
                                                  QFRC:$FRC, QFRC:$FRB))]>;
  let isCodeGenOnly = 1 in
  def QVFSELbs : AForm_1<4, 23, (outs QSRC:$FRT),
                        (ins QBRC:$FRA, QSRC:$FRB, QSRC:$FRC),
                        "qvfsel $FRT, $FRA, $FRC, $FRB", FPGeneral,
                        [(set QSRC:$FRT, (vselect QBRC:$FRA,
                                                  QSRC:$FRC, QSRC:$FRB))]>;
  let isCodeGenOnly = 1 in
  def QVFSELbb: AForm_1<4, 23, (outs QBRC:$FRT),
                        (ins QBRC:$FRA, QBRC:$FRB, QBRC:$FRC),
                        "qvfsel $FRT, $FRA, $FRC, $FRB", FPGeneral,
                        [(set QBRC:$FRT, (vselect QBRC:$FRA,
                                                  QBRC:$FRC, QBRC:$FRB))]>;

  // Convert and Round Instructions
  def QVFCTID : QPXX19_Int<4, 814, "qvfctid", int_ppc_qpx_qvfctid>;
  def QVFCTIDb : XForm_19<4, 814, (outs QBRC:$FRT), (ins QBRC:$FRB),
                         "qvfctid $FRT, $FRB", FPGeneral, []>;

  def QVFCTIDU : QPXX19_Int<4, 942, "qvfctidu", int_ppc_qpx_qvfctidu>;
  def QVFCTIDZ : QPXX19_Int<4, 815, "qvfctidz", int_ppc_qpx_qvfctidz>;
  def QVFCTIDUZ : QPXX19_Int<4, 143, "qvfctiduz", int_ppc_qpx_qvfctiduz>;
  def QVFCTIW : QPXX19_Int<4, 14, "qvfctiw", int_ppc_qpx_qvfctiw>;
  def QVFCTIWU : QPXX19_Int<4, 142, "qvfctiwu", int_ppc_qpx_qvfctiwu>;
  def QVFCTIWZ : QPXX19_Int<4, 15, "qvfctiwz", int_ppc_qpx_qvfctiwz>;
  def QVFCTIWUZ : QPXX19_Int<4, 943, "qvfctiwuz", int_ppc_qpx_qvfctiwuz>;
  def QVFCFID : QPXX19_Int<4, 846, "qvfcfid", int_ppc_qpx_qvfcfid>;
  def QVFCFIDb : XForm_19<4, 846, (outs QBRC:$FRT), (ins QBRC:$FRB),
                         "qvfcfid $FRT, $FRB", FPGeneral, []>;

  def QVFCFIDU : QPXX19_Int<4, 974, "qvfcfidu", int_ppc_qpx_qvfcfidu>;
  def QVFCFIDS : QPXX19_Int<0, 846, "qvfcfids", int_ppc_qpx_qvfcfids>;
  def QVFCFIDUS : QPXX19_Int<0, 974, "qvfcfidus", int_ppc_qpx_qvfcfidus>;

  let isCodeGenOnly = 1 in
    def QVFRSP : QPXX19_Int<4, 12, "qvfrsp", int_ppc_qpx_qvfrsp>;
  def QVFRSPs : XForm_19<4, 12,
                      (outs QSRC:$FRT), (ins QFRC:$FRB),
                      "qvfrsp $FRT, $FRB", FPGeneral,
                      [(set QSRC:$FRT, (fround QFRC:$FRB))]>;

  def QVFRIZ : XForm_19<4, 424, (outs QFRC:$FRT), (ins QFRC:$FRB),
                        "qvfriz $FRT, $FRB", FPGeneral,
                        [(set v4f64:$FRT, (ftrunc v4f64:$FRB))]>;
  let isCodeGenOnly = 1 in
    def QVFRIZs : XForm_19<4, 424, (outs QSRC:$FRT), (ins QSRC:$FRB),
                           "qvfriz $FRT, $FRB", FPGeneral,
                           [(set v4f32:$FRT, (ftrunc v4f32:$FRB))]>;

  def QVFRIN : XForm_19<4, 392, (outs QFRC:$FRT), (ins QFRC:$FRB),
                        "qvfrin $FRT, $FRB", FPGeneral,
                        [(set v4f64:$FRT, (fnearbyint v4f64:$FRB))]>;
  let isCodeGenOnly = 1 in
    def QVFRINs : XForm_19<4, 392, (outs QSRC:$FRT), (ins QSRC:$FRB),
                           "qvfrin $FRT, $FRB", FPGeneral,
                           [(set v4f32:$FRT, (fnearbyint v4f32:$FRB))]>;

  def QVFRIP : XForm_19<4, 456, (outs QFRC:$FRT), (ins QFRC:$FRB),
                        "qvfrip $FRT, $FRB", FPGeneral,
                        [(set v4f64:$FRT, (fceil v4f64:$FRB))]>;
  let isCodeGenOnly = 1 in
    def QVFRIPs : XForm_19<4, 456, (outs QSRC:$FRT), (ins QSRC:$FRB),
                           "qvfrip $FRT, $FRB", FPGeneral,
                           [(set v4f32:$FRT, (fceil v4f32:$FRB))]>;

  def QVFRIM : XForm_19<4, 488, (outs QFRC:$FRT), (ins QFRC:$FRB),
                        "qvfrim $FRT, $FRB", FPGeneral,
                        [(set v4f64:$FRT, (ffloor v4f64:$FRB))]>;
  let isCodeGenOnly = 1 in
    def QVFRIMs : XForm_19<4, 488, (outs QSRC:$FRT), (ins QSRC:$FRB),
                           "qvfrim $FRT, $FRB", FPGeneral,
                           [(set v4f32:$FRT, (ffloor v4f32:$FRB))]>;

  // Move Instructions
  def QVFMR : XForm_19<4, 74,
                      (outs QFRC:$FRT), (ins QFRC:$FRB),
                      "qvfmr $FRT, $FRB", FPGeneral,
                      [/* (set QFRC:$FRT, QFRC:$FRB) */]>;
  let isCodeGenOnly = 1 in {
    def QVFMRs : XForm_19<4, 74,
                         (outs QSRC:$FRT), (ins QSRC:$FRB),
                         "qvfmr $FRT, $FRB", FPGeneral,
                         [/* (set QSRC:$FRT, QSRC:$FRB) */]>;
    def QVFMRb : XForm_19<4, 74,
                         (outs QBRC:$FRT), (ins QBRC:$FRB),
                         "qvfmr $FRT, $FRB", FPGeneral,
                         [/* (set QBRC:$FRT, QBRC:$FRB) */]>;
  }
  def QVFNEG : XForm_19<4, 40,
                      (outs QFRC:$FRT), (ins QFRC:$FRB),
                      "qvfneg $FRT, $FRB", FPGeneral,
                      [(set QFRC:$FRT, (fneg QFRC:$FRB))]>;
  let isCodeGenOnly = 1 in
    def QVFNEGs : XForm_19<4, 40,
                         (outs QSRC:$FRT), (ins QSRC:$FRB),
                         "qvfneg $FRT, $FRB", FPGeneral,
                         [(set QSRC:$FRT, (fneg QSRC:$FRB))]>;
  def QVFABS : XForm_19<4, 264,
                      (outs QFRC:$FRT), (ins QFRC:$FRB),
                      "qvfabs $FRT, $FRB", FPGeneral,
                      [(set QFRC:$FRT, (fabs QFRC:$FRB))]>;
  let isCodeGenOnly = 1 in
    def QVFABSs : XForm_19<4, 264,
                         (outs QSRC:$FRT), (ins QSRC:$FRB),
                         "qvfabs $FRT, $FRB", FPGeneral,
                         [(set QSRC:$FRT, (fabs QSRC:$FRB))]>;
  def QVFNABS : XForm_19<4, 136,
                      (outs QFRC:$FRT), (ins QFRC:$FRB),
                      "qvfnabs $FRT, $FRB", FPGeneral,
                      [(set QFRC:$FRT, (fneg (fabs QFRC:$FRB)))]>;
  let isCodeGenOnly = 1 in
    def QVFNABSs : XForm_19<4, 136,
                         (outs QSRC:$FRT), (ins QSRC:$FRB),
                         "qvfnabs $FRT, $FRB", FPGeneral,
                         [(set QSRC:$FRT, (fneg (fabs QSRC:$FRB)))]>;
  def QVFCPSGN : XForm_18<4, 74,
                      (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB),
                      "qvfcpsgn $FRT, $FRA, $FRB", FPGeneral, []>;

  def QVALIGNI : Z23Form_1<4, 5,
                      (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB, u2imm:$idx),
                      "qvaligni $FRT, $FRA, $FRB, $idx", FPGeneral,
                      [(set QFRC:$FRT,
                          (PPCqvaligni QFRC:$FRA, QFRC:$FRB, (i32 imm:$idx)))]>;
  let isCodeGenOnly = 1 in
     def QVALIGNIs : Z23Form_1<4, 5,
                         (outs QSRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB, u2imm:$idx),
                         "qvaligni $FRT, $FRA, $FRB, $idx", FPGeneral,
                         [(set QSRC:$FRT,
                             (PPCqvaligni QSRC:$FRA, QSRC:$FRB, (i32 imm:$idx)))]>;
  let isCodeGenOnly = 1 in
     def QVALIGNIb : Z23Form_1<4, 5,
                         (outs QBRC:$FRT), (ins QBRC:$FRA, QBRC:$FRB, u2imm:$idx),
                         "qvaligni $FRT, $FRA, $FRB, $idx", FPGeneral,
                         [(set QBRC:$FRT,
                             (PPCqvaligni QBRC:$FRA, QBRC:$FRB, (i32 imm:$idx)))]>;

  def QVESPLATI : Z23Form_2<4, 37,
                      (outs QFRC:$FRT), (ins QFRC:$FRA, u2imm:$idx),
                      "qvesplati $FRT, $FRA, $idx", FPGeneral,
                      [(set QFRC:$FRT,
                          (PPCqvesplati QFRC:$FRA, (i32 imm:$idx)))]>;
  let isCodeGenOnly = 1 in
     def QVESPLATIs : Z23Form_2<4, 37,
                         (outs QSRC:$FRT), (ins QSRC:$FRA, u2imm:$idx),
                         "qvesplati $FRT, $FRA, $idx", FPGeneral,
                         [(set QSRC:$FRT,
                             (PPCqvesplati QSRC:$FRA, (i32 imm:$idx)))]>;
  let isCodeGenOnly = 1 in
     def QVESPLATIb : Z23Form_2<4, 37,
                         (outs QBRC:$FRT), (ins QBRC:$FRA, u2imm:$idx),
                         "qvesplati $FRT, $FRA, $idx", FPGeneral,
                         [(set QBRC:$FRT,
                             (PPCqvesplati QBRC:$FRA, (i32 imm:$idx)))]>;

  def QVFPERM : AForm_1<4, 6,
                      (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB, QFRC:$FRC),
                      "qvfperm $FRT, $FRA, $FRB, $FRC", FPGeneral,
                      [(set QFRC:$FRT,
                          (PPCqvfperm QFRC:$FRA, QFRC:$FRB, QFRC:$FRC))]>;
  let isCodeGenOnly = 1 in
     def QVFPERMs : AForm_1<4, 6,
                         (outs QSRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB, QFRC:$FRC),
                         "qvfperm $FRT, $FRA, $FRB, $FRC", FPGeneral,
                         [(set QSRC:$FRT,
                             (PPCqvfperm QSRC:$FRA, QSRC:$FRB, QFRC:$FRC))]>;

  let isReMaterializable = 1, isAsCheapAsAMove = 1 in
  def QVGPCI : Z23Form_3<4, 133,
                      (outs QFRC:$FRT), (ins u12imm:$idx),
                      "qvgpci $FRT, $idx", FPGeneral,
                      [(set QFRC:$FRT, (PPCqvgpci (i32 imm:$idx)))]>;

  // Compare Instruction
  let isCodeGenOnly = 1 in
    def QVFTSTNAN : QPXX18_Int<4, 64, "qvftstnan", int_ppc_qpx_qvftstnan>;
  def QVFTSTNANb : XForm_18<4, 64, (outs QBRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB),
                           "qvftstnan $FRT, $FRA, $FRB", FPCompare,
                           [(set QBRC:$FRT,
                                 (setcc QFRC:$FRA, QFRC:$FRB, SETUO))]>;
  let isCodeGenOnly = 1 in
  def QVFTSTNANbs : XForm_18<4, 64, (outs QBRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB),
                            "qvftstnan $FRT, $FRA, $FRB", FPCompare,
                            [(set QBRC:$FRT,
                                  (setcc QSRC:$FRA, QSRC:$FRB, SETUO))]>;
  let isCodeGenOnly = 1 in
    def QVFCMPLT : QPXX18_Int<4, 96, "qvfcmplt", int_ppc_qpx_qvfcmplt>;
  def QVFCMPLTb : XForm_18<4, 96, (outs QBRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB),
                           "qvfcmplt $FRT, $FRA, $FRB", FPCompare,
                           [(set QBRC:$FRT,
                                 (setcc QFRC:$FRA, QFRC:$FRB, SETOLT))]>;
  let isCodeGenOnly = 1 in
  def QVFCMPLTbs : XForm_18<4, 96, (outs QBRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB),
                            "qvfcmplt $FRT, $FRA, $FRB", FPCompare,
                            [(set QBRC:$FRT,
                                  (setcc QSRC:$FRA, QSRC:$FRB, SETOLT))]>;
  let isCodeGenOnly = 1 in
    def QVFCMPGT : QPXX18_Int<4, 32, "qvfcmpgt", int_ppc_qpx_qvfcmpgt>;
  def QVFCMPGTb : XForm_18<4, 32, (outs QBRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB),
                           "qvfcmpgt $FRT, $FRA, $FRB", FPCompare,
                           [(set QBRC:$FRT,
                                 (setcc QFRC:$FRA, QFRC:$FRB, SETOGT))]>;
  let isCodeGenOnly = 1 in
  def QVFCMPGTbs : XForm_18<4, 32, (outs QBRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB),
                            "qvfcmpgt $FRT, $FRA, $FRB", FPCompare,
                            [(set QBRC:$FRT,
                                  (setcc QSRC:$FRA, QSRC:$FRB, SETOGT))]>;
  let isCodeGenOnly = 1 in
    def QVFCMPEQ : QPXX18_Int<4, 0, "qvfcmpeq", int_ppc_qpx_qvfcmpeq>;
  def QVFCMPEQb : XForm_18<4, 0, (outs QBRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB),
                           "qvfcmpeq $FRT, $FRA, $FRB", FPCompare,
                           [(set QBRC:$FRT,
                                 (setcc QFRC:$FRA, QFRC:$FRB, SETOEQ))]>;
  let isCodeGenOnly = 1 in
  def QVFCMPEQbs : XForm_18<4, 0, (outs QBRC:$FRT), (ins QSRC:$FRA, QSRC:$FRB),
                            "qvfcmpeq $FRT, $FRA, $FRB", FPCompare,
                            [(set QBRC:$FRT,
                                  (setcc QSRC:$FRA, QSRC:$FRB, SETOEQ))]>;

  let isCodeGenOnly = 1 in
  def QVFLOGICAL : XForm_20<4, 4,
                      (outs QFRC:$FRT), (ins QFRC:$FRA, QFRC:$FRB, u12imm:$tttt),
                      "qvflogical $FRT, $FRA, $FRB, $tttt", FPCompare, []>;
  def QVFLOGICALb : XForm_20<4, 4,
                      (outs QBRC:$FRT), (ins QBRC:$FRA, QBRC:$FRB, u12imm:$tttt),
                      "qvflogical $FRT, $FRA, $FRB, $tttt", FPCompare, []>;
  let isCodeGenOnly = 1 in
  def QVFLOGICALs : XForm_20<4, 4,
                      (outs QBRC:$FRT), (ins QBRC:$FRA, QBRC:$FRB, u12imm:$tttt),
                      "qvflogical $FRT, $FRA, $FRB, $tttt", FPCompare, []>;

  // Load indexed instructions
  let mayLoad = 1, canFoldAsLoad = 1 in {
    def QVLFDX : XForm_1<31, 583,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfdx $FRT, $src", LdStLoad,
                        [(set QFRC:$FRT, (load xoaddr:$src))]>;
    def QVLFDXb : XForm_1<31, 583,
                        (outs QBRC:$FRT), (ins memrr:$src),
                        "qvlfdx $FRT, $src", LdStLoad, []>;

    let RC = 1 in
    def QVLFDXA : XForm_1<31, 583,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfdxa $FRT, $src", LdStLoad, []>;

    def QVLFDUX : XForm_1<31, 494,
                        (outs QFRC:$FRT, ptr_rc_nor0:$ea_result),
                        (ins memrr:$src),
                        "qvlfdux $FRT, $src", LdStLoad, []>,
                        RegConstraint<"$src.ptrreg = $ea_result">,
                        NoEncode<"$ea_result">;
    let RC = 1 in
    def QVLFDUXA : XForm_1<31, 494,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfduxa $FRT, $src", LdStLoad, []>;

    def QVLFSX : XForm_1<31, 519,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfsx $FRT, $src", LdStLoad,
                        [(set QFRC:$FRT, (extloadv4f32 xoaddr:$src))]>;

    let isCodeGenOnly = 1 in
    def QVLFSXb : XForm_1<31, 519,
                        (outs QBRC:$FRT), (ins memrr:$src),
                        "qvlfsx $FRT, $src", LdStLoad,
                        [(set QBRC:$FRT, (PPCqvlfsb xoaddr:$src))]>;
    let isCodeGenOnly = 1 in
    def QVLFSXs : XForm_1<31, 519,
                        (outs QSRC:$FRT), (ins memrr:$src),
                        "qvlfsx $FRT, $src", LdStLoad,
                        [(set QSRC:$FRT, (load xoaddr:$src))]>;

    let RC = 1 in
    def QVLFSXA : XForm_1<31, 519,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfsxa $FRT, $src", LdStLoad, []>;

    def QVLFSUX : XForm_1<31, 615,
                        (outs QSRC:$FRT, ptr_rc_nor0:$ea_result),
                        (ins memrr:$src),
                        "qvlfsux $FRT, $src", LdStLoad, []>,
                        RegConstraint<"$src.ptrreg = $ea_result">,
                        NoEncode<"$ea_result">;

    let RC = 1 in
    def QVLFSUXA : XForm_1<31, 615,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfsuxa $FRT, $src", LdStLoad, []>;

    def QVLFCDX : XForm_1<31, 71,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfcdx $FRT, $src", LdStLoad,
                        [(set QFRC:$FRT, (vector_shuffle_0_1_0_1 (load xoaddr:$src), undef))]>;
    let RC = 1 in
    def QVLFCDXA : XForm_1<31, 71,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfcdxa $FRT, $src", LdStLoad, []>;

    def QVLFCDUX : XForm_1<31, 103,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfcdux $FRT, $src", LdStLoad, []>;
    let RC = 1 in
    def QVLFCDUXA : XForm_1<31, 103,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfcduxa $FRT, $src", LdStLoad, []>;

    def QVLFCSX : XForm_1<31, 7,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfcsx $FRT, $src", LdStLoad,
                        [(set QFRC:$FRT, (vector_shuffle_0_1_0_1 (extloadv2f32 xoaddr:$src), undef))]>;
    let isCodeGenOnly = 1 in
    def QVLFCSXs : XForm_1<31, 7,
                         (outs QSRC:$FRT), (ins memrr:$src),
                         "qvlfcsx $FRT, $src", LdStLoad,
                         [(set QSRC:$FRT, (vector_shuffle_0_1_0_1 (load xoaddr:$src), undef))]>;

    let RC = 1 in
    def QVLFCSXA : XForm_1<31, 7,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfcsxa $FRT, $src", LdStLoad, []>;

    def QVLFCSUX : XForm_1<31, 39,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfcsux $FRT, $src", LdStLoad, []>;
    let RC = 1 in
    def QVLFCSUXA : XForm_1<31, 39,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfcsuxa $FRT, $src", LdStLoad, []>;

    def QVLFIWAX : XForm_1<31, 871,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfiwax $FRT, $src", LdStLoad, []>;
    let RC = 1 in
    def QVLFIWAXA : XForm_1<31, 871,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfiwaxa $FRT, $src", LdStLoad, []>;

    def QVLFIWZX : XForm_1<31, 839,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfiwzx $FRT, $src", LdStLoad, []>;
    let RC = 1 in
    def QVLFIWZXA : XForm_1<31, 839,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlfiwzxa $FRT, $src", LdStLoad, []>;

    def QVLPCLDX : XForm_1<31, 582,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlpcldx $FRT, $src", LdStLoad, []>;
    def QVLPCLSX : XForm_1<31, 518,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlpclsx $FRT, $src", LdStLoad, []>;
    let isCodeGenOnly = 1 in
      def QVLPCLSXint : XForm_11<31, 518,
                                (outs QFRC:$FRT), (ins G8RC:$src),
                                "qvlpclsx $FRT, 0, $src", LdStLoad, []>;
    def QVLPCRDX : XForm_1<31, 70,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlpcrdx $FRT, $src", LdStLoad, []>;
    def QVLPCRSX : XForm_1<31, 6,
                        (outs QFRC:$FRT), (ins memrr:$src),
                        "qvlpcrsx $FRT, $src", LdStLoad, []>;
  }

  // Store indexed instructions
  let mayStore = 1 in {
    def QVSTFDX : XForm_8<31, 711,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfdx $FRT, $dst", LdStStore,
                        [(store QFRC:$FRT, xoaddr:$dst)]>;
    def QVSTFDXb : XForm_8<31, 711,
                        (outs), (ins QBRC:$FRT, memrr:$dst),
                        "qvstfdx $FRT, $dst", LdStStore, []>;

    let RC = 1 in
    def QVSTFDXA : XForm_8<31, 711,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfdxa $FRT, $dst", LdStStore, []>;

    def QVSTFDUX : XForm_8<31, 743, (outs ptr_rc_nor0:$ea_res),
                           (ins QFRC:$FRT, memrr:$dst),
                           "qvstfdux $FRT, $dst", LdStStore, []>,
                           RegConstraint<"$dst.ptrreg = $ea_res">,
                           NoEncode<"$ea_res">;

    let RC = 1 in
    def QVSTFDUXA : XForm_8<31, 743,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfduxa $FRT, $dst", LdStStore, []>;

    def QVSTFDXI : XForm_8<31, 709,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfdxi $FRT, $dst", LdStStore, []>;
    let RC = 1 in
    def QVSTFDXIA : XForm_8<31, 709,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfdxia $FRT, $dst", LdStStore, []>;

    def QVSTFDUXI : XForm_8<31, 741,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfduxi $FRT, $dst", LdStStore, []>;
    let RC = 1 in
    def QVSTFDUXIA : XForm_8<31, 741,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfduxia $FRT, $dst", LdStStore, []>;

    def QVSTFSX : XForm_8<31, 647,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfsx $FRT, $dst", LdStStore,
                        [(truncstorev4f32 QFRC:$FRT, xoaddr:$dst)]>;
    let isCodeGenOnly = 1 in
    def QVSTFSXs : XForm_8<31, 647,
                         (outs), (ins QSRC:$FRT, memrr:$dst),
                         "qvstfsx $FRT, $dst", LdStStore,
                         [(store QSRC:$FRT, xoaddr:$dst)]>;

    let RC = 1 in
    def QVSTFSXA : XForm_8<31, 647,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfsxa $FRT, $dst", LdStStore, []>;

    def QVSTFSUX : XForm_8<31, 679, (outs ptr_rc_nor0:$ea_res),
                           (ins QSRC:$FRT, memrr:$dst),
                           "qvstfsux $FRT, $dst", LdStStore, []>,
                           RegConstraint<"$dst.ptrreg = $ea_res">,
                           NoEncode<"$ea_res">;

    let RC = 1 in
    def QVSTFSUXA : XForm_8<31, 679,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfsuxa $FRT, $dst", LdStStore, []>;

    def QVSTFSXI : XForm_8<31, 645,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfsxi $FRT, $dst", LdStStore, []>;
    let RC = 1 in
    def QVSTFSXIA : XForm_8<31, 645,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfsxia $FRT, $dst", LdStStore, []>;

    def QVSTFSUXI : XForm_8<31, 677,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfsuxi $FRT, $dst", LdStStore, []>;
    let RC = 1 in
    def QVSTFSUXIA : XForm_8<31, 677,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfsuxia $FRT, $dst", LdStStore, []>;

    def QVSTFCDX : XForm_8<31, 199,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcdx $FRT, $dst", LdStStore,
                        [(store (vector_shuffle_0_1 QFRC:$FRT, undef), xoaddr:$dst)]>;
    let RC = 1 in
    def QVSTFCDXA : XForm_8<31, 199,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcdxa $FRT, $dst", LdStStore, []>;

    def QVSTFCSX : XForm_8<31, 135,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcsx $FRT, $dst", LdStStore,
                        [(truncstorev2f32 (vector_shuffle_0_1 QFRC:$FRT, undef), xoaddr:$dst)]>;
    let isCodeGenOnly = 1 in
    def QVSTFCSXs : XForm_8<31, 135,
                         (outs), (ins QSRC:$FRT, memrr:$dst),
                         "qvstfcsx $FRT, $dst", LdStStore,
                         [(store (vector_shuffle_0_1 QSRC:$FRT, undef), xoaddr:$dst)]>;

    let RC = 1 in
    def QVSTFCSXA : XForm_8<31, 135,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcsxa $FRT, $dst", LdStStore, []>;

    def QVSTFCDUX : XForm_8<31, 231,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcdux $FRT, $dst", LdStStore, []>;
    let RC = 1 in
    def QVSTFCDUXA : XForm_8<31, 231,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcduxa $FRT, $dst", LdStStore, []>;

    def QVSTFCSUX : XForm_8<31, 167,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcsux $FRT, $dst", LdStStore, []>;
    let RC = 1 in
    def QVSTFCSUXA : XForm_8<31, 167,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcsuxa $FRT, $dst", LdStStore, []>;

    def QVSTFCDXI : XForm_8<31, 197,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcdxi $FRT, $dst", LdStStore, []>;
    let RC = 1 in
    def QVSTFCDXIA : XForm_8<31, 197,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcdxia $FRT, $dst", LdStStore, []>;

    def QVSTFCSXI : XForm_8<31, 133,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcsxi $FRT, $dst", LdStStore, []>;
    let RC = 1 in
    def QVSTFCSXIA : XForm_8<31, 133,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcsxia $FRT, $dst", LdStStore, []>;

    def QVSTFCDUXI : XForm_8<31, 229,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcduxi $FRT, $dst", LdStStore, []>;
    let RC = 1 in
    def QVSTFCDUXIA : XForm_8<31, 229,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcduxia $FRT, $dst", LdStStore, []>;

    def QVSTFCSUXI : XForm_8<31, 165,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcsuxi $FRT, $dst", LdStStore, []>;
    let RC = 1 in
    def QVSTFCSUXIA : XForm_8<31, 165,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfcsuxia $FRT, $dst", LdStStore, []>;

    def QVSTFIWX : XForm_8<31, 977,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfiwx $FRT, $dst", LdStStore, []>;
    let RC = 1 in
    def QVSTFIWXA : XForm_8<31, 977,
                        (outs), (ins QFRC:$FRT, memrr:$dst),
                        "qvstfiwxa $FRT, $dst", LdStStore, []>;
  }
}

} // neverHasSideEffects

//===----------------------------------------------------------------------===//
// Additional QPX Patterns
//

def : Pat<(v4f64 (scalar_to_vector F8RC:$A)),
          (INSERT_SUBREG (v4f64 (IMPLICIT_DEF)), F8RC:$A, sub_64)>;
def : Pat<(v4f32 (scalar_to_vector F4RC:$A)),
          (INSERT_SUBREG (v4f32 (IMPLICIT_DEF)), F4RC:$A, sub_64)>;

def : Pat<(f64 (vector_extract QFRC:$S, 0)),
          (EXTRACT_SUBREG QFRC:$S, sub_64)>;
def : Pat<(f32 (vector_extract QSRC:$S, 0)),
          (EXTRACT_SUBREG QSRC:$S, sub_64)>;

def : Pat<(f64 (vector_extract QFRC:$S, 1)),
          (EXTRACT_SUBREG (QVESPLATI QFRC:$S, 1), sub_64)>;
def : Pat<(f64 (vector_extract QFRC:$S, 2)),
          (EXTRACT_SUBREG (QVESPLATI QFRC:$S, 2), sub_64)>;
def : Pat<(f64 (vector_extract QFRC:$S, 3)),
          (EXTRACT_SUBREG (QVESPLATI QFRC:$S, 3), sub_64)>;

def : Pat<(f32 (vector_extract QSRC:$S, 1)),
          (EXTRACT_SUBREG (QVESPLATIs QSRC:$S, 1), sub_64)>;
def : Pat<(f32 (vector_extract QSRC:$S, 2)),
          (EXTRACT_SUBREG (QVESPLATIs QSRC:$S, 2), sub_64)>;
def : Pat<(f32 (vector_extract QSRC:$S, 3)),
          (EXTRACT_SUBREG (QVESPLATIs QSRC:$S, 3), sub_64)>;

def : Pat<(f64 (vector_extract QFRC:$S, G8RC:$F)),
          (EXTRACT_SUBREG (QVFPERM QFRC:$S, QFRC:$S,
                                   (QVLPCLSXint (RLDICR G8RC:$F, 5,
                                                        /* 63-5 = */ 58))),
                          sub_64)>;
def : Pat<(f32 (vector_extract QSRC:$S, G8RC:$F)),
          (EXTRACT_SUBREG (QVFPERMs QSRC:$S, QSRC:$S,
                                    (QVLPCLSXint (RLDICR G8RC:$F, 5,
                                                         /* 63-5 = */ 58))),
                          sub_64)>;

def : Pat<(int_ppc_qpx_qvfperm QFRC:$A, QFRC:$B, QFRC:$C),
          (QVFPERM QFRC:$A, QFRC:$B, QFRC:$C)>;

def : Pat<(int_ppc_qpx_qvfcpsgn QFRC:$A, QFRC:$B),
          (QVFCPSGN QFRC:$A, QFRC:$B)>;

def : Pat<(int_ppc_qpx_qvfneg QFRC:$A), (QVFNEG QFRC:$A)>;
def : Pat<(int_ppc_qpx_qvfabs QFRC:$A), (QVFABS QFRC:$A)>;
def : Pat<(int_ppc_qpx_qvfnabs QFRC:$A), (QVFNABS QFRC:$A)>;

def : Pat<(int_ppc_qpx_qvfriz QFRC:$A), (QVFRIZ QFRC:$A)>;
def : Pat<(int_ppc_qpx_qvfrin QFRC:$A), (QVFRIN QFRC:$A)>;
def : Pat<(int_ppc_qpx_qvfrip QFRC:$A), (QVFRIP QFRC:$A)>;
def : Pat<(int_ppc_qpx_qvfrim QFRC:$A), (QVFRIM QFRC:$A)>;

def : Pat<(int_ppc_qpx_qvfre QFRC:$A), (QVFRE QFRC:$A)>;
def : Pat<(int_ppc_qpx_qvfrsqrte QFRC:$A), (QVFRSQRTE QFRC:$A)>;

def : Pat<(int_ppc_qpx_qvfadd QFRC:$A, QFRC:$B),
          (QVFADD QFRC:$A, QFRC:$B)>;
def : Pat<(int_ppc_qpx_qvfsub QFRC:$A, QFRC:$B),
          (QVFSUB QFRC:$A, QFRC:$B)>;
def : Pat<(int_ppc_qpx_qvfmul QFRC:$A, QFRC:$B),
          (QVFMUL QFRC:$A, QFRC:$B)>;

// Additional QVFNMSUB patterns: -a*c + b == -(a*c - b)
def : Pat<(fma (fneg v4f64:$A), v4f64:$C, v4f64:$B),
          (QVFNMSUB $A, $B, $C)>;
def : Pat<(fma v4f64:$A, (fneg v4f64:$C), v4f64:$B),
          (QVFNMSUB $A, $B, $C)>;
def : Pat<(fma (fneg v4f32:$A), v4f32:$C, v4f32:$B),
          (QVFNMSUBSs $A, $B, $C)>;
def : Pat<(fma v4f32:$A, (fneg v4f32:$C), v4f32:$B),
          (QVFNMSUBSs $A, $B, $C)>;

def : Pat<(int_ppc_qpx_qvfmadd QFRC:$A, QFRC:$B, QFRC:$C),
          (QVFMADD QFRC:$A, QFRC:$B, QFRC:$C)>;
def : Pat<(int_ppc_qpx_qvfnmadd QFRC:$A, QFRC:$B, QFRC:$C),
          (QVFNMADD QFRC:$A, QFRC:$B, QFRC:$C)>;
def : Pat<(int_ppc_qpx_qvfmsub QFRC:$A, QFRC:$B, QFRC:$C),
          (QVFMSUB QFRC:$A, QFRC:$B, QFRC:$C)>;
def : Pat<(int_ppc_qpx_qvfnmsub QFRC:$A, QFRC:$B, QFRC:$C),
          (QVFNMSUB QFRC:$A, QFRC:$B, QFRC:$C)>;

def : Pat<(int_ppc_qpx_qvlfd xoaddr:$src),
          (QVLFDX xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfda xoaddr:$src),
          (QVLFDXA xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfs xoaddr:$src),
          (QVLFSX xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfsa xoaddr:$src),
          (QVLFSXA xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfcda xoaddr:$src),
          (QVLFCDXA xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfcd xoaddr:$src),
          (QVLFCDX xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfcsa xoaddr:$src),
          (QVLFCSXA xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfcs xoaddr:$src),
          (QVLFCSX xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfda xoaddr:$src),
          (QVLFDXA xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfiwaa xoaddr:$src),
          (QVLFIWAXA xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfiwa xoaddr:$src),
          (QVLFIWAX xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfiwza xoaddr:$src),
          (QVLFIWZXA xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfiwz xoaddr:$src),
          (QVLFIWZX xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlfsa xoaddr:$src),
          (QVLFSXA xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlpcld xoaddr:$src),
          (QVLPCLDX xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlpcls xoaddr:$src),
          (QVLPCLSX xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlpcrd xoaddr:$src),
          (QVLPCRDX xoaddr:$src)>;
def : Pat<(int_ppc_qpx_qvlpcrs xoaddr:$src),
          (QVLPCRSX xoaddr:$src)>;

def : Pat<(int_ppc_qpx_qvstfd QFRC:$T, xoaddr:$dst),
          (QVSTFDX QFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_qpx_qvstfs QFRC:$T, xoaddr:$dst),
          (QVSTFSX QFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_qpx_qvstfcda QFRC:$T, xoaddr:$dst),
          (QVSTFCDXA QFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_qpx_qvstfcd QFRC:$T, xoaddr:$dst),
          (QVSTFCDX QFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_qpx_qvstfcsa QFRC:$T, xoaddr:$dst),
          (QVSTFCSXA QFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_qpx_qvstfcs QFRC:$T, xoaddr:$dst),
          (QVSTFCSX QFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_qpx_qvstfda QFRC:$T, xoaddr:$dst),
          (QVSTFDXA QFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_qpx_qvstfiwa QFRC:$T, xoaddr:$dst),
          (QVSTFIWXA QFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_qpx_qvstfiw QFRC:$T, xoaddr:$dst),
          (QVSTFIWX QFRC:$T, xoaddr:$dst)>;
def : Pat<(int_ppc_qpx_qvstfsa QFRC:$T, xoaddr:$dst),
          (QVSTFSXA QFRC:$T, xoaddr:$dst)>;

def : Pat<(pre_store v4f64:$rS, iPTR:$ptrreg, iPTR:$ptroff),
          (QVSTFDUX $rS, $ptrreg, $ptroff)>;
def : Pat<(pre_store v4f32:$rS, iPTR:$ptrreg, iPTR:$ptroff),
          (QVSTFSUX $rS, $ptrreg, $ptroff)>;

def : Pat<(int_ppc_qpx_qvflogical  QFRC:$A, QFRC:$B, (i32 imm:$idx)),
          (QVFLOGICAL QFRC:$A, QFRC:$B, imm:$idx)>;
def : Pat<(int_ppc_qpx_qvgpci (i32 imm:$idx)),
          (QVGPCI imm:$idx)>;

def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETOGE),
          (QVFLOGICALb (QVFCMPLTb QFRC:$FRA, QFRC:$FRB),
                       (QVFTSTNANb QFRC:$FRA, QFRC:$FRB), (i32 8))>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETOLE),
          (QVFLOGICALb (QVFCMPGTb QFRC:$FRA, QFRC:$FRB),
                       (QVFTSTNANb QFRC:$FRA, QFRC:$FRB), (i32 8))>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETONE),
          (QVFLOGICALb (QVFCMPEQb QFRC:$FRA, QFRC:$FRB),
                       (QVFTSTNANb QFRC:$FRA, QFRC:$FRB), (i32 8))>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETO),
          (QVFLOGICALb (QVFTSTNANb QFRC:$FRA, QFRC:$FRB),
                       (QVFTSTNANb QFRC:$FRA, QFRC:$FRB), (i32 10))>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETUEQ),
          (QVFLOGICALb (QVFCMPEQb QFRC:$FRA, QFRC:$FRB),
                       (QVFTSTNANb QFRC:$FRA, QFRC:$FRB), (i32 7))>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETUGT),
          (QVFLOGICALb (QVFCMPGTb QFRC:$FRA, QFRC:$FRB),
                       (QVFTSTNANb QFRC:$FRA, QFRC:$FRB), (i32 7))>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETUGE),
          (QVFLOGICALb (QVFTSTNANb QFRC:$FRA, QFRC:$FRB),
                       (QVFCMPLTb QFRC:$FRA, QFRC:$FRB), (i32 13))>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETULT),
          (QVFLOGICALb (QVFCMPLTb QFRC:$FRA, QFRC:$FRB),
                       (QVFTSTNANb QFRC:$FRA, QFRC:$FRB), (i32 7))>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETULE),
          (QVFLOGICALb (QVFTSTNANb QFRC:$FRA, QFRC:$FRB),
                       (QVFCMPGTb QFRC:$FRA, QFRC:$FRB), (i32 13))>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETUNE),
          (QVFLOGICALb (QVFTSTNANb QFRC:$FRA, QFRC:$FRB),
                       (QVFCMPEQb QFRC:$FRA, QFRC:$FRB), (i32 13))>;

def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETEQ),
          (QVFCMPEQb QFRC:$FRA, QFRC:$FRB)>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETGT),
          (QVFCMPGTb QFRC:$FRA, QFRC:$FRB)>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETGE),
          (QVFLOGICALb (QVFCMPLTb QFRC:$FRA, QFRC:$FRB),
                       (QVFCMPLTb QFRC:$FRA, QFRC:$FRB), (i32 10))>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETLT),
          (QVFCMPLTb QFRC:$FRA, QFRC:$FRB)>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETLE),
          (QVFLOGICALb (QVFCMPGTb QFRC:$FRA, QFRC:$FRB),
                       (QVFCMPGTb QFRC:$FRA, QFRC:$FRB), (i32 10))>;
def : Pat<(setcc QFRC:$FRA, QFRC:$FRB, SETNE),
          (QVFLOGICALb (QVFCMPEQb QFRC:$FRA, QFRC:$FRB),
                       (QVFCMPEQb QFRC:$FRA, QFRC:$FRB), (i32 10))>;

def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETOGE),
          (QVFLOGICALb (QVFCMPLTbs QSRC:$FRA, QSRC:$FRB),
                       (QVFTSTNANbs QSRC:$FRA, QSRC:$FRB), (i32 8))>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETOLE),
          (QVFLOGICALb (QVFCMPGTbs QSRC:$FRA, QSRC:$FRB),
                       (QVFTSTNANbs QSRC:$FRA, QSRC:$FRB), (i32 8))>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETONE),
          (QVFLOGICALb (QVFCMPEQbs QSRC:$FRA, QSRC:$FRB),
                       (QVFTSTNANbs QSRC:$FRA, QSRC:$FRB), (i32 8))>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETO),
          (QVFLOGICALb (QVFTSTNANbs QSRC:$FRA, QSRC:$FRB),
                       (QVFTSTNANbs QSRC:$FRA, QSRC:$FRB), (i32 10))>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETUEQ),
          (QVFLOGICALb (QVFCMPEQbs QSRC:$FRA, QSRC:$FRB),
                       (QVFTSTNANbs QSRC:$FRA, QSRC:$FRB), (i32 7))>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETUGT),
          (QVFLOGICALb (QVFCMPGTbs QSRC:$FRA, QSRC:$FRB),
                       (QVFTSTNANbs QSRC:$FRA, QSRC:$FRB), (i32 7))>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETUGE),
          (QVFLOGICALb (QVFTSTNANbs QSRC:$FRA, QSRC:$FRB),
                       (QVFCMPLTbs QSRC:$FRA, QSRC:$FRB), (i32 13))>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETULT),
          (QVFLOGICALb (QVFCMPLTbs QSRC:$FRA, QSRC:$FRB),
                       (QVFTSTNANbs QSRC:$FRA, QSRC:$FRB), (i32 7))>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETULE),
          (QVFLOGICALb (QVFTSTNANbs QSRC:$FRA, QSRC:$FRB),
                       (QVFCMPGTbs QSRC:$FRA, QSRC:$FRB), (i32 13))>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETUNE),
          (QVFLOGICALb (QVFTSTNANbs QSRC:$FRA, QSRC:$FRB),
                       (QVFCMPEQbs QSRC:$FRA, QSRC:$FRB), (i32 13))>;

def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETEQ),
          (QVFCMPEQbs QSRC:$FRA, QSRC:$FRB)>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETGT),
          (QVFCMPGTbs QSRC:$FRA, QSRC:$FRB)>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETGE),
          (QVFLOGICALb (QVFCMPLTbs QSRC:$FRA, QSRC:$FRB),
                       (QVFCMPLTbs QSRC:$FRA, QSRC:$FRB), (i32 10))>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETLT),
          (QVFCMPLTbs QSRC:$FRA, QSRC:$FRB)>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETLE),
          (QVFLOGICALb (QVFCMPGTbs QSRC:$FRA, QSRC:$FRB),
                       (QVFCMPGTbs QSRC:$FRA, QSRC:$FRB), (i32 10))>;
def : Pat<(setcc QSRC:$FRA, QSRC:$FRB, SETNE),
          (QVFLOGICALb (QVFCMPEQbs QSRC:$FRA, QSRC:$FRB),
                       (QVFCMPEQbs QSRC:$FRA, QSRC:$FRB), (i32 10))>;

def : Pat<(and QBRC:$FRA, (not QBRC:$FRB)),
          (QVFLOGICALb QBRC:$FRA, QBRC:$FRB, (i32 4))>;
def : Pat<(not (or QBRC:$FRA, QBRC:$FRB)),
          (QVFLOGICALb QBRC:$FRA, QBRC:$FRB, (i32 8))>;
def : Pat<(not (xor QBRC:$FRA, QBRC:$FRB)),
          (QVFLOGICALb QBRC:$FRA, QBRC:$FRB, (i32 9))>;
def : Pat<(or QBRC:$FRA, (not QBRC:$FRB)),
          (QVFLOGICALb QBRC:$FRA, QBRC:$FRB, (i32 13))>;
def : Pat<(not (and QBRC:$FRA, QBRC:$FRB)),
          (QVFLOGICALb QBRC:$FRA, QBRC:$FRB, (i32 14))>;

def : Pat<(and QBRC:$FRA, QBRC:$FRB),
          (QVFLOGICALb QBRC:$FRA, QBRC:$FRB, (i32 1))>;
def : Pat<(or QBRC:$FRA, QBRC:$FRB),
          (QVFLOGICALb QBRC:$FRA, QBRC:$FRB, (i32 7))>;
def : Pat<(xor QBRC:$FRA, QBRC:$FRB),
          (QVFLOGICALb QBRC:$FRA, QBRC:$FRB, (i32 6))>;
def : Pat<(not QBRC:$FRA),
          (QVFLOGICALb QBRC:$FRA, QBRC:$FRA, (i32 10))>;

def : Pat<(v4f64 (fextend QSRC:$src)),
          (COPY_TO_REGCLASS QSRC:$src, QFRC)>;

// Extract the underlying floating-point values from the
// QPX (-1.0, 1.0) boolean representation.
def : Pat<(v4f64 (PPCqbflt QBRC:$src)),
          (COPY_TO_REGCLASS QBRC:$src, QFRC)>;

} // end HasQPX

