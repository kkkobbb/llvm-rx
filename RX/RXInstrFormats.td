//===-- RXInstrFormats.td - RX Instruction Formats -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// NOTE llvm/include/llvm/Target/Target.td Instruction

class RXInst<dag outs, dag ins, string asmstr, list<dag> pattern>
    : Instruction {
  let Namespace = "RX";

  let OutOperandList = outs;
  let InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;

  field bits<32> SoftFail = 0;
}

class RXInstPseudo<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  let isCodeGenOnly = 1;
  let isPseudo = 1;
}
