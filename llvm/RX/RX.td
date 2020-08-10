//===-- RX.td - Describe the RX Target Machine ------------*- tablegen -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

//===----------------------------------------------------------------------===//
// RX subtarget features and instruction predicates.
//===----------------------------------------------------------------------===//

def FeatureRXv1 : SubtargetFeature<"rxv1", "RXArchVersion", "RXv1",
                                   "RXv1 ISA Support">;

//===----------------------------------------------------------------------===//
// Registers, calling conventions, instruction descriptions.
//===----------------------------------------------------------------------===//

include "RXRegisterInfo.td"
include "RXCallingConv.td"
include "RXInstrInfo.td"

//===----------------------------------------------------------------------===//
// RX processors supported.
//===----------------------------------------------------------------------===//

def : ProcessorModel<"generic", NoSchedModel, [FeatureRXv1]>;
def : ProcessorModel<"rxv1", NoSchedModel, [FeatureRXv1]>;

//===----------------------------------------------------------------------===//
// Define the RX target.
//===----------------------------------------------------------------------===//

def RXInstrInfo : InstrInfo {
  let guessInstructionProperties = 0;
}

def RXAsmWriter : AsmWriter {
  int PassSubtarget = 1;
}

def RX : Target {
  let InstructionSet = RXInstrInfo;
  let AssemblyWriters = [RXAsmWriter];
  let AllowRegisterRenaming = 1;
}
