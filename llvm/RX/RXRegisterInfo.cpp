//===-- RXRegisterInfo.cpp - RX Register Information -----------*- C++ -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the RX implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#include "RXRegisterInfo.h"
#include "RX.h"
#include "RXSubtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/CodeGen/TargetFrameLowering.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"

#define DEBUG_TYPE "rx-registerinfo"

#define GET_REGINFO_ENUM
#define GET_REGINFO_TARGET_DESC
#include "RXGenRegisterInfo.inc"

using namespace llvm;

// 各役割の汎用レジスタを指定する?
// RXでは該当する汎用レジスタはないため全て0(NoRegister)とした
RXRegisterInfo::RXRegisterInfo(unsigned HwMode)
    : RXGenRegisterInfo(/*ReturnAddres*/0, /*DwarfFlavour*/0,
                        /*EHFlavor*/0, /*PC*/0, HwMode) {}

const MCPhysReg *
RXRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  return CSR_SaveList;
}

BitVector RXRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());

  // NOTE 一時的な値保存用に使ってはいけないレジスタを設定する
  markSuperRegs(Reserved, RX::R0); // stack pointer
  assert(checkAllSuperRegsMarked(Reserved));
  return Reserved;
}

// フレームインデックスをレジスタにセットする
void RXRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                         int SPAdj, unsigned FIOperandNum,
                                         RegScavenger *RS) const {
  LLVM_DEBUG(dbgs() << "### eliminateFrameIndex\n");

  assert(SPAdj == 0 && "Unexpected non-zero SPAdj value");

  MachineInstr &MI = *II;
  MachineFunction &MF = *MI.getParent()->getParent();
  DebugLoc DL = MI.getDebugLoc();

  int FrameIndex = MI.getOperand(FIOperandNum).getIndex();
  Register FrameReg;
  int Offset =
      getFrameLowering(MF)->getFrameIndexReference(MF, FrameIndex, FrameReg) +
      MI.getOperand(FIOperandNum + 1).getImm();

  if (!isInt<32>(Offset)) {
    report_fatal_error(
        "Frame offsets outside of the signed 32-bit range not supported");
  }

  MI.getOperand(FIOperandNum)
      .ChangeToRegister(FrameReg, false);
  MI.getOperand(FIOperandNum + 1).ChangeToImmediate(Offset);
}

Register RXRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  // NOTE フレームレジスタ (スタックポインタ)を返す
  return RX::R0;
}

const uint32_t *
RXRegisterInfo::getCallPreservedMask(const MachineFunction & MF,
                                     CallingConv::ID /*CC*/) const {
  return CSR_RegMask;
}
