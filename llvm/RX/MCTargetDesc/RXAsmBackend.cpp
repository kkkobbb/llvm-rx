//===-- RXAsmBackend.cpp - RX Assembler Backend ---------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "RXAsmBackend.h"
#include "llvm/ADT/APInt.h"
#include "llvm/MC/MCAsmLayout.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCDirectives.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/MCValue.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

void RXAsmBackend::relaxInstruction(MCInst &Inst,
                                    const MCSubtargetInfo &STI) const {
  llvm_unreachable("Opcode not expected!");
}

bool RXAsmBackend::mayNeedRelaxation(const MCInst &Inst,
                                     const MCSubtargetInfo &STI) const {
  return false;
}

bool RXAsmBackend::writeNopData(raw_ostream &OS, uint64_t Count,
                                const MCSubtargetInfo *STI) const {
  for (; Count > 0; --Count)
    OS.write("\x03", 1);
  return true;
}

void RXAsmBackend::applyFixup(const MCAssembler &Asm, const MCFixup &Fixup,
                              const MCValue &Target,
                              MutableArrayRef<char> Data, uint64_t Value,
                              bool IsResolved,
                              const MCSubtargetInfo *STI) const {
  return;
}

std::unique_ptr<MCObjectTargetWriter>
RXAsmBackend::createObjectTargetWriter() const {
  return createRXELFObjectWriter(OSABI, Is64Bit);
}

MCAsmBackend *llvm::createRXAsmBackend(const Target &T,
                                       const MCSubtargetInfo &STI,
                                       const MCRegisterInfo &MRI,
                                       const MCTargetOptions &Options) {
  const Triple &TT = STI.getTargetTriple();
  uint8_t OSABI = MCELFObjectTargetWriter::getOSABI(TT.getOS());
  return new RXAsmBackend(STI, OSABI, TT.isArch64Bit(), Options);
}
