//===--- RX.h - Declare RX target feature support ---------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares RX TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_BASIC_TARGETS_RX_H
#define LLVM_CLANG_LIB_BASIC_TARGETS_RX_H

#include "clang/Basic/TargetInfo.h"
#include "clang/Basic/TargetOptions.h"
#include "llvm/ADT/Triple.h"
#include "llvm/Support/Compiler.h"

namespace clang {
namespace targets {

// RX Target
class RXTargetInfo : public TargetInfo {
public:
  RXTargetInfo(const llvm::Triple &Triple, const TargetOptions &)
      : TargetInfo(Triple) {
    // TODO RISCVのまま
    LongDoubleWidth = 128;
    LongDoubleAlign = 128;
    LongDoubleFormat = &llvm::APFloat::IEEEquad();
    SuitableAlign = 128;
    WCharType = SignedInt;
    WIntType = UnsignedInt;
  }

  // NOTE clang/include/clang/Basic/TargetInfo.h overrideが必要
  // NOTE ターゲット固有のdefine (識別用?)
  void getTargetDefines(const LangOptions &Opts,
                        MacroBuilder &Builder) const override;

  // NOTE clang/include/clang/Basic/TargetInfo.h overrideが必要
  ArrayRef<Builtin::Info> getTargetBuiltins() const override { return None; }

  // NOTE clang/include/clang/Basic/TargetInfo.h overrideが必要
  BuiltinVaListKind getBuiltinVaListKind() const override {
    return TargetInfo::VoidPtrBuiltinVaList;
  }

  // NOTE clang/include/clang/Basic/TargetInfo.h overrideが必要
  const char *getClobbers() const override { return ""; }

  // NOTE clang/include/clang/Basic/TargetInfo.h overrideが必要
  // NOTE レジスタ名
  ArrayRef<const char *> getGCCRegNames() const override;

  // NOTE clang/include/clang/Basic/TargetInfo.h overrideが必要
  // NOTE レジスタ名の別名
  ArrayRef<TargetInfo::GCCRegAlias> getGCCRegAliases() const override;

  // NOTE clang/include/clang/Basic/TargetInfo.h overrideが必要
  bool validateAsmConstraint(const char *&Name,
                             TargetInfo::ConstraintInfo &Info) const override;
};
class LLVM_LIBRARY_VISIBILITY RXv1TargetInfo : public RXTargetInfo {
public:
  RXv1TargetInfo(const llvm::Triple &Triple, const TargetOptions &Opts)
      : RXTargetInfo(Triple, Opts) {
    IntPtrType = SignedInt;
    PtrDiffType = SignedInt;
    SizeType = UnsignedInt;
    resetDataLayout("e-m:e-p:32:32-i32:32-n32");
  }
};
} // namespace targets
} // namespace clang

#endif // LLVM_CLANG_LIB_BASIC_TARGETS_RX_H
