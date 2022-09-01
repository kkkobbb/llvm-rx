//===-- RXMCTargetDesc.cpp - RX Target Descriptions -----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// This file provides RX-specific target descriptions.
///
//===----------------------------------------------------------------------===//

#include "RXMCTargetDesc.h"
#include "RXInstPrinter.h"
#include "RXMCAsmInfo.h"
#include "RXTargetStreamer.h"
#include "TargetInfo/RXTargetInfo.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/CodeGen/Register.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/ErrorHandling.h"

#define GET_INSTRINFO_MC_DESC
#include "RXGenInstrInfo.inc"

#define GET_REGINFO_MC_DESC
#include "RXGenRegisterInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "RXGenSubtargetInfo.inc"

using namespace llvm;

static MCInstrInfo *createRXMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitRXMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createRXMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  // リターンアドレスを保持する汎用レジスタを指定する？
  // RXではシステムレジスタ(PR)でリターンアドレスを保持するためNoRegisterとした
  InitRXMCRegisterInfo(X, RX::NoRegister);
  return X;
}

static MCAsmInfo *createRXMCAsmInfo(const MCRegisterInfo &MRI,
                                    const Triple &TT,
                                    const MCTargetOptions &Options) {
  MCAsmInfo *MAI = new RXMCAsmInfo(TT);
  return MAI;
}

static MCSubtargetInfo *createRXMCSubtargetInfo(const Triple &TT,
                                                StringRef CPU, StringRef FS) {
  return createRXMCSubtargetInfoImpl(TT, CPU, /*TuneCPU*/ CPU, FS);
}

static MCInstPrinter *createRXMCInstPrinter(const Triple &T,
                                            unsigned SyntaxVariant,
                                            const MCAsmInfo &MAI,
                                            const MCInstrInfo &MII,
                                            const MCRegisterInfo &MRI) {
  return new RXInstPrinter(MAI, MII, MRI);
}

static MCTargetStreamer *createRXAsmTargetStreamer(MCStreamer &S,
                                                   formatted_raw_ostream &OS,
                                                   MCInstPrinter *InstPrint,
                                                   bool isVerboseAsm) {
  return new RXTargetAsmStreamer(S, OS);
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeRXTargetMC() {
  // NOTE llvm/include/llvm/MC/TargetRegistry.h getTheFooTarget
  for (Target *T : {&getTheRXv1Target()}) {
    TargetRegistry::RegisterMCAsmInfo(*T, createRXMCAsmInfo);
    TargetRegistry::RegisterMCInstrInfo(*T, createRXMCInstrInfo);
    TargetRegistry::RegisterMCRegInfo(*T, createRXMCRegisterInfo);
    TargetRegistry::RegisterMCAsmBackend(*T, createRXAsmBackend);
    TargetRegistry::RegisterMCCodeEmitter(*T, createRXMCCodeEmitter);
    TargetRegistry::RegisterMCInstPrinter(*T, createRXMCInstPrinter);
    TargetRegistry::RegisterMCSubtargetInfo(*T, createRXMCSubtargetInfo);

    // Register the asm target streamer.
    TargetRegistry::RegisterAsmTargetStreamer(*T, createRXAsmTargetStreamer);
  }
}
