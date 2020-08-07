//===-- RXSubtarget.h - Define Subtarget for the RX ------------*- C++ -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares the RX specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_RX_RXSUBTARGET_H
#define LLVM_LIB_TARGET_RX_RXSUBTARGET_H

#include "RXFrameLowering.h"
#include "RXInstrInfo.h"
#include "RXISelLowering.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/Target/TargetMachine.h"

#define GET_SUBTARGETINFO_HEADER
#include "RXGenSubtargetInfo.inc"

namespace llvm {
class StringRef;

class RXSubtarget : public RXGenSubtargetInfo {
  virtual void anchor();

  enum RXArchEnum {
    RXDefault,
    RXv1
  };

  RXArchEnum RXArchVersion;

  RXFrameLowering FrameLowering;
  RXInstrInfo InstrInfo;
  RXRegisterInfo RegInfo;
  RXTargetLowering TLInfo;

public:
  // Initializes the data members to match that of the specified triple.
  RXSubtarget(const Triple &TT, StringRef CPU, StringRef FS,
              StringRef ABIName, const TargetMachine &TM);

  // Parses features string setting specified subtarget options. The
  // definition of this function is auto-generated by tblgen.
  void ParseSubtargetFeatures(StringRef CPU, StringRef FS);

  const RXFrameLowering *getFrameLowering() const override {
    return &FrameLowering;
  }
  const RXInstrInfo *getInstrInfo() const override { return &InstrInfo; }
  const RXRegisterInfo *getRegisterInfo() const override {
    return &RegInfo;
  }
  const RXTargetLowering *getTargetLowering() const override {
    return &TLInfo;
  }

  bool hasRXv1() const { return RXArchVersion >= RXv1; }
};
} // End llvm namespace

#endif
