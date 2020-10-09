//===-- RXInstrFormats.td - RX Instruction Formats --------*- tablegen -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

class RXLd<bits<2> val> {
  bits<2> Value = val;
}
def LD_DIRECT   : RXLd<0b11>;
def LD_INDIRECT : RXLd<0b00>;
def LD_INDOFF8  : RXLd<0b01>;
def LD_INDOFF16 : RXLd<0b10>;

class RXSize<bits<2> val> {
  bits<2> Value = val;
}
def SIZE_B : RXSize<0b00>;
def SIZE_W : RXSize<0b01>;
def SIZE_L : RXSize<0b10>;

class RXCd<bits<4> val> {
  bits<4> Value = val;
}
def CD_BEQ  : RXCd<0b0000>;
def CD_BNE  : RXCd<0b0001>;
def CD_BGEU : RXCd<0b0010>;
def CD_BLTU : RXCd<0b0010>;
def CD_BGTU : RXCd<0b0011>;
def CD_BLEU : RXCd<0b0101>;
def CD_BPZ  : RXCd<0b0110>;
def CD_BN   : RXCd<0b0111>;
def CD_BGE  : RXCd<0b1000>;
def CD_BLT  : RXCd<0b1001>;
def CD_BGT  : RXCd<0b1010>;
def CD_BLE  : RXCd<0b1011>;
def CD_BO   : RXCd<0b1100>;
def CD_BNO  : RXCd<0b1101>;
def CD_BRAB : RXCd<0b1110>;


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
class RXInst1<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<8> Inst;
  let Size = 1;
}

class RXInst1_Op<bits<8> opcode, dag outs, dag ins, string asmstr,
                 list<dag> pattern>
    : RXInst1<outs, ins, asmstr, pattern> {
  let Inst = opcode;
}

// 2byte format
class RXInst2<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<16> Inst;
  let Size = 2;
}

class RXInst2_OpRs<bits<12> opcode, dag outs, dag ins, string asmstr,
                   list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rs;

  let Inst{15-4} = opcode;
  let Inst{3-0} = rs;
}

class RXInst2_OpRd<bits<12> opcode, dag outs, dag ins, string asmstr,
                   list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rd;

  let Inst{15-4} = opcode;
  let Inst{3-0} = rd;
}

class RXInst2_OpSzLdLdRsRd<RXSize size, RXLd ld1, RXLd ld2, dag outs, dag ins,
                           string asmstr, list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rs;
  bits<4> rd;

  let Inst{15-14} = 0b11;
  let Inst{13-12} = size.Value;
  let Inst{11-10} = ld1.Value;
  let Inst{9-8} = ld2.Value;
  let Inst{7-4} = rs;
  let Inst{3-0} = rd;
}

class RXInst2_OpSzLdLdRdRs<RXSize size, RXLd ld1, RXLd ld2, dag outs, dag ins,
                           string asmstr, list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rs;
  bits<4> rd;

  let Inst{15-14} = 0b11;
  let Inst{13-12} = size.Value;
  let Inst{11-10} = ld1.Value;
  let Inst{9-8} = ld2.Value;
  let Inst{7-4} = rd;
  let Inst{3-0} = rs;
}

class RXInst2_OpSzRs<bits<10> opcode, RXSize size, dag outs, dag ins,
                     string asmstr, list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rs;

  let Inst{15-6} = opcode;
  let Inst{5-4} = size.Value;
  let Inst{3-0} = rs;
}

class RXInst2_OpLdRsRs<bits<6> opcode, RXLd ld, dag outs, dag ins,
                     string asmstr, list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rs1;
  bits<4> rs2;

  let Inst{15-10} = opcode;
  let Inst{9-8} = ld.Value;
  let Inst{7-4} = rs1;
  let Inst{3-0} = rs2;
}

class RXInst2_OpUi4Rs<bits<8> opcode, dag outs, dag ins,
                     string asmstr, list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rs;
  bits<4> imm;

  let Inst{15-8} = opcode;
  let Inst{7-4} = imm;
  let Inst{3-0} = rs;
}

class RXInst2_OpCdDsp<RXCd cd, dag outs, dag ins, string asmstr,
                      list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<8> dsp;

  let Inst{15-12} = 0b0010;
  let Inst{11-8} = cd.Value;
  let Inst{7-0} = dsp;
}

// 3byte format
class RXInst3<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<24> Inst;
  let Size = 3;
}

// 4byte format
class RXInst4<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<32> Inst;
  let Size = 4;
}

// 5byte format
class RXInst5<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<40> Inst;
  let Size = 5;
}

// 6byte format
class RXInst6<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<48> Inst;
  let Size = 6;
}

// 7byte format
class RXInst7<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<56> Inst;
  let Size = 7;
}

// 8byte format
class RXInst8<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<64> Inst;
  let Size = 8;
}
