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

// 1byte format
class RXInst1<bits<8> opcode, dag outs, dag ins, string asmstr,
              list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<8> Inst;
  let Size = 1;
  let Inst = opcode;
}

// 3byte format
class RXInst3<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<24> Inst;
  let Size = 3;
}

// 6byte format
class RXInst6<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<48> Inst;
  let Size = 6;
}


// 3byte format <opcode addressing size Rx Ry>
// addressing mode 00:Ry,[Rx+] 01:Ry,[-Rx] 10:[+Rx],Ry 11:[-Rx],Ry
// size 00:B 01:W 02:L
// Rx/Ry 0000:R0 ... 1111:R15
class RXInst3_ad_sz_rr<bits<12> opcode, bits<2> addressing, bits<2> size,
                       dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst3<outs, ins, asmstr, pattern> {
  bits<4> rx;
  bits<4> ry;

  let Inst{23-12} = opcode;
  let Inst{10-11} = addressing;
  let Inst{9-8} = size;
  let Inst{7-4} = rx;
  let Inst{3-0} = ry;
}

// 6byte format <opcode Rx Ry imm:32>
// Rx/Ry 0000:R0 ... 1111:R15
// imm:32 32bit immediate
class RXInst6_rri32<bits<6> opcode, dag outs, dag ins,
                     string asmstr, list<dag> pattern>
    : RXInst6<outs, ins, asmstr, pattern> {
  bits<4> rx;
  bits<4> ry;
  bits<32> imm;

  let Inst{47-42} = opcode;
  let Inst{41-40} = 0b00;  // li imm:32
  let Inst{39-36} = rx;
  let Inst{35-32} = ry;
  let Inst{31-0} = imm;
}
