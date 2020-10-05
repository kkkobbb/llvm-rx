//===-- RX.h - Top-level interface for RX ----------------------*- C++ -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in the LLVM
// RX back-end.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_RX_RX_H
#define LLVM_LIB_TARGET_RX_RX_H

#include "llvm/Target/TargetMachine.h"

namespace llvm {
class RXSubtarget;
class RXTargetMachine;
class AsmPrinter;
class FunctionPass;
class InstructionSelector;
class MCInst;
class MCOperand;
class MachineInstr;
class MachineOperand;
class PassRegistry;

void LowerRXMachineInstrToMCInst(const MachineInstr *MI, MCInst &OutMI,
                                 const AsmPrinter &AP);
bool LowerRXMachineOperandToMCOperand(const MachineOperand &MO,
                                      MCOperand &MCOp, const AsmPrinter &AP);

FunctionPass *createRXISelDag(RXTargetMachine &TM);

FunctionPass *createRXExpandPseudoPass();
void initializeRXExpandPseudoPass(PassRegistry &);

}

#endif
