//===-- RXInstrInfo.cpp - RX Instruction Information -----------*- C++ -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the RX implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "RXInstrInfo.h"
#include "RX.h"
#include "RXSubtarget.h"
#include "RXTargetMachine.h"
#include "MCTargetDesc/RXMCTargetDesc.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

#define DEBUG_TYPE "rx-instrinfo"

#define GET_INSTRINFO_CTOR_DTOR
#include "RXGenInstrInfo.inc"

using namespace llvm;

RXInstrInfo::RXInstrInfo()
    : RXGenInstrInfo(RX::ADJCALLSTACKDOWN, RX::ADJCALLSTACKUP) {}

unsigned RXInstrInfo::isLoadFromStackSlot(const MachineInstr &MI,
                                          int &FrameIndex) const {

  LLVM_DEBUG(dbgs() << "### isLoadFromStackSlot " << MI << "\n");

  switch (MI.getOpcode()) {
  default:
    return 0;
  // TODO ロード命令の場合break
  }

  if (MI.getOperand(1).isFI() && MI.getOperand(2).isImm() &&
      MI.getOperand(2).getImm() == 0) {
    FrameIndex = MI.getOperand(1).getIndex();
    return MI.getOperand(0).getReg();
  }

  return 0;
}

unsigned RXInstrInfo::isStoreToStackSlot(const MachineInstr &MI,
                                         int &FrameIndex) const {

  LLVM_DEBUG(dbgs() << "### isStoreToStackSlot " << MI << "\n");

  switch (MI.getOpcode()) {
  default:
    return 0;
  // TODO ストア命令の場合break
  }

  if (MI.getOperand(0).isFI() && MI.getOperand(1).isImm() &&
      MI.getOperand(1).getImm() == 0) {
    FrameIndex = MI.getOperand(0).getIndex();
    return MI.getOperand(2).getReg();
  }

  return 0;
}

void RXInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator MBBI,
                              const DebugLoc &DL, MCRegister DstReg,
                              MCRegister SrcReg, bool KillSrc) const {
  // SrcRegの値をDstRegにコピーする命令を生成する
  BuildMI(MBB, MBBI, DL, get(RX::MOVL_RR))
      .addReg(DstReg, RegState::Define)
      .addReg(SrcReg, getKillRegState(KillSrc));
}

void RXInstrInfo::storeRegToStackSlot(MachineBasicBlock &MBB,
                                      MachineBasicBlock::iterator I,
                                      unsigned SrcReg, bool IsKill, int FI,
                                      const TargetRegisterClass *RC,
                                      const TargetRegisterInfo *TRI) const {
  // スタックへレジスタの値を保存する命令を生成する

  DebugLoc DL;
  if (I != MBB.end())
    DL = I->getDebugLoc();

  // displacement mov命令でSrcRegの値を保存
  // ただし、RXのdisplacementは18bitの制限有
  BuildMI(MBB, I, DL, get(RX::MOVL_RD16))
      .addReg(SrcReg, getKillRegState(IsKill))
      .addFrameIndex(FI)
      .addImm(0);
}

void RXInstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
                                       MachineBasicBlock::iterator I,
                                       unsigned DstReg, int FI,
                                       const TargetRegisterClass *RC,
                                       const TargetRegisterInfo *TRI) const {
  // スタックからレジスタの値を取得する命令を生成する

  DebugLoc DL;
  if (I != MBB.end())
    DL = I->getDebugLoc();

  // displacement mov命令で値をDstRegに保存
  // ただし、RXのdisplacementは18bitの制限有
  BuildMI(MBB, I, DL, get(RX::MOVL_D16R))
      .addReg(DstReg)
      .addFrameIndex(FI)
      .addImm(0);
}

// NOTE llvm/include/llvm/CodeGen/TargetInstrInfo.h
bool RXInstrInfo::analyzeBranch(MachineBasicBlock &MBB,
                                MachineBasicBlock *&TBB,
                                MachineBasicBlock *&FBB,
                                SmallVectorImpl<MachineOperand> &Cond,
                                bool AllowModify) const {
  LLVM_DEBUG(dbgs() << "### analyzeBranch " << MBB << "\n");
  // 分岐関係で独自の処理を追加する場合はここに記述する
  // removeBranch insertBranch はこの関数が成功したとき(falseを返したとき?)に呼び出される
  // 未実装の場合はtrueを返す
  return true;
}

MachineBasicBlock *
RXInstrInfo::getBranchDestBlock(const MachineInstr &MI) const {
  LLVM_DEBUG(dbgs() << "### getBranchDestBlock " << MI << "\n");
  // TODO brを使ったコードをコンパイルしても呼び出されない
  assert(MI.getDesc().isBranch() && "Unexpected opcode!");

  // TODO 分岐先を返す
  return nullptr;
}

bool RXInstrInfo::isBranchOffsetInRange(unsigned BranchOp,
                                           int64_t BrOffset) const {
  LLVM_DEBUG(dbgs() << "### isBranchOffsetInRange " << BranchOp << "\n");
  // TODO brを使ったコードをコンパイルしても呼び出されない
  // TODO ジャンプ可能な範囲内なら真を返す
  return isIntN(32, BrOffset);  // BrOffsetを符号付き32bitで表現できる場合、真
}

// Pseudo生成後の処理
bool RXInstrInfo::expandPostRAPseudo(MachineInstr &MI) const {
  LLVM_DEBUG(dbgs() << "### expandPostRAPseudo " << MI << "\n");

  // TODO Pseudo生成後の処理

  // 何もしていない場合、偽を返す
  return false;
}

// 命令のバイト数を返す
unsigned RXInstrInfo::getInstSizeInBytes(const MachineInstr &MI) const {
  unsigned Opcode = MI.getOpcode();

  switch (Opcode) {
  default:
    return 0;
  case RX::NOP:
  case RX::RTS:
    return 1;
  case RX::MOVL_RR:
  case RX::MOVL_RpR:
  case RX::PUSHL_R:
  case RX::POP:
    return 2;
  case RX::ADD_RRR:
  case RX::MOVL_dRR:
  case RX::MOVL_RiR:
    return 3;
  case RX::MOVL_RD16:
  case RX::MOVL_D16R:
    return 4;
  case RX::ADD_I32R:
    return 6;
  }
}
