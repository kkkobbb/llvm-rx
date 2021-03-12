//===-- RXELFObjectWriter.cpp - RX ELF Writer -----------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/RXMCTargetDesc.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCFixup.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

namespace {
class RXELFObjectWriter : public MCELFObjectTargetWriter {
public:
  RXELFObjectWriter(uint8_t OSABI, bool Is64Bit);

  ~RXELFObjectWriter() override;

protected:
  unsigned getRelocType(MCContext &Ctx, const MCValue &Target,
                        const MCFixup &Fixup, bool IsPCRel) const override;
};
}

RXELFObjectWriter::RXELFObjectWriter(uint8_t OSABI, bool Is64Bit)
    : MCELFObjectTargetWriter(Is64Bit, OSABI, /* ELFのe_machine (ない場合はEM_NONE) */ ELF::EM_RX,
                              /*HasRelocationAddend*/ false) {}

RXELFObjectWriter::~RXELFObjectWriter() {}

unsigned RXELFObjectWriter::getRelocType(MCContext &Ctx,
                                         const MCValue &Target,
                                         const MCFixup &Fixup,
                                         bool IsPCRel) const {
  Ctx.reportError(Fixup.getLoc(), "Unsupported relocation type");
  return 0;
}

std::unique_ptr<MCObjectTargetWriter>
llvm::createRXELFObjectWriter(uint8_t OSABI, bool Is64Bit) {
  return std::make_unique<RXELFObjectWriter>(OSABI, Is64Bit);
}
