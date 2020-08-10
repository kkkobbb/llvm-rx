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

def SDT_RXBsr : SDTypeProfile<0, 1, [SDTCisVT<0, iPTR>]>;
def RXBsr : SDNode<"RXISD::BSR", SDT_RXBsr,
                   [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue, SDNPVariadic]>;

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

// アドレス (bsr用)
def bsrtarget : Operand<iPTR>;

// displacement 16
// dsp16の値の範囲は0-262140(18bit)だが、命令コードのビット表現では1/4して
// 2bit落とした16bitになる
// asmの記述では4の倍数のみ受け付ける
def dsp16 : Operand<i32>;

// 符号なし18bit整数 (dsp16用)
def imm18 : PatLeaf<(imm), [{ return isUInt<18>(N->getSExtValue()); }]>;

// 2オペランドで表現されるアドレス
def addr : ComplexPattern<iPTR, 2, "SelectAddr", [], [SDNPWantRoot]>;

// TODO RX用の記述 Operand


//===----------------------------------------------------------------------===//
// Instruction Formats
//===----------------------------------------------------------------------===//

include "RXInstrFormats.td"


//===----------------------------------------------------------------------===//
// Instructions
//===----------------------------------------------------------------------===//

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def NOP : RXInst1<(outs), (ins), "nop", []>;

// サブルーチン呼び出し
// 呼び出し先 16bit 24bit レジスタの3つの指定方法がある
let isCall = 1 in
def BSR : RXInst4<(outs), (ins bsrtarget:$addr), "bsr $addr", []>;
def : Pat<(RXBsr (i32 tglobaladdr:$addr)), (BSR tglobaladdr:$addr)>;
def : Pat<(RXBsr (i32 texternalsym:$addr)), (BSR texternalsym:$addr)>;

// サブルーチンからの復帰
let isBranch = 1, isTerminator = 1, isBarrier = 1, isReturn = 1 in
def RTS : RXInst1<(outs), (ins), "rts", [(RXRts)]>;

// 加算 i32 reg
let Constraints = "$rd = $src" in
def ADD_I32R : RXInst6<(outs GPR:$rd), (ins GPR:$src, i32imm:$imm),
                      "add #$imm, $rd",
                      [(set GPR:$rd, (add GPR:$src, timm:$imm))]>;

// 加算 reg reg reg
def ADD_RRR : RXInst3<(outs GPR:$rd), (ins GPR:$rs, GPR:$rs2),
                     "add $rs, $rs2, $rd",
                     [(set GPR:$rd, (add GPR:$rs, GPR:$rs2))]>;

// 減算 reg reg reg
def SUB_RRR : RXInst3<(outs GPR:$rd), (ins GPR:$rs, GPR:$rs2),
                     "sub $rs, $rs2, $rd",
                     [(set GPR:$rd, (sub GPR:$rs2, GPR:$rs))]>;

// AND reg reg reg
def AND_RRR : RXInst3<(outs GPR:$rd), (ins GPR:$rs, GPR:$rs2),
                     "and $rs, $rs2, $rd",
                     [(set GPR:$rd, (and GPR:$rs2, GPR:$rs))]>;

// OR reg reg reg
def OR_RRR : RXInst3<(outs GPR:$rd), (ins GPR:$rs, GPR:$rs2),
                    "or $rs, $rs2, $rd",
                    [(set GPR:$rd, (or GPR:$rs2, GPR:$rs))]>;

// XOR reg reg reg
def XOR_RRR : RXInst3<(outs GPR:$rd), (ins GPR:$rs, GPR:$rs2),
                     "xor $rs, $rs2, $rd",
                     [(set GPR:$rd, (xor GPR:$rs2, GPR:$rs))]>;

// move i32 reg
def MOV_I32R : RXInst6<(outs GPR:$rd), (ins i32imm:$imm),
                      "mov #$imm, $rd",
                      [(set GPR:$rd, imm:$imm)]>;

// move reg reg (long)
def MOVL_RR : RXInst2<(outs GPR:$rd), (ins GPR:$rs),
                     "mov.l $rs, $rd",
                     [(set GPR:$rd, GPR:$rs)]>;

// load (long)
def MOVL_pRR : RXInst2<(outs GPR:$rd), (ins GPR:$rs),
                      "mov.l [$rs], $rd",
                      [(set GPR:$rd, (load GPR:$rs))]>;

// store (long)
def MOVL_RpR : RXInst2<(outs), (ins GPR:$rd, GPR:$rs),
                      "mov.l $rs, [$rd]",
                      [(store GPR:$rs, GPR:$rd)]>;

// displacement load (long)
def MOVL_D16R : RXInst4<(outs GPR:$rd), (ins GPR:$rs, dsp16:$dsp),
                       "mov.l $dsp[$rs], $rd",
                       [(set GPR:$rd, (load (addr GPR:$rs, imm18:$dsp)))]>;

// displacement store (long)
def MOVL_RD16 : RXInst4<(outs), (ins GPR:$rs, GPR:$rd, dsp16:$dsp),
                       "mov.l $rs, $dsp[$rd]",
                       [(store GPR:$rs, (load (addr GPR:$rd, imm18:$dsp)))]>;

// pre decrement store (long)
// NOTE pre decrement 参考 AVR STPtrPdRr命令
let Constraints = "$ptrreg = $rd" in
def MOVL_dRR : RXInst3<(outs GPR:$ptrreg), (ins GPR:$rd, GPR:$rs),
                      "mov.l $rs, [-$rd]",
                      [(set i32:$ptrreg, (pre_store GPR:$rs, GPR:$rd, 4))]>;

// post increment load (long)
// NOTE post increment 参考 AVR LDRdPtrPi命令
let hasSideEffects = 0, mayLoad = 1, mayStore = 0,
    Constraints = "$ptrreg = $rs" in
def MOVL_RiR : RXInst3<(outs GPR:$rd, GPR:$ptrreg), (ins GPR:$rs),
                       "mov.l [${rs}+], $rd", []>;

let Defs = [R0], Uses = [R0] in {
// pop レジスタ
let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def POP : RXInst2<(outs GPR:$rd), (ins), "pop $rd", []>;

// push レジスタ
let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def PUSHL_R : RXInst2<(outs), (ins GPR:$rs), "push.l $rs", []>;
}

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