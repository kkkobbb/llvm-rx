//===-- RXTargetStreamer.h - RX Target Streamer ----------------*- C++ -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_RX_RXTARGETSTREAMER_H
#define LLVM_LIB_TARGET_RX_RXTARGETSTREAMER_H

#include "llvm/MC/MCStreamer.h"

namespace llvm {

class RXTargetStreamer : public MCTargetStreamer {
public:
  RXTargetStreamer(MCStreamer &S);
};

// This part is for ascii assembly output
class RXTargetAsmStreamer : public RXTargetStreamer {
  formatted_raw_ostream &OS;

public:
  RXTargetAsmStreamer(MCStreamer &S, formatted_raw_ostream &OS);
};

}
#endif
