//===-- RXTargetInfo.cpp - RX Target Implementation -----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "TargetInfo/RXTargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
using namespace llvm;

Target &llvm::getTheRXv1Target() {
  static Target TheRXv1Target;
  return TheRXv1Target;
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeRXTargetInfo() {
  RegisterTarget<Triple::rxv1> X(getTheRXv1Target(), "rxv1",
                                 "Renesas RXv1", "RX");
}
