//===-- RXFrameLowering.cpp - RX Frame Information ------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the RX implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "RXFrameLowering.h"
#include "RXMachineFunctionInfo.h"
#include "RXSubtarget.h"
#include "MCTargetDesc/RXMCTargetDesc.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/MC/MCDwarf.h"
#include "llvm/Support/Debug.h"

#define DEBUG_TYPE "rx-framelowering"

using namespace llvm;

// NOTE llvm/include/llvm/CodeGen/TargetFrameLowering.h hasFP
// 専用のフレームポインタレジスタを持つべき関数の場合、真を返す
// 可変サイズの"alloca"が含まれる場合などで真になる
bool RXFrameLowering::hasFP(const MachineFunction &MF) const {
  return false;
}

// DestReg = SrcReg + Val を生成する
void RXFrameLowering::adjustReg(MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator MBBI,
                                const DebugLoc &DL, Register DestReg,
                                Register SrcReg, int64_t Val,
                                MachineInstr::MIFlag Flag) const {
  MachineRegisterInfo &MRI = MBB.getParent()->getRegInfo();
  const RXInstrInfo *TII = STI.getInstrInfo();

  if (DestReg == SrcReg && Val == 0)
    return;

  // NOTE ここでレジスタを新しく用意して使う
  // 本来ADD_I32RRでいいが、レジスタ確保をする例としてADD_RRRを使う
  Register ScratchReg = MRI.createVirtualRegister(&RX::GPRRegClass);
  BuildMI(MBB, MBBI, DL, TII->get(RX::MOV_I32R), ScratchReg)
    .addImm(Val)
    .setMIFlag(Flag);
  BuildMI(MBB, MBBI, DL, TII->get(RX::ADD_RRR), DestReg)
    .addReg(SrcReg)
    .addReg(ScratchReg, RegState::Kill)
    .setMIFlag(Flag);
}

void RXFrameLowering::emitPrologue(MachineFunction &MF,
                                   MachineBasicBlock &MBB) const {
  assert(&MF.front() == &MBB && "Shrink-wrapping not yet supported");

  MachineFrameInfo &MFI = MF.getFrameInfo();
  const RXInstrInfo *TII = STI.getInstrInfo();
  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc DL;

  uint64_t StackSize = MFI.getStackSize();

  // Early exit if there is no need to allocate on the stack
  if (StackSize == 0)
    return;

  // Update stack size
  MFI.setStackSize(StackSize);

  // スタックを1フレーム分伸ばす
  const Register frameReg = RX::R0;
  BuildMI(MBB, MBBI, DL, TII->get(RX::ADD_I32RR), frameReg)
      .addReg(frameReg)
      .addImm(-StackSize)
      .setMIFlag(MachineInstr::FrameSetup);
}

void RXFrameLowering::emitEpilogue(MachineFunction &MF,
                                   MachineBasicBlock &MBB) const {
  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  DebugLoc DL = MBBI->getDebugLoc();
  const RXInstrInfo *TII = STI.getInstrInfo();

  LLVM_DEBUG(dbgs() << "### emitEpilogue " << MFI.getCalleeSavedInfo().size() << "\n");

  // Get the number of bytes from FrameInfo
  uint64_t StackSize = MFI.getStackSize();

  // Early exit if there is no need to restore the frame pointer.
  if (StackSize == 0)
    return;

  // スタックを1フレーム分戻す
  const Register frameReg = RX::R0;
  BuildMI(MBB, MBBI, DL, TII->get(RX::ADD_I32RR), frameReg)
      .addReg(frameReg)
      .addImm(StackSize)
      .setMIFlag(MachineInstr::FrameDestroy);
}

// Eliminate ADJCALLSTACKDOWN, ADJCALLSTACKUP pseudo instructions.
MachineBasicBlock::iterator RXFrameLowering::eliminateCallFramePseudoInstr(
    MachineFunction &MF, MachineBasicBlock &MBB,
    MachineBasicBlock::iterator MI) const {
  // NOTE ほぼRISCV
  Register SPReg = RX::R0;
  DebugLoc DL = MI->getDebugLoc();

  if (!hasReservedCallFrame(MF)) {
    // If space has not been reserved for a call frame, ADJCALLSTACKDOWN and
    // ADJCALLSTACKUP must be converted to instructions manipulating the stack
    // pointer. This is necessary when there is a variable length stack
    // allocation (e.g. alloca), which means it's not possible to allocate
    // space for outgoing arguments from within the function prologue.
    int64_t Amount = MI->getOperand(0).getImm();

    if (Amount != 0) {
      // Ensure the stack remains aligned after adjustment.
      Amount = alignSPAdjust(Amount);

      if (MI->getOpcode() == RX::ADJCALLSTACKDOWN)
        Amount = -Amount;

      adjustReg(MBB, MI, DL, SPReg, SPReg, Amount, MachineInstr::NoFlags);
    }
  }

  return MBB.erase(MI);
}
