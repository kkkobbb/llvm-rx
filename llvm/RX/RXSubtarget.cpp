//===-- RXSubtarget.cpp - RX Subtarget Information ------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the RX specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#include "RXSubtarget.h"
#include "RX.h"
#include "RXTargetMachine.h"
#include "llvm/MC/TargetRegistry.h"
#include <string>

using namespace llvm;

#define DEBUG_TYPE "rx-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "RXGenSubtargetInfo.inc"

void RXSubtarget::anchor() {}

RXSubtarget::RXSubtarget(const Triple &TT, StringRef CPU, StringRef FS,
                         StringRef ABIName, const TargetMachine &TM)
    : RXGenSubtargetInfo(TT, CPU, /*TuneCPU*/ CPU, FS),
      FrameLowering(*this),
      InstrInfo(), RegInfo(getHwMode()), TLInfo(TM, *this) {
  if (CPU.empty())
    CPU = "generic";

  ParseSubtargetFeatures(CPU, /*TuneCPU*/ CPU, FS);
}
