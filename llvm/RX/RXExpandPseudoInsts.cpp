//===-- RXExpandPseudoInsts.cpp - Expand pseudo instructions --------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains a pass that expands pseudo instructions into target
// instructions. This pass should be run after register allocation but before
// the post-regalloc scheduling pass.
//
//===----------------------------------------------------------------------===//

#include "RX.h"
#include "RXInstrInfo.h"
#include "RXTargetMachine.h"

#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/Support/Debug.h"

#define DEBUG_TYPE "rx-expandpseudoinsts"

using namespace llvm;

#define RX_EXPAND_PSEUDO_NAME "RX pseudo instruction expansion pass"

namespace {

class RXExpandPseudo : public MachineFunctionPass {
public:
  const RXInstrInfo *TII;
  static char ID;

  RXExpandPseudo() : MachineFunctionPass(ID) {
    initializeRXExpandPseudoPass(*PassRegistry::getPassRegistry());
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

  StringRef getPassName() const override { return RX_EXPAND_PSEUDO_NAME; }

private:
  bool expandMBB(MachineBasicBlock &MBB);
  bool expandMI(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                MachineBasicBlock::iterator &NextMBBI);
  bool expandBrcond(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                    int branchOp, MachineBasicBlock::iterator &NextMBBI);
  bool expandStoreCond(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                       int scOp, MachineBasicBlock::iterator &NextMBBI);
};

char RXExpandPseudo::ID = 0;

bool RXExpandPseudo::runOnMachineFunction(MachineFunction &MF) {
  TII = static_cast<const RXInstrInfo *>(MF.getSubtarget().getInstrInfo());
  bool Modified = false;
  for (auto &MBB : MF)
    Modified |= expandMBB(MBB);
  return Modified;
}

bool RXExpandPseudo::expandMBB(MachineBasicBlock &MBB) {
  bool Modified = false;

  MachineBasicBlock::iterator MBBI = MBB.begin(), E = MBB.end();
  while (MBBI != E) {
    LLVM_DEBUG(dbgs() << "### expandMBB " << *MBBI << "\n");
    MachineBasicBlock::iterator NMBBI = std::next(MBBI);
    Modified |= expandMI(MBB, MBBI, NMBBI);
    MBBI = NMBBI;
  }

  return Modified;
}

bool RXExpandPseudo::expandMI(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator MBBI,
                                 MachineBasicBlock::iterator &NextMBBI) {
  switch (MBBI->getOpcode()) {
  case RX::pBRCOND_EQ:
    return expandBrcond(MBB, MBBI, RX::BEQ, NextMBBI);
  case RX::pBRCOND_NE:
    return expandBrcond(MBB, MBBI, RX::BNE, NextMBBI);
  case RX::pBRCOND_LT:
    return expandBrcond(MBB, MBBI, RX::BLT, NextMBBI);
  case RX::pBRCOND_ULT:
    return expandBrcond(MBB, MBBI, RX::BLTU, NextMBBI);
  case RX::pBRCOND_GT:
    return expandBrcond(MBB, MBBI, RX::BGT, NextMBBI);
  case RX::pBRCOND_UGT:
    return expandBrcond(MBB, MBBI, RX::BGTU, NextMBBI);
  case RX::pBRCOND_LE:
    return expandBrcond(MBB, MBBI, RX::BLE, NextMBBI);
  case RX::pBRCOND_ULE:
    return expandBrcond(MBB, MBBI, RX::BLEU, NextMBBI);
  case RX::pBRCOND_GE:
    return expandBrcond(MBB, MBBI, RX::BGE, NextMBBI);
  case RX::pBRCOND_UGE:
    return expandBrcond(MBB, MBBI, RX::BGEU, NextMBBI);

  case RX::pSETCC_EQ:
    return expandStoreCond(MBB, MBBI, RX::SCEQ, NextMBBI);
  case RX::pSETCC_NE:
    return expandStoreCond(MBB, MBBI, RX::SCNE, NextMBBI);
  case RX::pSETCC_LT:
    return expandStoreCond(MBB, MBBI, RX::SCLT, NextMBBI);
  case RX::pSETCC_ULT:
    return expandStoreCond(MBB, MBBI, RX::SCLTU, NextMBBI);
  case RX::pSETCC_GT:
    return expandStoreCond(MBB, MBBI, RX::SCGT, NextMBBI);
  case RX::pSETCC_UGT:
    return expandStoreCond(MBB, MBBI, RX::SCGTU, NextMBBI);
  case RX::pSETCC_LE:
    return expandStoreCond(MBB, MBBI, RX::SCLE, NextMBBI);
  case RX::pSETCC_ULE:
    return expandStoreCond(MBB, MBBI, RX::SCLEU, NextMBBI);
  case RX::pSETCC_GE:
    return expandStoreCond(MBB, MBBI, RX::SCGE, NextMBBI);
  case RX::pSETCC_UGE:
    return expandStoreCond(MBB, MBBI, RX::SCGEU, NextMBBI);
  }

  return false;
}

static void buildCmp(const RXInstrInfo *TII, MachineBasicBlock &MBB,
                     MachineBasicBlock::iterator MBBI, DebugLoc DL,
                     MachineOperand operand1, MachineOperand operand2) {
  if (operand1.isReg()) {
    // cmp reg reg
    BuildMI(MBB, MBBI, DL, TII->get(RX::CMP_RR))
      .addReg(operand1.getReg())
      .addReg(operand2.getReg());
  } else {
    // cmp imm reg
    auto operandVal = operand1.getImm();
    auto opcode = RX::CMP_I32R;
    // 4bit即値の比較が使える場合は使う
    if (operandVal >= 0 && operandVal <=15)
      opcode = RX::CMP_UI4R;

    BuildMI(MBB, MBBI, DL, TII->get(opcode))
      .addImm(operandVal)
      .addReg(operand2.getReg());
  }
}

bool RXExpandPseudo::expandBrcond( MachineBasicBlock &MBB,
    MachineBasicBlock::iterator MBBI, int branchOp,
    MachineBasicBlock::iterator &NextMBBI) {
  LLVM_DEBUG(dbgs() << "### expandBrcond " << *MBBI << "\n");

  MachineInstr &MI = *MBBI;
  DebugLoc DL = MI.getDebugLoc();

  // pBRCOND_*のオペランドは(reg reg)か(imm reg)の2種類
  buildCmp(TII, MBB, MBBI, DL, MI.getOperand(0), MI.getOperand(1));

  BuildMI(MBB, MBBI, DL, TII->get(branchOp))
      .addMBB(MI.getOperand(2).getMBB());

  NextMBBI = MBB.end();
  MI.eraseFromParent();
  return true;
}

bool RXExpandPseudo::expandStoreCond(MachineBasicBlock &MBB,
    MachineBasicBlock::iterator MBBI, int scOp,
    MachineBasicBlock::iterator &NextMBBI) {
  LLVM_DEBUG(dbgs() << "### expandStoreCond " << *MBBI << "\n");

  MachineInstr &MI = *MBBI;
  DebugLoc DL = MI.getDebugLoc();

  // pSETCC_*のオペランドは(reg reg reg)か(reg imm reg)の2種類
  buildCmp(TII, MBB, MBBI, DL, MI.getOperand(1), MI.getOperand(2));

  BuildMI(MBB, MBBI, DL, TII->get(scOp))
      .addReg(MI.getOperand(0).getReg(), RegState::Define);

  //NextMBBI = MBB.end();
  MI.eraseFromParent();
  return true;
}

} // end of anonymous namespace

INITIALIZE_PASS(RXExpandPseudo, "rx-expand-pseudo",
                RX_EXPAND_PSEUDO_NAME, false, false)
namespace llvm {

FunctionPass *createRXExpandPseudoPass() { return new RXExpandPseudo(); }

} // end of namespace llvm
