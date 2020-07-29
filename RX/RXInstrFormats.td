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

// 2byte format
class RXInst2<dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst<outs, ins, asmstr, pattern> {
  field bits<16> Inst;
  let Size = 2;
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


// 2byte format <opcode1 size opcode2 Rx Ry>
// size 00:B 01:W 02:L
// Rx/Ry 0000:R0 ... 1111:R15
class RXInst2_sz_rr<bits<2> opcode1, bits<2> size, bits<4> opcode2,
                    dag outs, dag ins, string asmstr, list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rx;
  bits<4> ry;

  let Inst{15-14} = opcode1;
  let Inst{13-12} = size;
  let Inst{11-8} = opcode2;
  let Inst{7-4} = rx;
  let Inst{3-0} = ry;
}

// 2byte format <opcode size Rs>
// size 00:B 01:W 02:L
// Rs 0000:R0 ... 1111:R15
class RXInst2_sz_r<bits<10> opcode, bits<2> size, dag outs, dag ins,
                   string asmstr, list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rs;

  let Inst{15-6} = opcode;
  let Inst{5-4} = size;
  let Inst{3-0} = rs;
}

// 2byte format <opcode Rd>
// Rd 0000:R0 ... 1111:R15
class RXInst2_r<bits<12> opcode, dag outs, dag ins,
                string asmstr, list<dag> pattern>
    : RXInst2<outs, ins, asmstr, pattern> {
  bits<4> rd;

  let Inst{15-4} = opcode;
  let Inst{3-0} = rd;
}

// 3byte format <opcode addressing size Rx Ry>
// addressing mode 00:Ry,[Rx+] 01:Ry,[-Rx] 10:[+Rx],Ry 11:[-Rx],Ry
// size 00:B 01:W 10:L
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

// 3byte format <opcode Rx Ry Rz>
// Rx/Ry/Rz 0000:R0 ... 1111:R15
class RXInst3_rrr<bits<12> opcode, dag outs, dag ins, string asmstr,
                  list<dag> pattern>
    : RXInst3<outs, ins, asmstr, pattern> {
  bits<4> rx;
  bits<4> ry;
  bits<4> rz;

  let Inst{23-12} = opcode;
  let Inst{11-8} = rx;
  let Inst{7-4} = ry;
  let Inst{3-0} = rz;
}

// 4byte format <opcode size Rs Rd>
// size 00:B 01:W 10:L
// Rs/Rd 0000:R0 ... 1111:R15
class RXInst4_mov_dsp_r<bits<2> size, dag outs, dag ins, string asmstr,
                        list<dag> pattern>
    : RXInst4<outs, ins, asmstr, pattern> {
  bits<4> rd;
  bits<4> rs;
  bits<18> dsp;

  let Inst{31-30} = 0b11;
  let Inst{29-28} = size;
  let Inst{27-26} = 0b11;
  let Inst{25-24} = 0b10;
  let Inst{23-20} = rs;
  let Inst{19-16} = rd;
  let Inst{15-0} = dsp{17-2};
}

// 4byte format <opcode size Rd Rs>
// size 00:B 01:W 10:L
// Rs/Rd 0000:R0 ... 1111:R15
class RXInst4_mov_r_dsp<bits<2> size, dag outs, dag ins, string asmstr,
                        list<dag> pattern>
    : RXInst4<outs, ins, asmstr, pattern> {
  bits<4> rd;
  bits<4> rs;
  bits<18> dsp;

  let Inst{31-30} = 0b11;
  let Inst{29-28} = size;
  let Inst{27-26} = 0b10;
  let Inst{25-24} = 0b11;
  let Inst{23-20} = rd;
  let Inst{19-16} = rs;
  let Inst{15-0} = dsp{17-2};
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
