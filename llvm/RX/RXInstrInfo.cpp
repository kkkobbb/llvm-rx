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
      // TODO ここでDstRegをDefineにしないと関数呼び出し後のレジスタ復元時にエラーになる
      //      (llcの-verify-machineinstrsを付けた時のみ)
      //      RISCV等では付けていないので別の対処法があるかも
      .addReg(DstReg, RegState::Define)
      .addFrameIndex(FI)
      .addImm(0);
}

// The contents of values added to Cond are not examined outside of
// RXInstrInfo, giving us flexibility in what to push to it. For RX, we
// push BranchOpcode, Reg1, Reg2.
static bool parseCondBranch(MachineInstr &LastInst, MachineBasicBlock *&Target,
                            SmallVectorImpl<MachineOperand> &Cond) {
  LLVM_DEBUG(dbgs() << "### parseCondBranch " << LastInst << "\n");

  // オペランドの数がpBRCOND_*命令と異なる場合、何もしない
  if (LastInst.getNumOperands() != 3)
    return true;

  // NOTE ほぼRISCV

  // Block ends with fall-through condbranch.
  assert(LastInst.getDesc().isConditionalBranch() &&
         "Unknown conditional branch");
  Target = LastInst.getOperand(2).getMBB();
  Cond.push_back(MachineOperand::CreateImm(LastInst.getOpcode()));
  Cond.push_back(LastInst.getOperand(0));
  Cond.push_back(LastInst.getOperand(1));
  return false;
}

static unsigned getOppositeBranchOpcode(int Opc) {
  switch (Opc) {
  default:
    llvm_unreachable("Unrecognized conditional branch");
  case RX::pBRCOND_EQ:
    return RX::pBRCOND_NE;
  case RX::pBRCOND_NE:
    return RX::pBRCOND_EQ;
  case RX::pBRCOND_LT:
    return RX::pBRCOND_GE;
  case RX::pBRCOND_ULT:
    return RX::pBRCOND_UGE;
  case RX::pBRCOND_GT:
    return RX::pBRCOND_LE;
  case RX::pBRCOND_UGT:
    return RX::pBRCOND_ULE;
  case RX::pBRCOND_LE:
    return RX::pBRCOND_GT;
  case RX::pBRCOND_ULE:
    return RX::pBRCOND_UGT;
  case RX::pBRCOND_GE:
    return RX::pBRCOND_LT;
  case RX::pBRCOND_UGE:
    return RX::pBRCOND_ULT;
  }
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
  // NOTE ほぼRISCV

  TBB = FBB = nullptr;
  Cond.clear();

  // If the block has no terminators, it just falls into the block after it.
  MachineBasicBlock::iterator I = MBB.getLastNonDebugInstr();
  if (I == MBB.end() || !isUnpredicatedTerminator(*I))
    return false;

  // Count the number of terminators and find the first unconditional or
  // indirect branch.
  MachineBasicBlock::iterator FirstUncondOrIndirectBr = MBB.end();
  int NumTerminators = 0;
  for (auto J = I.getReverse(); J != MBB.rend() && isUnpredicatedTerminator(*J);
       J++) {
    NumTerminators++;
    if (J->getDesc().isUnconditionalBranch() ||
        J->getDesc().isIndirectBranch()) {
      FirstUncondOrIndirectBr = J.getReverse();
    }
  }

  // If AllowModify is true, we can erase any terminators after
  // FirstUncondOrIndirectBR.
  if (AllowModify && FirstUncondOrIndirectBr != MBB.end()) {
    while (std::next(FirstUncondOrIndirectBr) != MBB.end()) {
      std::next(FirstUncondOrIndirectBr)->eraseFromParent();
      NumTerminators--;
    }
    I = FirstUncondOrIndirectBr;
  }

  // We can't handle blocks that end in an indirect branch.
  if (I->getDesc().isIndirectBranch())
    return true;

  // We can't handle blocks with more than 2 terminators.
  if (NumTerminators > 2)
    return true;

  // Handle a single unconditional branch.
  if (NumTerminators == 1 && I->getDesc().isUnconditionalBranch()) {
    TBB = I->getOperand(0).getMBB();
    return false;
  }

  // Handle a single conditional branch.
  if (NumTerminators == 1 && I->getDesc().isConditionalBranch()) {
    return parseCondBranch(*I, TBB, Cond);
  }

  // Handle a conditional branch followed by an unconditional branch.
  if (NumTerminators == 2 && std::prev(I)->getDesc().isConditionalBranch() &&
      I->getDesc().isUnconditionalBranch()) {
    if(parseCondBranch(*std::prev(I), TBB, Cond)) {
      return true;
    } else {
      FBB = I->getOperand(0).getMBB();
      return false;
    }
  }

  // Otherwise, we can't handle this.
  return true;
}

// MBBの最後の分岐を削除する
// analyzeBranchが成功した場合のみ呼び出される
// 削除後の命令数を返す
// BytesRemovedがnullでない場合、変更したバイト数をセットする
unsigned RXInstrInfo::removeBranch(MachineBasicBlock &MBB,
                                      int *BytesRemoved) const {
  LLVM_DEBUG(dbgs() << "### removeBranch " << MBB << "\n");
  // 末尾が分岐になる場合は以下の3パターン
  // 1. 条件分岐
  //   b*  LBL
  // 2. 無条件分岐
  //   bra LBL
  // 3. 条件分岐と無条件分岐の組み合わせ
  //   b*  LBL1
  //   bra LBL2
  // NOTE ほぼRISCV

  if (BytesRemoved)
    *BytesRemoved = 0;
  MachineBasicBlock::iterator I = MBB.getLastNonDebugInstr();
  if (I == MBB.end())
    return 0;

  if (!I->getDesc().isUnconditionalBranch() &&
      !I->getDesc().isConditionalBranch())
    return 0;

  // Remove the branch.
  if (BytesRemoved)
    *BytesRemoved += getInstSizeInBytes(*I);
  I->eraseFromParent();

  I = MBB.end();

  if (I == MBB.begin())
    return 1;
  --I;
  if (!I->getDesc().isConditionalBranch())
    return 1;

  // Remove the branch.
  if (BytesRemoved)
    *BytesRemoved += getInstSizeInBytes(*I);
  I->eraseFromParent();
  return 2;
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
  LLVM_DEBUG(dbgs() << "### insertBranch " << MBB << "\n");
  // CondにはanalyzeBranch()によって
  // 条件分岐の場合、[pBRCOND_*, lhs(reg), rhs(reg)]が格納される
  // 無条件分岐の場合、空になる
  // NOTE ほぼRISCV

  if (BytesAdded)
    *BytesAdded = 0;

  // Shouldn't be a fall through.
  assert(TBB && "InsertBranch must not be told to insert a fallthrough");
  assert((Cond.size() == 3 || Cond.size() == 0) &&
         "RX branch conditions have two components!");

  // Unconditional branch.
  if (Cond.empty()) {
    MachineInstr &MI = *BuildMI(&MBB, DL, get(RX::BRA)).addMBB(TBB);
    if (BytesAdded)
      *BytesAdded += getInstSizeInBytes(MI);
    return 1;
  }

  // Either a one or two-way conditional branch.
  unsigned Opc = Cond[0].getImm();
  MachineInstr &CondMI =
      *BuildMI(&MBB, DL, get(Opc)).add(Cond[1]).add(Cond[2]).addMBB(TBB);
  if (BytesAdded)
    *BytesAdded += getInstSizeInBytes(CondMI);

  // One-way conditional branch.
  if (!FBB)
    return 1;

  // Two-way conditional branch.
  MachineInstr &MI = *BuildMI(&MBB, DL, get(RX::BRA)).addMBB(FBB);
  if (BytesAdded)
    *BytesAdded += getInstSizeInBytes(MI);
  return 2;
}

// 引数で渡された分岐条件を反転する
// 反転した場合はfalseを返す
// 反転できない場合はtrueを返す
//
// analyzeBranch()で成功した(falseを返した)場合、
// 一部の処理で分岐命令を書き換えるために呼び出される
// 例: llvm/lib/CodeGen/BranchFolding.cpp
bool RXInstrInfo::reverseBranchCondition(
    SmallVectorImpl<MachineOperand> &Cond) const {
  LLVM_DEBUG(dbgs() << "### reverseBranchCondition\n");
  // NOTE ほぼRISCV

  assert((Cond.size() == 3) && "Invalid branch condition!");
  Cond[0].setImm(getOppositeBranchOpcode(Cond[0].getImm()));
  return false;
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
