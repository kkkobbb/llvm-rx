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

// 分岐命令の分析 (分岐関係の最適化ができる部分を探すため)
// 成功した(分岐命令を認識できた)場合、falseを返す
// 判断できない、未実装の場合、trueを返す
//
// 1. MBBの最後が分岐していない場合、TBB,FBBをnullにしてfalseを返す
// 2. MBBの最後が無条件分岐の場合、TBBに分岐先ブロックをセットしてfalseを返す
// 3. MBBの最後が条件分岐かつ(分岐しないなら)次のブロックに飛ぶ場合、
//    TBBに分岐先ブロック、Condに条件を評価するオペランド一覧をセットして
//    falseを返す
// 4. MBBの最後が条件分岐かつ(分岐しないなら)無条件分岐する場合、
//    TBBにtrueの場合の分岐先ブロック、FBBにfalseの場合の分岐先ブロック、
//    Condに条件を評価するオペランド一覧をセットしてfalseを返す
//
// removeBranch insertBranchはこの関数が成功したとき
// 呼び出される可能性があるので実装してる必要がある
//
// AllowModifyがtrueの場合、BasicBlockを変更しても良い
// NOTE llvm/include/llvm/CodeGen/TargetInstrInfo.h
bool RXInstrInfo::analyzeBranch(MachineBasicBlock &MBB,
                                MachineBasicBlock *&TBB,
                                MachineBasicBlock *&FBB,
                                SmallVectorImpl<MachineOperand> &Cond,
                                bool AllowModify) const {
  LLVM_DEBUG(dbgs() << "### analyzeBranch " << MBB << "\n");
  return true;
}

// MBBの最後の分岐を削除する
// analyzeBranchが成功した場合のみ呼び出される
// 削除後の命令数を返す
// BytesRemovedがnullでない場合、変更したバイト数をセットする
unsigned RXInstrInfo::removeBranch(MachineBasicBlock &MBB,
                                      int *BytesRemoved) const {
  // TODO 未実装
  llvm_unreachable("Target didn't implement TargetInstrInfo::removeBranch!");
}

// ブロックの最後に分岐命令を追加する
// 引数はanalyzeBranchでセットした値となる
// analyzeBranchが成功した場合のみ呼び出される
// 追加後の命令数を返す
// BytesAddedがnullでない場合、変更したバイト数をセットする
//
// また、解析すべき元のブランチがなかったためにanalyzeBranchが適用されない場合
// 無条件分岐を追加するためにtail mergingで呼び出される
//
// Inserts a branch into the end of the specific MachineBasicBlock, returning
// the number of instructions inserted.
unsigned RXInstrInfo::insertBranch(
    MachineBasicBlock &MBB, MachineBasicBlock *TBB, MachineBasicBlock *FBB,
    ArrayRef<MachineOperand> Cond, const DebugLoc &DL, int *BytesAdded) const {
  // TODO 未実装
  llvm_unreachable("Target didn't implement TargetInstrInfo::insertBranch!");
}

// 引数で渡された分岐条件を反転する
// 反転した場合はfalseを返す
// 反転できない場合はtrueを返す
bool RXInstrInfo::reverseBranchCondition(
    SmallVectorImpl<MachineOperand> &Cond) const {
  return true;
}

// Pseudo生成後の処理
bool RXInstrInfo::expandPostRAPseudo(MachineInstr &MI) const {
  LLVM_DEBUG(dbgs() << "### expandPostRAPseudo " << MI << "\n");

  auto &MBB = *MI.getParent();
  unsigned Opcode = MI.getOpcode();
  int brOp = RX::BEQ;
  switch (Opcode) {
  default:
    // 何もしていない場合、偽を返す
    return false;
  case RX::pBRCOND_EQ:
    brOp = RX::BEQ;
    break;
  case RX::pBRCOND_NE:
    brOp = RX::BNE;
    break;
  case RX::pBRCOND_LT:
    brOp = RX::BLT;
    break;
  case RX::pBRCOND_ULT:
    brOp = RX::BLTU;
    break;
  case RX::pBRCOND_GT:
    brOp = RX::BGT;
    break;
  case RX::pBRCOND_UGT:
    brOp = RX::BGTU;
    break;
  case RX::pBRCOND_LE:
    brOp = RX::BLE;
    break;
  case RX::pBRCOND_ULE:
    brOp = RX::BLEU;
    break;
  case RX::pBRCOND_GE:
    brOp = RX::BGE;
    break;
  case RX::pBRCOND_UGE:
    brOp = RX::BGEU;
    break;
  }

  BuildMI(MBB, MI, MI.getDebugLoc(), get(RX::CMP_RR))
      .addReg(MI.getOperand(0).getReg())
      .addReg(MI.getOperand(1).getReg());

  BuildMI(MBB, MI, MI.getDebugLoc(), get(brOp))
      .addMBB(MI.getOperand(2).getMBB());

  MBB.erase(MI.getIterator());
  return true;
}

// 命令のバイト数を返す
unsigned RXInstrInfo::getInstSizeInBytes(const MachineInstr &MI) const {
  unsigned Opcode = MI.getOpcode();

  switch (Opcode) {
  default:
    return get(Opcode).getSize();
  case TargetOpcode::EH_LABEL:
  case TargetOpcode::IMPLICIT_DEF:
  case TargetOpcode::KILL:
  case TargetOpcode::DBG_VALUE:
    return 0;
  case TargetOpcode::INLINEASM:
  case TargetOpcode::INLINEASM_BR: {
    const MachineFunction &MF = *MI.getParent()->getParent();
    const auto &TM = static_cast<const RXTargetMachine &>(MF.getTarget());
    return getInlineAsmLength(MI.getOperand(0).getSymbolName(),
                              *TM.getMCAsmInfo());
  }
  }
}
