//===-- RXMCCodeEmitter.cpp - Convert RX code to machine code -------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the RXMCCodeEmitter class.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/RXMCTargetDesc.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/Register.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstBuilder.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/EndianStream.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "mccodeemitter"

STATISTIC(MCNumEmitted, "Number of MC instructions emitted");

namespace {
class RXMCCodeEmitter : public MCCodeEmitter {
  RXMCCodeEmitter(const RXMCCodeEmitter &) = delete;
  void operator=(const RXMCCodeEmitter &) = delete;
  MCContext &Ctx;
  MCInstrInfo const &MCII;

public:
  RXMCCodeEmitter(MCContext &ctx, MCInstrInfo const &MCII)
      : Ctx(ctx), MCII(MCII) {}

  ~RXMCCodeEmitter() override {}

  void encodeInstruction(const MCInst &MI, raw_ostream &OS,
                         SmallVectorImpl<MCFixup> &Fixups,
                         const MCSubtargetInfo &STI) const override;

  /// TableGen'erated function for getting the binary encoding for an
  /// instruction.
  uint64_t getBinaryCodeForInstr(const MCInst &MI,
                                 SmallVectorImpl<MCFixup> &Fixups,
                                 const MCSubtargetInfo &STI) const;

  /// Return binary encoding of operand. If the machine operand requires
  /// relocation, record the relocation and return zero.
  unsigned getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                             SmallVectorImpl<MCFixup> &Fixups,
                             const MCSubtargetInfo &STI) const;

  unsigned getDsp16wOpValue(const MCInst &MI, unsigned OpNo,
                            SmallVectorImpl<MCFixup> &Fixups,
                            const MCSubtargetInfo &STI) const;
  unsigned getDsp16lOpValue(const MCInst &MI, unsigned OpNo,
                            SmallVectorImpl<MCFixup> &Fixups,
                            const MCSubtargetInfo &STI) const;
  unsigned getImm16OpValue(const MCInst &MI, unsigned OpNo,
                           SmallVectorImpl<MCFixup> &Fixups,
                           const MCSubtargetInfo &STI) const;
  unsigned getImm32OpValue(const MCInst &MI, unsigned OpNo,
                           SmallVectorImpl<MCFixup> &Fixups,
                           const MCSubtargetInfo &STI) const;
};
} // end anonymous namespace

MCCodeEmitter *llvm::createRXMCCodeEmitter(const MCInstrInfo &MCII,
                                           const MCRegisterInfo &MRI,
                                           MCContext &Ctx) {
  return new RXMCCodeEmitter(Ctx, MCII);
}

static void emitInstruction(uint64_t Val, unsigned Size,
                            const MCSubtargetInfo &STI,
                            raw_ostream &OS) {
  for (int64_t i = Size - 1; i >= 0; --i) {
    uint8_t Byte = (Val >> (i * 8)) & 0xFF;
    support::endian::write<uint8_t>(OS, Byte, support::little);
  }
}

void RXMCCodeEmitter::encodeInstruction(const MCInst &MI, raw_ostream &OS,
                                        SmallVectorImpl<MCFixup> &Fixups,
                                        const MCSubtargetInfo &STI) const {
  const MCInstrDesc &Desc = MCII.get(MI.getOpcode());
  // Get byte count of instruction.
  unsigned Size = Desc.getSize();

  uint64_t BinaryOpCode = getBinaryCodeForInstr(MI, Fixups, STI);
  emitInstruction(BinaryOpCode, Size, STI, OS);

  ++MCNumEmitted; // Keep track of the # of mi's emitted.
}

unsigned
RXMCCodeEmitter::getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                                   SmallVectorImpl<MCFixup> &Fixups,
                                   const MCSubtargetInfo &STI) const {
  LLVM_DEBUG(dbgs() << "### getMachineOpValue " << MI << ", " << MO << "\n");

  if (MO.isReg())
    return Ctx.getRegisterInfo()->getEncodingValue(MO.getReg());

  if (MO.isImm())
    return static_cast<unsigned>(MO.getImm());

  llvm_unreachable("Unhandled expression!");
  return 0;
}

template<unsigned ByteSize>
static unsigned convLittleEndian(const unsigned Value) {
  unsigned LEValue = 0;
  for (unsigned i = 0; i < ByteSize; ++i) {
    const unsigned pos = i * 8;
    const unsigned lpos = (ByteSize - 1 - i) * 8;
    LEValue |= ((Value & (0xff << pos)) >> pos) << lpos;
  }

  return LEValue;
}

unsigned
RXMCCodeEmitter::getDsp16wOpValue(const MCInst &MI, unsigned OpNo,
                                  SmallVectorImpl<MCFixup> &Fixups,
                                  const MCSubtargetInfo &STI) const {
  const MCOperand &MO = MI.getOperand(OpNo);

  assert(MO.isImm() &&
         "getDsp16wOpValue expects only immediates");

  const unsigned Dsp = MO.getImm() >> 1;
  return convLittleEndian<2>(Dsp);
}

unsigned
RXMCCodeEmitter::getDsp16lOpValue(const MCInst &MI, unsigned OpNo,
                                  SmallVectorImpl<MCFixup> &Fixups,
                                  const MCSubtargetInfo &STI) const {
  const MCOperand &MO = MI.getOperand(OpNo);

  assert(MO.isImm() &&
         "getDsp16lOpValue expects only immediates");

  const unsigned Dsp = MO.getImm() >> 2;
  return convLittleEndian<2>(Dsp);
}

unsigned
RXMCCodeEmitter::getImm16OpValue(const MCInst &MI, unsigned OpNo,
                                 SmallVectorImpl<MCFixup> &Fixups,
                                 const MCSubtargetInfo &STI) const {
  const MCOperand &MO = MI.getOperand(OpNo);

  assert(MO.isImm() &&
         "getImm16OpValue expects only immediates");

  const unsigned Imm = MO.getImm();
  return convLittleEndian<2>(Imm);
}

unsigned
RXMCCodeEmitter::getImm32OpValue(const MCInst &MI, unsigned OpNo,
                                 SmallVectorImpl<MCFixup> &Fixups,
                                 const MCSubtargetInfo &STI) const {
  const MCOperand &MO = MI.getOperand(OpNo);

  assert(MO.isImm() &&
         "getImm32OpValue expects only immediates");

  const unsigned Imm = MO.getImm();
  return convLittleEndian<4>(Imm);
}

#include "RXGenMCCodeEmitter.inc"
