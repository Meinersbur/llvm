//===-- MipsMachineFunctionInfo.cpp - Private data used for Mips ----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MipsMachineFunction.h"
#include "MCTargetDesc/MipsBaseInfo.h"
#include "MipsInstrInfo.h"
#include "MipsSubtarget.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

static cl::opt<bool>
FixGlobalBaseReg("mips-fix-global-base-reg", cl::Hidden, cl::init(true),
                 cl::desc("Always use $gp as the global base register."));

// class MipsCallEntry.
MipsCallEntry::MipsCallEntry(const StringRef &N) {
#ifndef NDEBUG
  Name = N;
  Val = 0;
#endif
}

MipsCallEntry::MipsCallEntry(const GlobalValue *V) {
#ifndef NDEBUG
  Val = V;
#endif
}

bool MipsCallEntry::isConstant(const MachineFrameInfo *) const {
  return false;
}

bool MipsCallEntry::isAliased(const MachineFrameInfo *) const {
  return false;
}

bool MipsCallEntry::mayAlias(const MachineFrameInfo *) const {
  return false;
}

void MipsCallEntry::printCustom(raw_ostream &O) const {
  O << "MipsCallEntry: ";
#ifndef NDEBUG
  if (Val)
    O << Val->getName();
  else
    O << Name;
#endif
}

MipsFunctionInfo::~MipsFunctionInfo() {
  for (StringMap<const MipsCallEntry *>::iterator
       I = ExternalCallEntries.begin(), E = ExternalCallEntries.end(); I != E;
       ++I)
    delete I->getValue();

  for (ValueMap<const GlobalValue *, const MipsCallEntry *>::iterator
       I = GlobalCallEntries.begin(), E = GlobalCallEntries.end(); I != E; ++I)
    delete I->second;
}

bool MipsFunctionInfo::globalBaseRegSet() const {
  return GlobalBaseReg;
}

unsigned MipsFunctionInfo::getGlobalBaseReg() {
  // Return if it has already been initialized.
  if (GlobalBaseReg)
    return GlobalBaseReg;

  const MipsSubtarget &ST = MF.getTarget().getSubtarget<MipsSubtarget>();

  const TargetRegisterClass *RC;
  if (ST.inMips16Mode())
    RC=(const TargetRegisterClass*)&Mips::CPU16RegsRegClass;
  else
    RC = ST.isABI_N64() ?
      (const TargetRegisterClass*)&Mips::GPR64RegClass :
      (const TargetRegisterClass*)&Mips::GPR32RegClass;
  return GlobalBaseReg = MF.getRegInfo().createVirtualRegister(RC);
}

bool MipsFunctionInfo::mips16SPAliasRegSet() const {
  return Mips16SPAliasReg;
}
unsigned MipsFunctionInfo::getMips16SPAliasReg() {
  // Return if it has already been initialized.
  if (Mips16SPAliasReg)
    return Mips16SPAliasReg;

  const TargetRegisterClass *RC;
  RC=(const TargetRegisterClass*)&Mips::CPU16RegsRegClass;
  return Mips16SPAliasReg = MF.getRegInfo().createVirtualRegister(RC);
}

void MipsFunctionInfo::createEhDataRegsFI() {
  for (int I = 0; I < 4; ++I) {
    const MipsSubtarget &ST = MF.getTarget().getSubtarget<MipsSubtarget>();
    const TargetRegisterClass *RC = ST.isABI_N64() ?
        &Mips::GPR64RegClass : &Mips::GPR32RegClass;

    EhDataRegFI[I] = MF.getFrameInfo()->CreateStackObject(RC->getSize(),
        RC->getAlignment(), false);
  }
}

bool MipsFunctionInfo::isEhDataRegFI(int FI) const {
  return CallsEhReturn && (FI == EhDataRegFI[0] || FI == EhDataRegFI[1]
                        || FI == EhDataRegFI[2] || FI == EhDataRegFI[3]);
}

MachinePointerInfo MipsFunctionInfo::callPtrInfo(const StringRef &Name) {
  StringMap<const MipsCallEntry *>::const_iterator I;
  I = ExternalCallEntries.find(Name);

  if (I != ExternalCallEntries.end())
    return MachinePointerInfo(I->getValue());

  const MipsCallEntry *E = ExternalCallEntries[Name] = new MipsCallEntry(Name);
  return MachinePointerInfo(E);
}

MachinePointerInfo MipsFunctionInfo::callPtrInfo(const GlobalValue *Val) {
  ValueMap<const GlobalValue *, const MipsCallEntry *>::const_iterator I;
  I = GlobalCallEntries.find(Val);

  if (I != GlobalCallEntries.end())
    return MachinePointerInfo(I->second);

  const MipsCallEntry *E = GlobalCallEntries[Val] = new MipsCallEntry(Val);
  return MachinePointerInfo(E);
}

void MipsFunctionInfo::anchor() { }
