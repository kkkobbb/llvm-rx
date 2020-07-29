//===-- RXInstrInfo.td - Target Description for RX --------*- tablegen -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the RX instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// RX specific DAG Nodes.
//===----------------------------------------------------------------------===//

// NOTE llvm/include/llvm/CodeGen/SDNodeProperties.td SDNP*

def RXRts : SDNode<"RXISD::RTS", SDTNone,
                   [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// TODO RX用の記述 DAG Node

// Target-independent type requirements, but with target-specific formats.
def SDT_CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;
def SDT_CallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;
// Target-independent nodes, but with target-specific formats.
def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_CallSeqStart,
                           [SDNPHasChain, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END", SDT_CallSeqEnd,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;


//===----------------------------------------------------------------------===//
// Operand and SDNode transformation definitions.
//===----------------------------------------------------------------------===//

// displacement 16
// dsp16の値の範囲は0-262140(18bit)だが、命令のビット表現では1/4して
// 2bit落とした16bitになる
// asmの記述では4の倍数のみ受け付ける
def dsp16 : Operand<i32>;

// 符号なし18bit整数 (dsp16用)
def imm18 : PatLeaf<(imm), [{ return isUInt<18>(N->getSExtValue()); }]>;

// TODO RX用の記述 Operand


//===----------------------------------------------------------------------===//
// Instruction Formats
//===----------------------------------------------------------------------===//

include "RXInstrFormats.td"


//===----------------------------------------------------------------------===//
// Instructions
//===----------------------------------------------------------------------===//

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def NOP : RXInst1<0b00000011, (outs), (ins), "nop", []>;

// サブルーチンからの復帰
let isBranch = 1, isTerminator = 1, isBarrier = 1, isReturn = 1 in
def RTS : RXInst1<0b00000010, (outs), (ins), "rts", [(RXRts)]>;

// 加算 2オペランド レジスタ 32bit即値
let Constraints = "$rd = $src" in
def ADD_RI32 : RXInst6_rri32<0b011100,
                             (outs GPR:$rd), (ins GPR:$src, i32imm:$imm),
                             "add #$imm, $rd",
                             [(set GPR:$rd, (add GPR:$src, timm:$imm))]>;

// 加算 3オペランド レジスタ レジスタ レジスタ
def ADD_RRR : RXInst3_rrr<0b111111110010,
                          (outs GPR:$rd), (ins GPR:$rs, GPR:$rs2),
                          "add $rd, $rs, $rs2",
                          [(set GPR:$rd, (add GPR:$rs, GPR:$rs2))]>;

// move reg reg (long)
def MOVL_RR : RXInst2_sz_rr<0b11, 0b10, 0b1111,
                            (outs GPR:$rd), (ins GPR:$rs),
                            "mov.l $rs, $rd",
                            [(set GPR:$rd, GPR:$rs)]>;

// pre decrement store (long)
// NOTE 参考 AVR STPtrPdRr命令
let Constraints = "$ptrreg = $rd" in
def MOVL_dRR : RXInst3_ad_sz_rr<0b111111010010, 0b01, 0b10,
                                (outs GPR:$ptrreg), (ins GPR:$rd, GPR:$rs),
                                "mov.l $rs, [-$rd]",
                                [(set i32:$ptrreg,
                                 (pre_store GPR:$rs, GPR:$rd, 4))]>;

// post increment load (long)
// NOTE 参考 AVR LDRdPtrPi命令
let hasSideEffects = 0, mayLoad = 1, mayStore = 0,
    Constraints = "$ptrreg = $rs" in
def MOVL_RiR : RXInst3_ad_sz_rr<0b111111010010, 0b10, 0b10,
                                (outs GPR:$rd, GPR:$ptrreg), (ins GPR:$rs),
                                "mov.l [${rs}+], $rd", []>;

// displacement store (long)
def MOVL_RD16 : RXInst4_mov_r_dsp<0b10,
                                  (outs), (ins GPR:$rs, GPR:$rd, dsp16:$dsp),
                                  "mov.l $rs, $dsp[$rd]",
                                  [(store GPR:$rs,
                                          (load (add GPR:$rd, imm18:$dsp)))]>;

// displacement load (long)
def MOVL_D16R : RXInst4_mov_dsp_r<0b10,
                                  (outs GPR:$rd), (ins GPR:$rs, dsp16:$dsp),
                                  "mov.l $dsp[$rs], $rd",
                                  [(set GPR:$rd,
                                        (load (add GPR:$rs, imm18:$dsp)))]>;

// push レジスタ
let Defs = [R0], Uses = [R0],
    hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def PUSHL_R : RXInst2_sz_r<0b0111111010, 0b10,
                           (outs), (ins GPR:$rs),
                           "push.l $rs", []>;

// pop レジスタ
let Defs = [R0], Uses = [R0],
    hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def POP : RXInst2_r<0b011111101011,
                    (outs GPR:$rd), (ins),
                    "pop $rd", []>;

// TODO RX用の記述 Instruction


// Callの開始終了を表す疑似命令
let Defs = [R0], Uses = [R0] in {
def ADJCALLSTACKDOWN : RXInstPseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                                    "!ADJCALLSTACKDOWN $amt1",
                                    [(callseq_start timm:$amt1, timm:$amt2)]>;
def ADJCALLSTACKUP   : RXInstPseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                                    "!ADJCALLSTACKUP $amt1",
                                    [(callseq_end timm:$amt1, timm:$amt2)]>;
}
