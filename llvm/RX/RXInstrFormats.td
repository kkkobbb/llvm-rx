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
def LD_INDDSP8  : RXLd<0b01>;
def LD_INDDSP16 : RXLd<0b10>;

class RXLi<bits<2> val> {
  bits<2> Value = val;
}
def LI_SIMM8  : RXLi<0b01>;
def LI_SIMM16 : RXLi<0b10>;
def LI_SIMM24 : RXLi<0b11>;
def LI_IMM32  : RXLi<0b00>;

class RXSize<bits<2> val> {
  bits<2> Value = val;
}
def SIZE_B : RXSize<0b00>;
def SIZE_W : RXSize<0b01>;
def SIZE_L : RXSize<0b10>;

class RXSize1<bits<1> val> {
  bits<1> Value = val;
}
def SIZE1_B : RXSize1<0b0>;
def SIZE1_W : RXSize1<0b1>;

class RXCd<bits<4> val> {
  bits<4> Value = val;
}
def CD_BEQ  : RXCd<0b0000>;
def CD_BNE  : RXCd<0b0001>;
def CD_BGEU : RXCd<0b0010>;
def CD_BLTU : RXCd<0b0011>;
def CD_BGTU : RXCd<0b0100>;
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

  // ビット長は命令長の最大以上であればいいっぽい
  field bits<64> SoftFail = 0;
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

class I1_Op<bits<8> opcode, dag outs, dag ins, string asmstr,
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

class I2_OpRs<bits<12> opcode, dag outs, dag ins, string asmstr,
                   list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rs;

  let Inst{15-4} = opcode;
  let Inst{3-0} = rs;
}

class I2_OpRd<bits<12> opcode, dag outs, dag ins, string asmstr,
                   list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rd;

  let Inst{15-4} = opcode;
  let Inst{3-0} = rd;
}

class I2_OpSzLdLdRsRd<RXSize size, RXLd ld1, RXLd ld2, dag outs, dag ins,
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

class I2_OpSzLdLdRdRs<RXSize size, RXLd ld1, RXLd ld2, dag outs, dag ins,
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

class I2_OpSzRs<bits<10> opcode, RXSize size, dag outs, dag ins,
                     string asmstr, list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rs;

  let Inst{15-6} = opcode;
  let Inst{5-4} = size.Value;
  let Inst{3-0} = rs;
}

class I2_OpLdRsRs<bits<6> opcode, RXLd ld, dag outs, dag ins,
                     string asmstr, list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rs1;
  bits<4> rs2;

  let Inst{15-10} = opcode;
  let Inst{9-8} = ld.Value;
  let Inst{7-4} = rs1;
  let Inst{3-0} = rs2;
}

class I2_OpUi4Rs<bits<8> opcode, dag outs, dag ins,
                     string asmstr, list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rs;
  bits<4> imm;

  let Inst{15-8} = opcode;
  let Inst{7-4} = imm;
  let Inst{3-0} = rs;
}

class I2_OpCdDsp<RXCd cd, dag outs, dag ins, string asmstr,
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

class I3_OpRdRsRs<bits<12> opcode, dag outs, dag ins, string asmstr,
                       list<dag> pattern>
    : RXInst3<outs, ins, asmstr, pattern> {
  bits<4> rd;
  bits<4> rs;
  bits<4> rs2;

  let Inst{23-12} = opcode;
  let Inst{11-8} = rd;
  let Inst{7-4} = rs;
  let Inst{3-0} = rs2;
}

class I3_OpLdRsRd<bits<14> opcode, RXLd ld, dag outs, dag ins,
                       string asmstr, list<dag> pattern>
    : RXInst3<outs, ins, asmstr, pattern> {
  bits<4> rs;
  bits<4> rd;

  let Inst{23-10} = opcode;
  let Inst{9-8} = ld.Value;
  let Inst{7-4} = rs;
  let Inst{3-0} = rd;
}

class I3_OpI5RsRd<bits<11> opcode, dag outs, dag ins, string asmstr,
                       list<dag> pattern>
    : RXInst3<outs, ins, asmstr, pattern> {
  bits<5> imm;
  bits<4> rs;
  bits<4> rd;

  let Inst{23-13} = opcode;
  let Inst{12-8} = imm;
  let Inst{7-4} = rs;
  let Inst{3-0} = rd;
}

class I3_OpRsRd<bits<16> opcode, dag outs, dag ins, string asmstr,
                       list<dag> pattern>
    : RXInst3<outs, ins, asmstr, pattern> {
  bits<4> rs;
  bits<4> rd;

  let Inst{23-8} = opcode;
  let Inst{7-4} = rs;
  let Inst{3-0} = rd;
}

// 4byte format
class RXInst4<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<32> Inst;
  let Size = 4;
}

class I4_OpPcdsp<bits<8> opcode, dag outs, dag ins, string asmstr,
                      list<dag> pattern>
    : RXInst4<outs, ins, asmstr, pattern> {
  field bits<24> pcdsp;

  let Inst{31-24} = opcode;
  let Inst{23-0} = pcdsp;
}

class I4_OpSzLdRsRdD16<RXSize size, dag outs, dag ins,
                            string asmstr, list<dag> pattern>
    : RXInst4<outs, ins, asmstr, pattern> {
  field bits<4> rs;
  field bits<4> rd;
  field bits<16> dsp;

  let Inst{31-30} = 0b11;
  let Inst{29-28} = size.Value;
  let Inst{27-26} = 0b11;
  let Inst{25-24} = LD_INDDSP16.Value;
  let Inst{23-20} = rs;
  let Inst{19-16} = rd;
  let Inst{15-0} = dsp;
}

class I4_OpSzLdRdRsD16<RXSize size, dag outs, dag ins,
                            string asmstr, list<dag> pattern>
    : RXInst4<outs, ins, asmstr, pattern> {
  field bits<4> rd;
  field bits<4> rs;
  field bits<16> dsp;

  let Inst{31-30} = 0b11;
  let Inst{29-28} = size.Value;
  let Inst{27-26} = LD_INDDSP16.Value;
  let Inst{25-24} = 0b11;
  let Inst{23-20} = rd;
  let Inst{19-16} = rs;
  let Inst{15-0} = dsp;
}

class I4_OpSLdRsRdD16<bits<5> opcode, RXSize1 size, dag outs, dag ins,
                           string asmstr, list<dag> pattern>
    : RXInst4<outs, ins, asmstr, pattern> {
  field bits<4> rs;
  field bits<4> rd;
  field bits<16> dsp;

  let Inst{31-27} = opcode;
  let Inst{26} = size.Value;
  let Inst{25-24} = LD_INDDSP16.Value;
  let Inst{23-20} = rs;
  let Inst{19-16} = rd;
  let Inst{15-0} = dsp;
}

// 5byte format
class RXInst5<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<40> Inst;
  let Size = 5;
}

class I5_OpLdRdLiSzD16I8<bits<6> opcode, RXSize size, dag outs, dag ins,
                         string asmstr, list<dag> pattern>
    : RXInst5<outs, ins, asmstr, pattern> {
  field bits<4> rd;
  field bits<16> dsp;
  field bits<8> imm;

  let Inst{39-34} = opcode;
  let Inst{33-32} = LD_INDDSP16.Value;
  let Inst{31-28} = rd;
  let Inst{27-26} = LI_SIMM8.Value;
  let Inst{25-24} = size.Value;
  let Inst{23-8} = dsp;
  let Inst{7-0} = imm;
}

// 6byte format
class RXInst6<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<48> Inst;
  let Size = 6;
}

class I6_OpLiRsRdI32<bits<6> opcode, dag outs, dag ins, string asmstr,
                     list<dag> pattern>
    : RXInst6<outs, ins, asmstr, pattern> {
  field bits<4> rs;
  field bits<4> rd;
  field bits<32> imm;

  let Inst{47-42} = opcode;
  let Inst{41-40} = LI_IMM32.Value;
  let Inst{39-36} = rs;
  let Inst{35-32} = rd;
  let Inst{31-0} = imm;
}

class I6_OpRdLiI32<bits<8> opcode, dag outs, dag ins, string asmstr,
                   list<dag> pattern>
    : RXInst6<outs, ins, asmstr, pattern> {
  field bits<4> rd;
  field bits<32> imm;

  let Inst{47-40} = opcode;
  let Inst{39-36} = rd;
  let Inst{35-34} = LI_IMM32.Value;
  let Inst{33-32} = 0b10;
  let Inst{31-0} = imm;
}

class I6_OpLdRdLiSzD16I16<bits<6> opcode, RXSize size, dag outs, dag ins,
                          string asmstr, list<dag> pattern>
    : RXInst6<outs, ins, asmstr, pattern> {
  field bits<4> rd;
  field bits<16> dsp;
  field bits<16> imm;

  let Inst{47-42} = opcode;
  let Inst{41-40} = LD_INDDSP16.Value;
  let Inst{39-36} = rd;
  let Inst{35-34} = LI_SIMM16.Value;
  let Inst{33-32} = size.Value;
  let Inst{31-16} = dsp;
  let Inst{15-0} = imm;
}

class I6_OpLiRsI32<bits<6> opcode, dag outs, dag ins, string asmstr,
                   list<dag> pattern>
    : RXInst6<outs, ins, asmstr, pattern> {
  field bits<4> rs;
  field bits<32> imm;

  let Inst{47-42} = opcode;
  let Inst{41-40} = LI_IMM32.Value;
  let Inst{39-36} = 0b0000;
  let Inst{35-32} = rs;
  let Inst{31-0} = imm;
}

// 7byte format
class RXInst7<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<56> Inst;
  let Size = 7;
}

class I7_OpLiRdI32<bits<12> opcode, dag outs, dag ins, string asmstr,
                   list<dag> pattern>
    : RXInst7<outs, ins, asmstr, pattern> {
  field bits<4> rd;
  field bits<32> imm;

  let Inst{55-44} = opcode;
  let Inst{43-42} = LI_IMM32.Value;
  let Inst{41-36} = 0b000110;
  let Inst{35-32} = rd;
  let Inst{31-0} = imm;
}

// 8byte format
class RXInst8<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<64> Inst;
  let Size = 8;
}

class I8_OpLdRdLiSzD16I32<bits<6> opcode, RXSize size, dag outs, dag ins,
                          string asmstr, list<dag> pattern>
    : RXInst8<outs, ins, asmstr, pattern> {
  field bits<4> rd;
  field bits<16> dsp;
  field bits<32> imm;

  let Inst{63-58} = opcode;
  let Inst{57-56} = LD_INDDSP16.Value;
  let Inst{55-52} = rd;
  let Inst{51-50} = LI_IMM32.Value;
  let Inst{49-48} = size.Value;
  let Inst{47-32} = dsp;
  let Inst{31-0} = imm;
}
