//===-- RXMCTargetDesc.h - RX Target Descriptions --------------*- C++ -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file provides RX specific target descriptions.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_RX_MCTARGETDESC_RXMCTARGETDESC_H
#define LLVM_LIB_TARGET_RX_MCTARGETDESC_RXMCTARGETDESC_H

#include "llvm/Config/config.h"
#include "llvm/MC/MCTargetOptions.h"
#include "llvm/Support/DataTypes.h"
#include <memory>

namespace llvm {
class MCContext;
class MCInstrInfo;
class MCObjectTargetWriter;
class MCRegisterInfo;
class MCSubtargetInfo;
class StringRef;
class Target;
class Triple;
class raw_ostream;
class raw_pwrite_stream;
}

// Defines symbolic names for RX registers.
#define GET_REGINFO_ENUM
#include "RXGenRegisterInfo.inc"

// Defines symbolic names for RX instructions.
#define GET_INSTRINFO_ENUM
#include "RXGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "RXGenSubtargetInfo.inc"

#endif
