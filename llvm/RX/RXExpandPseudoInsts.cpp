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
  }

  return false;
}

bool RXExpandPseudo::expandBrcond( MachineBasicBlock &MBB,
    MachineBasicBlock::iterator MBBI, int branchOp,
    MachineBasicBlock::iterator &NextMBBI) {
  LLVM_DEBUG(dbgs() << "### expandBrcond " << MBB << "\n");

  MachineInstr &MI = *MBBI;
  DebugLoc DL = MI.getDebugLoc();

  // pBRCOND_*のオペランドは(reg reg)か(imm reg)の2種類
  if (MI.getOperand(0).isReg()) {
    BuildMI(MBB, MI, DL, TII->get(RX::CMP_RR))
      .addReg(MI.getOperand(0).getReg())
      .addReg(MI.getOperand(1).getReg());
  } else {
    auto oprand0 = MI.getOperand(0).getImm();
    auto opcode = RX::CMP_I32R;
    // 4bit即値の比較が使える場合は使う
    if (oprand0 >= 0 && oprand0 <=15)
      opcode = RX::CMP_UI4R;

    BuildMI(MBB, MI, DL, TII->get(opcode))
      .addImm(oprand0)
      .addReg(MI.getOperand(1).getReg());
  }

  BuildMI(MBB, MI, DL, TII->get(branchOp))
      .addMBB(MI.getOperand(2).getMBB());

  NextMBBI = MBB.end();
  MI.eraseFromParent();
  return true;
}

} // end of anonymous namespace

INITIALIZE_PASS(RXExpandPseudo, "rx-expand-pseudo",
                RX_EXPAND_PSEUDO_NAME, false, false)
namespace llvm {

FunctionPass *createRXExpandPseudoPass() { return new RXExpandPseudo(); }

} // end of namespace llvm
