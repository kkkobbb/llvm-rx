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

// NOTE SDTypeProfile<出力の数, 入力の数, [入力の制約, ...]>
// NOTE SDNode<命令, 制約条件, プロパティ(SDNP*)>
// NOTE llvm/include/llvm/CodeGen/SDNodeProperties.td SDNP*

def SDT_RXBsr : SDTypeProfile<0, 1, [SDTCisVT<0, iPTR>]>;
def RXBsr : SDNode<"RXISD::BSR", SDT_RXBsr,
                   [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue, SDNPVariadic]>;

def RXRts : SDNode<"RXISD::RTS", SDTNone,
                   [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

def SDT_RXCmp : SDTypeProfile<0, 2, [SDTCisSameAs<0, 1>]>;
def RXCmp : SDNode<"RXISD::CMP", SDT_RXCmp, [SDNPOutGlue]>;

def SDT_RXBr : SDTypeProfile<0, 1, [SDTCisVT<0, OtherVT>]>;
def RXBeq  : SDNode<"RXISD::BEQ",  SDT_RXBr, [SDNPHasChain, SDNPInGlue]>;
def RXBne  : SDNode<"RXISD::BNE",  SDT_RXBr, [SDNPHasChain, SDNPInGlue]>;
def RXBge  : SDNode<"RXISD::BGE",  SDT_RXBr, [SDNPHasChain, SDNPInGlue]>;
def RXBle  : SDNode<"RXISD::BLE",  SDT_RXBr, [SDNPHasChain, SDNPInGlue]>;
def RXBgt  : SDNode<"RXISD::BGT",  SDT_RXBr, [SDNPHasChain, SDNPInGlue]>;
def RXBlt  : SDNode<"RXISD::BLT",  SDT_RXBr, [SDNPHasChain, SDNPInGlue]>;
def RXBgeu : SDNode<"RXISD::BGEU", SDT_RXBr, [SDNPHasChain, SDNPInGlue]>;
def RXBleu : SDNode<"RXISD::BLEU", SDT_RXBr, [SDNPHasChain, SDNPInGlue]>;
def RXBgtu : SDNode<"RXISD::BGTU", SDT_RXBr, [SDNPHasChain, SDNPInGlue]>;
def RXBltu : SDNode<"RXISD::BLTU", SDT_RXBr, [SDNPHasChain, SDNPInGlue]>;

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

// アドレス (BasicBlock用)
def brtarget : Operand<OtherVT>;

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

// NOTE パターンに現れるsetはノードではなく出力レジスタを表現するための記述のため、Pat<>には記述する必要がない(できない?)

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def NOP : RXInst1<(outs), (ins), "nop", []>;

// 相対サブルーチン分岐 pcdsp:24
let isCall = 1 in
def BSRA : RXInst4<(outs), (ins bsrtarget:$addr), "bsr $addr", []>;
def : Pat<(RXBsr (i32 tglobaladdr:$addr)), (BSRA tglobaladdr:$addr)>;
def : Pat<(RXBsr (i32 texternalsym:$addr)), (BSRA texternalsym:$addr)>;

// サブルーチンからの復帰
let isBranch = 1, isTerminator = 1, isBarrier = 1, isReturn = 1 in
def RTS : RXInst1<(outs), (ins), "rts", [(RXRts)]>;

// 加算 i32 reg reg
def ADD_I32RR : RXInst6<(outs GPR:$rd), (ins GPR:$rs, i32imm:$imm),
                        "add #$imm, $rs, $rd",
                        [(set GPR:$rd, (add GPR:$rs, imm:$imm))]>;

// 加算 reg reg reg
def ADD_RRR : RXInst3<(outs GPR:$rd), (ins GPR:$rs, GPR:$rs2),
                      "add $rs, $rs2, $rd",
                      [(set GPR:$rd, (add GPR:$rs, GPR:$rs2))]>;

// 減算 reg reg reg
def SUB_RRR : RXInst3<(outs GPR:$rd), (ins GPR:$rs, GPR:$rs2),
                      "sub $rs, $rs2, $rd",
                      [(set GPR:$rd, (sub GPR:$rs2, GPR:$rs))]>;

// 乗算 reg reg reg
def MUL_RRR : RXInst3<(outs GPR:$rd), (ins GPR:$rs, GPR:$rs2),
                      "mul $rs, $rs2, $rd",
                      [(set GPR:$rd, (mul GPR:$rs, GPR:$rs2))]>;

// 符号付き除算 reg reg
let Constraints = "$rd = $src" in
def DIV_RR : RXInst3<(outs GPR:$rd), (ins GPR:$src, GPR:$rs),
                     "div $rs, $rd",
                     [(set GPR:$rd, (sdiv GPR:$src, GPR:$rs))]>;

// 符号なし除算 reg reg
let Constraints = "$rd = $src" in
def DIVU_RR : RXInst3<(outs GPR:$rd), (ins GPR:$src, GPR:$rs),
                      "divu $rs, $rd",
                      [(set GPR:$rd, (udiv GPR:$src, GPR:$rs))]>;

// 絶対値 reg reg
def ABS_RR : RXInst3<(outs GPR:$rd), (ins GPR:$rs),
                     "abs $rs, $rd",
                     [(set GPR:$rd, (abs GPR:$rs))]>;

let Constraints = "$rd = $src" in {
// 最大値選択 reg reg
def MAX_RR : RXInst3<(outs GPR:$rd), (ins GPR:$src, GPR:$rs),
                     "max $rs, $rd",
                     [(set GPR:$rd, (smax GPR:$src, GPR:$rs))]>;

// 最小値選択 reg reg
def MIN_RR : RXInst3<(outs GPR:$rd), (ins GPR:$src, GPR:$rs),
                     "min $rs, $rd",
                     [(set GPR:$rd, (smin GPR:$src, GPR:$rs))]>;
}

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

let Constraints = "$rd = $src" in {
// 算術右シフト reg reg
def SHAR_RR : RXInst3<(outs GPR:$rd), (ins GPR:$src, GPR:$rs),
                      "shar $rs, $rd",
                      [(set GPR:$rd, (sra GPR:$src, GPR:$rs))]>;

// 算術左シフト reg reg
def SHLL_RR : RXInst3<(outs GPR:$rd), (ins GPR:$src, GPR:$rs),
                      "shll $rs, $rd",
                      [(set GPR:$rd, (shl GPR:$src, GPR:$rs))]>;

// 論理右シフト reg reg
def SHLR_RR : RXInst3<(outs GPR:$rd), (ins GPR:$src, GPR:$rs),
                      "shlr $rs, $rd",
                      [(set GPR:$rd, (srl GPR:$src, GPR:$rs))]>;

// 左回転 reg reg
def ROTL_RR : RXInst3<(outs GPR:$rd), (ins GPR:$src, GPR:$rs),
                      "rotl $rs, $rd",
                      [(set GPR:$rd, (rotl GPR:$src, GPR:$rs))]>;

// 右回転 reg reg
def ROTR_RR : RXInst3<(outs GPR:$rd), (ins GPR:$src, GPR:$rs),
                      "rotr $rs, $rd",
                      [(set GPR:$rd, (rotr GPR:$src, GPR:$rs))]>;
}

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

// NOTE *extload* 上位ビット拡張ロード
// displacement load (byte)
def MOVB_D16R : RXInst4<(outs GPR:$rd), (ins GPR:$rs, dsp16:$dsp),
                        "mov.b $dsp[$rs], $rd",
                        [(set GPR:$rd, (sextloadi8 (addr GPR:$rs, imm18:$dsp)))]>;
def : Pat<(extloadi8 (addr GPR:$rs, imm18:$dsp)), (MOVB_D16R GPR:$rs, imm18:$dsp)>;

// displacement load (word)
def MOVW_D16R : RXInst4<(outs GPR:$rd), (ins GPR:$rs, dsp16:$dsp),
                        "mov.w $dsp[$rs], $rd",
                        [(set GPR:$rd, (sextloadi16 (addr GPR:$rs, imm18:$dsp)))]>;
def : Pat<(extloadi16 (addr GPR:$rs, imm18:$dsp)), (MOVW_D16R GPR:$rs, imm18:$dsp)>;

// displacement load (long)
def MOVL_D16R : RXInst4<(outs GPR:$rd), (ins GPR:$rs, dsp16:$dsp),
                        "mov.l $dsp[$rs], $rd",
                        [(set GPR:$rd, (load (addr GPR:$rs, imm18:$dsp)))]>;

// NOTE truncstore* 上位ビット切り捨てストア
// displacement store (byte)
def MOVB_RD16 : RXInst4<(outs), (ins GPR:$rs, GPR:$rd, dsp16:$dsp),
                        "mov.b $rs, $dsp[$rd]",
                        [(truncstorei8 GPR:$rs, (addr GPR:$rd, imm18:$dsp))]>;

// displacement store (word)
def MOVW_RD16 : RXInst4<(outs), (ins GPR:$rs, GPR:$rd, dsp16:$dsp),
                        "mov.w $rs, $dsp[$rd]",
                        [(truncstorei16 GPR:$rs, (addr GPR:$rd, imm18:$dsp))]>;

// displacement store (long)
def MOVL_RD16 : RXInst4<(outs), (ins GPR:$rs, GPR:$rd, dsp16:$dsp),
                        "mov.l $rs, $dsp[$rd]",
                        [(store GPR:$rs, (addr GPR:$rd, imm18:$dsp))]>;

// displacement store i8
// insにi32immがあるが、asm変換時に上位ビットを切り捨てて8bitにする
def MOVB_I8D16 : RXInst6<(outs), (ins i32imm:$imm, GPR:$rd, dsp16:$dsp),
                         "mov.b #${imm}:8, $dsp[$rd]",
                         [(truncstorei8 imm:$imm, (addr GPR:$rd, imm18:$dsp))]>;

// displacement store i16
def MOVW_I16D16 : RXInst6<(outs), (ins i32imm:$imm, GPR:$rd, dsp16:$dsp),
                          "mov.w #${imm}:16, $dsp[$rd]",
                          [(truncstorei16 imm:$imm, (addr GPR:$rd, imm18:$dsp))]>;

// displacement store i32
def MOVL_I32D16 : RXInst8<(outs), (ins i32imm:$imm, GPR:$rd, dsp16:$dsp),
                          "mov.l #$imm, $dsp[$rd]",
                          [(store imm:$imm, (addr GPR:$rd, imm18:$dsp))]>;

// displacement load unsigned (byte)
def MOVUB_D16R : RXInst4<(outs GPR:$rd), (ins GPR:$rs, dsp16:$dsp),
                        "movu.b $dsp[$rs], $rd",
                        [(set GPR:$rd, (zextloadi8 (addr GPR:$rs, imm18:$dsp)))]>;

// displacement load unsigned (word)
def MOVUW_D16R : RXInst4<(outs GPR:$rd), (ins GPR:$rs, dsp16:$dsp),
                        "movu.w $dsp[$rs], $rd",
                        [(set GPR:$rd, (zextloadi16 (addr GPR:$rs, imm18:$dsp)))]>;

let Defs = [R0], Uses = [R0] in {
// NOTE 未使用
// pop レジスタ
let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def POP : RXInst2<(outs GPR:$rd), (ins), "pop $rd", []>;

// NOTE 未使用
// push レジスタ
let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def PUSHL_R : RXInst2<(outs), (ins GPR:$rs), "push.l $rs", []>;
}

// 比較
let hasSideEffects = 1, mayLoad = 0, mayStore = 0 in {
def CMP_RR : RXInst2<(outs), (ins GPR:$rs, GPR:$rs2),
                     "cmp $rs, $rs2",
                     [(RXCmp GPR:$rs, GPR:$rs2)]>;

def CMP_I32R : RXInst6<(outs), (ins i32imm:$imm, GPR:$rs),
                       "cmp $imm, $rs",
                       [(RXCmp imm:$imm, GPR:$rs)]>;
}

// 相対条件分岐
let hasSideEffects = 0, mayLoad = 0, mayStore = 0,
    isBranch = 1, isTerminator = 1 in
class Branch_W<string asmstr, SDNode OpNode>
    : RXInst3<(outs), (ins brtarget:$target),
              !strconcat(asmstr, " $target"),
              [(OpNode bb:$target)]>;
def BEQ  : Branch_W<"beq",  RXBeq>;   // ==
def BNE  : Branch_W<"bne",  RXBne>;   // !=
def BGE  : Branch_W<"bge",  RXBge>;   // <= (符号付き)
def BLE  : Branch_W<"ble",  RXBle>;   // >= (符号付き)
def BGT  : Branch_W<"bgt",  RXBgt>;   // <  (符号付き)
def BLT  : Branch_W<"blt",  RXBlt>;   // >  (符号付き)
def BGEU : Branch_W<"bgeu", RXBgeu>;  // <=
def BLEU : Branch_W<"bleu", RXBleu>;  // >=
def BGTU : Branch_W<"bgtu", RXBgtu>;  // <
def BLTU : Branch_W<"bltu", RXBltu>;  // >

// 相対無条件分岐
// BRA命令は24bitまでの相対アドレス
let isBranch = 1, isTerminator = 1, isBarrier = 1 in
def BRA : RXInst2<(outs), (ins brtarget:$target),
                  "bra $target",
                  [(br bb:$target)]>;

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
