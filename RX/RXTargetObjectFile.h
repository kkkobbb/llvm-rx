//===-- RXTargetObjectFile.h - RX Object Info -*- C++ -------------------*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_RX_RXTARGETOBJECTFILE_H
#define LLVM_LIB_TARGET_RX_RXTARGETOBJECTFILE_H

#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"

namespace llvm {
class RXTargetMachine;

/// This implementation is used for RX ELF targets.
class RXELFTargetObjectFile : public TargetLoweringObjectFileELF {

public:
  void Initialize(MCContext &Ctx, const TargetMachine &TM) override;
};

} // end namespace llvm

#endif
