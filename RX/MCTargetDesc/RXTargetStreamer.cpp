//===-- RXTargetStreamer.cpp - RX Target Streamer Methods -----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file provides RX specific target streamer methods.
//
//===----------------------------------------------------------------------===//

#include "RXTargetStreamer.h"
#include "llvm/Support/FormattedStream.h"

using namespace llvm;

RXTargetStreamer::RXTargetStreamer(MCStreamer &S) : MCTargetStreamer(S) {}

// This part is for ascii assembly output
RXTargetAsmStreamer::RXTargetAsmStreamer(MCStreamer &S,
                                         formatted_raw_ostream &OS)
    : RXTargetStreamer(S), OS(OS) {}
