//===-- RXMCAsmInfo.cpp - RX Asm properties -------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the RXMCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "RXMCAsmInfo.h"
#include "llvm/ADT/Triple.h"
#include "llvm/BinaryFormat/Dwarf.h"
#include "llvm/MC/MCStreamer.h"
using namespace llvm;

void RXMCAsmInfo::anchor() {}

// NOTE llvm/include/llvm/MC/MCAsmInfo.h MCAsmInfo各メンバ変数
RXMCAsmInfo::RXMCAsmInfo(const Triple &TT) {
  CodePointerSize = 4;
  CalleeSaveStackSlotSize = 4;
  CommentString = ";";
  SupportsDebugInformation = true;
}
