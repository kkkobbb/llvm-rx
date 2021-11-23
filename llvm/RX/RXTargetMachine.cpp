//===-- RXTargetMachine.cpp - Define TargetMachine for RX -----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements the info about RX target spec.
//
//===----------------------------------------------------------------------===//

#include "RX.h"
#include "RXTargetMachine.h"
#include "RXTargetObjectFile.h"
#include "TargetInfo/RXTargetInfo.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/InitializePasses.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Target/TargetOptions.h"
using namespace llvm;

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeRXTarget() {
  RegisterTargetMachine<RXTargetMachine> X(getTheRXv1Target());

  PassRegistry *PR = PassRegistry::getPassRegistry();
  initializeRXExpandPseudoPass(*PR);
}

static StringRef computeDataLayout(const Triple &TT) {
  assert(TT.isArch32Bit() && "RX 32bit only");

  // e little-endian
  // m:e ELF mangling
  // p:32:32 32bit address space, 32-bit aligned
  // i32:32 i32 is 32-bit aligned
  // n32 native integer widths is 32-bit
  return "e-m:e-p:32:32-i32:32-n32";
}

static Reloc::Model getEffectiveRelocModel(const Triple &TT,
                                           Optional<Reloc::Model> RM) {
  if (!RM.hasValue())
    return Reloc::Static;
  return *RM;
}

RXTargetMachine::RXTargetMachine(const Target &T, const Triple &TT,
                                 StringRef CPU, StringRef FS,
                                 const TargetOptions &Options,
                                 Optional<Reloc::Model> RM,
                                 Optional<CodeModel::Model> CM,
                                 CodeGenOpt::Level OL, bool JIT)
    : LLVMTargetMachine(T, computeDataLayout(TT), TT, CPU, FS, Options,
                        getEffectiveRelocModel(TT, RM),
                        getEffectiveCodeModel(CM, CodeModel::Small), OL),
      TLOF(std::make_unique<RXELFTargetObjectFile>()),
      Subtarget(TT, CPU, FS, Options.MCOptions.getABIName(), *this) {
  initAsmInfo();
}

namespace {
class RXPassConfig : public TargetPassConfig {
public:
  RXPassConfig(RXTargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  RXTargetMachine &getRXTargetMachine() const {
    return getTM<RXTargetMachine>();
  }

  bool addInstSelector() override;
  void addPreEmitPass2() override;
};
}

TargetPassConfig *RXTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new RXPassConfig(*this, PM);
}

bool RXPassConfig::addInstSelector() {
  addPass(createRXISelDag(getRXTargetMachine()));

  return false;
}

void RXPassConfig::addPreEmitPass2() {
  // Schedule the expansion of AMOs at the last possible moment, avoiding the
  // possibility for other passes to break the requirements for forward
  // progress in the LR/SC block.
  addPass(createRXExpandPseudoPass());
}
