//===-- RXAsmPrinter.cpp - RX LLVM assembly writer ------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to the RX assembly language.
//
//===----------------------------------------------------------------------===//

#include "RX.h"
#include "MCTargetDesc/RXInstPrinter.h"
#include "RXTargetMachine.h"
#include "TargetInfo/RXTargetInfo.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Debug.h"
using namespace llvm;

#define DEBUG_TYPE "rx-asmprinter"

namespace {
class RXAsmPrinter : public AsmPrinter {
public:
  explicit RXAsmPrinter(TargetMachine &TM,
                            std::unique_ptr<MCStreamer> Streamer)
      : AsmPrinter(TM, std::move(Streamer)) {}

  StringRef getPassName() const override { return "RX Assembly Printer"; }

  void emitInstruction(const MachineInstr *MI) override;
};
}

void RXAsmPrinter::emitInstruction(const MachineInstr *MI) {
  LLVM_DEBUG(dbgs() << "### EmitInstruction " << *MI << "\n");

  MCInst TmpInst;
  LowerRXMachineInstrToMCInst(MI, TmpInst, *this);
  EmitToStreamer(*OutStreamer, TmpInst);
}

// Force static initialization.
extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeRXAsmPrinter() {
  RegisterAsmPrinter<RXAsmPrinter> X(getTheRXv1Target());
}
