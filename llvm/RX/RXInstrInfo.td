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

def SDT_RXSelectCC : SDTypeProfile<1, 5, [SDTCisSameAs<1, 2>,
                                             SDTCisSameAs<0, 4>,
                                             SDTCisSameAs<4, 5>]>;
def RXSelectCC : SDNode<"RXISD::SELECT_CC", SDT_RXSelectCC,
                        [SDNPInGlue]>;

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
def pcdsp24_ptr : Operand<iPTR>;

// TODO 値が範囲内かの確認処理
// 8bit相対アドレス (BasicBlock用) (-128 <= pcdsp8 <= 127)
def pcdsp8 : Operand<OtherVT>;
// 24bit相対アドレス (BasicBlock用)
def pcdsp24 : Operand<OtherVT>;

// 2オペランドで表現されるアドレス ノード
def addr : ComplexPattern<iPTR, 2, "SelectAddr", [], [SDNPWantRoot]>;

// displacement 16
// dsp16l(.L)の値の範囲は0-262140(18bit)だが、命令コードのビット表現では1/4して
// 2bit落とした16bitになる
// asmの記述では4の倍数のみ受け付ける
// dps16w(.W)の場合は0-121070(17bit)だが、1/2して1bit落とした値が命令コードになる
// Operandとノードを同じ名前として定義している
def dsp16b : Operand<i32>,
             ImmLeaf<i32,[{return isUInt<16>(Imm);}]>;
def dsp16w : Operand<i32>,
             ImmLeaf<i32,[{return isUInt<17>(Imm) && (Imm % 2 == 0);}]> {
  let EncoderMethod = "getDsp16wOpValue";
}
def dsp16l : Operand<i32>,
             ImmLeaf<i32,[{return isUInt<18>(Imm) && (Imm % 4 == 0);}]> {
  let EncoderMethod = "getDsp16lOpValue";
}


// 5bit unsigned即値
def uimm5 : Operand<i32>, ImmLeaf<i32, [{return isUInt<5>(Imm);}]>;
// 8bit signed即値
def imm8 : Operand<i32>, ImmLeaf<i32, [{return isInt<8>(Imm);}]>;
// 16bit signed即値
def imm16 : Operand<i32>, ImmLeaf<i32, [{return isInt<16>(Imm);}]> {
  let EncoderMethod = "getImm16OpValue";
}
// 32bit 即値
def imm32 : Operand<i32>, ImmLeaf<i32, [{return isInt<32>(Imm);}]> {
  let EncoderMethod = "getImm32OpValue";
}

// reg or imm
def GPRIMM : Operand<i32>;


//===----------------------------------------------------------------------===//
// Instruction Formats
//===----------------------------------------------------------------------===//

include "RXInstrFormats.td"


//===----------------------------------------------------------------------===//
// Instructions
//===----------------------------------------------------------------------===//

// NOTE パターンに現れるsetはノードではなく出力レジスタを表現するための記述のため、Pat<>には記述する必要がない(できない?)

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def NOP : I1_Op<0b00000011, (outs), (ins), "nop", []>;

// 相対サブルーチン分岐 pcdsp:24
let isCall = 1 in
def BSRA : I4_OpD24<0b00000101, (outs), (ins pcdsp24_ptr:$pcdsp),
                    "bsr $pcdsp", []>;
def : Pat<(RXBsr (i32 tglobaladdr:$addr)), (BSRA tglobaladdr:$addr)>;
def : Pat<(RXBsr (i32 texternalsym:$addr)), (BSRA texternalsym:$addr)>;

// 相対アドレスをレジスタに格納する方法が不明なので、レジスタに格納されるのは絶対アドレスのみ
// BSR命令は使えないため、JSR命令を変わりに使う
// なので、関数ポインタ、グローバル変数を使用するとPIC不可
// TODO レジスタに相対アドレスを格納できればBSR命令を使用する
let isCall = 1 in
def JSR : I2_OpRs<0b011111110001, (outs), (ins GPR:$rs), "jsr $rs",
                  [(RXBsr GPR:$rs)]>;


// サブルーチンからの復帰
// NOTE isBarrier 制御フローを(常に)停止させる命令の場合、真
// NOTE isTerminator BasicBlockを終了させる可能性がある場合、真
// NOTE llvm/include/llvm/MC/MCInstrDesc.h
let isBarrier = 1, isReturn = 1, isTerminator = 1 in
def RTS : I1_Op<0b00000010, (outs), (ins), "rts", [(RXRts)]>;

// 加算 imm32 reg reg
def ADD_I32RR : I6_OpLiRsRdI32<0b011100, (outs GPR:$rd), (ins GPR:$rs, imm32:$imm),
                               "add #$imm, $rs, $rd",
                               [(set GPR:$rd, (add GPR:$rs, imm32:$imm))]>;

// 加算 reg reg reg
def ADD_RRR : I3_OpRdRsRs<0b111111110010, (outs GPR:$rd),
                          (ins GPR:$rs, GPR:$rs2),
                          "add $rs, $rs2, $rd",
                          [(set GPR:$rd, (add GPR:$rs, GPR:$rs2))]>;

// 減算 reg reg reg
def SUB_RRR : I3_OpRdRsRs<0b111111110000, (outs GPR:$rd),
                          (ins GPR:$rs, GPR:$rs2),
                          "sub $rs, $rs2, $rd",
                          [(set GPR:$rd, (sub GPR:$rs2, GPR:$rs))]>;

// 乗算 reg reg reg
def MUL_RRR : I3_OpRdRsRs<0b111111110011, (outs GPR:$rd),
                          (ins GPR:$rs, GPR:$rs2),
                          "mul $rs, $rs2, $rd",
                          [(set GPR:$rd, (mul GPR:$rs, GPR:$rs2))]>;

// 符号付き乗算 2つの32bitレジスタに結果を格納する
//
// sdivが出た場合、smullohiを使って乗算に変換される
//
// rdとrd2は連番となる必要がある
// GPR64_lo,GPR64_hiをそれぞれレジスタ１つのみ定義することで連番にしている
//
// ただし、レジスタ割り当てに失敗するかもしれない
// TODO EMUL_I32R 他の方法があれば修正する or SMUL_LOHIもExpandにする
//   (MULHS、SMUL_LOHI両方をExpandにした場合、sdivは変換されない)
let Constraints = "$rd = $src" in
def EMUL_I32R : I7_OpLiRdI32<0b111111010111,
                             (outs GPR64_lo:$rd, GPR64_hi:$rd2),
                             (ins GPR64_lo:$src, imm32:$imm),
                             "emul #$imm, $rd ; $rd2",
                             [(set GPR64_lo:$rd, GPR64_hi:$rd2, (smullohi GPR64_lo:$src, imm32:$imm))]>;

// 符号付き除算 reg reg
let Constraints = "$rd = $src" in
def DIV_RR : I3_OpLdRsRd<0b11111100001000, LD_DIRECT, (outs GPR:$rd),
                         (ins GPR:$src, GPR:$rs),
                         "div $rs, $rd",
                         [(set GPR:$rd, (sdiv GPR:$src, GPR:$rs))]>;

// 符号なし除算 reg reg
let Constraints = "$rd = $src" in
def DIVU_RR : I3_OpLdRsRd<0b11111100001001, LD_DIRECT, (outs GPR:$rd),
                          (ins GPR:$src, GPR:$rs),
                          "divu $rs, $rd",
                          [(set GPR:$rd, (udiv GPR:$src, GPR:$rs))]>;

// 絶対値 reg reg
def ABS_RR : I3_OpLdRsRd<0b11111100000011, LD_DIRECT, (outs GPR:$rd),
                         (ins GPR:$rs),
                         "abs $rs, $rd",
                         [(set GPR:$rd, (abs GPR:$rs))]>;

let Constraints = "$rd = $src" in {
// 最大値選択 reg reg
def MAX_RR : I3_OpLdRsRd<0b11111100000100, LD_DIRECT, (outs GPR:$rd),
                         (ins GPR:$src, GPR:$rs),
                         "max $rs, $rd",
                         [(set GPR:$rd, (smax GPR:$src, GPR:$rs))]>;

// 最小値選択 reg reg
def MIN_RR : I3_OpLdRsRd<0b11111100000101, LD_DIRECT, (outs GPR:$rd),
                         (ins GPR:$src, GPR:$rs),
                         "min $rs, $rd",
                         [(set GPR:$rd, (smin GPR:$src, GPR:$rs))]>;
}

// AND reg reg reg
def AND_RRR : I3_OpRdRsRs<0b111111110100, (outs GPR:$rd),
                          (ins GPR:$rs, GPR:$rs2),
                          "and $rs, $rs2, $rd",
                          [(set GPR:$rd, (and GPR:$rs2, GPR:$rs))]>;

// OR reg reg reg
def OR_RRR : I3_OpRdRsRs<0b111111110101, (outs GPR:$rd),
                         (ins GPR:$rs, GPR:$rs2),
                         "or $rs, $rs2, $rd",
                         [(set GPR:$rd, (or GPR:$rs2, GPR:$rs))]>;

// XOR reg reg
let Constraints = "$rd = $src" in
def XOR_RR : I3_OpLdRsRd<0b11111100001101, LD_DIRECT, (outs GPR:$rd),
                         (ins GPR:$src, GPR:$rs),
                         "xor $rs, $rd",
                         [(set GPR:$rd, (xor GPR:$src, GPR:$rs))]>;

// 算術右シフト uimm5 reg reg
def SHAR_I5RR : I3_OpI5RsRd<0b11111101101, (outs GPR:$rd),
                            (ins GPR:$rs, uimm5:$imm),
                            "shar #$imm, $rs, $rd",
                            [(set GPR:$rd, (sra GPR:$rs, uimm5:$imm))]>;

// 論理算術左シフト uimm5 reg reg
def SHLL_I5RR : I3_OpI5RsRd<0b11111101110, (outs GPR:$rd),
                            (ins GPR:$rs, uimm5:$imm),
                            "shll #$imm, $rs, $rd",
                            [(set GPR:$rd, (shl GPR:$rs, uimm5:$imm))]>;

// 論理右シフト uimm5 reg reg
def SHLR_I5RR : I3_OpI5RsRd<0b11111101100, (outs GPR:$rd),
                            (ins GPR:$rs, uimm5:$imm),
                            "shlr #$imm, $rs, $rd",
                            [(set GPR:$rd, (srl GPR:$rs, uimm5:$imm))]>;

let Constraints = "$rd = $src" in {
// 算術右シフト reg reg
def SHAR_RR : I3_OpRsRd<0b1111110101100001, (outs GPR:$rd),
                        (ins GPR:$src, GPR:$rs),
                        "shar $rs, $rd",
                        [(set GPR:$rd, (sra GPR:$src, GPR:$rs))]>;

// 論理算術左シフト reg reg
def SHLL_RR : I3_OpRsRd<0b1111110101100010, (outs GPR:$rd),
                        (ins GPR:$src, GPR:$rs),
                        "shll $rs, $rd",
                        [(set GPR:$rd, (shl GPR:$src, GPR:$rs))]>;

// 論理右シフト reg reg
def SHLR_RR : I3_OpRsRd<0b1111110101100000, (outs GPR:$rd),
                        (ins GPR:$src, GPR:$rs),
                        "shlr $rs, $rd",
                        [(set GPR:$rd, (srl GPR:$src, GPR:$rs))]>;

// 左回転 reg reg
def ROTL_RR : I3_OpRsRd<0b1111110101100110, (outs GPR:$rd),
                        (ins GPR:$src, GPR:$rs),
                        "rotl $rs, $rd",
                        [(set GPR:$rd, (rotl GPR:$src, GPR:$rs))]>;

// 右回転 reg reg
def ROTR_RR : I3_OpRsRd<0b1111110101100100, (outs GPR:$rd),
                        (ins GPR:$src, GPR:$rs),
                        "rotr $rs, $rd",
                        [(set GPR:$rd, (rotr GPR:$src, GPR:$rs))]>;
}

// move imm32 reg
def MOV_I32R : I6_OpRdLiI32<0b11111011, (outs GPR:$rd), (ins imm32:$imm),
                            "mov #$imm, $rd",
                            [(set GPR:$rd, imm32:$imm)]>;

// move reg reg (long)
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def MOVL_RR : I2_OpSzLdLdRsRd<SIZE_L, LD_DIRECT, LD_DIRECT,
                              (outs GPR:$rd), (ins GPR:$rs),
                              "mov.l $rs, $rd", []>;

// load (long)
def MOVL_pRR : I2_OpSzLdLdRsRd<SIZE_L, LD_DIRECT, LD_INDIRECT,
                               (outs GPR:$rd), (ins GPR:$rs),
                               "mov.l [$rs], $rd",
                               [(set GPR:$rd, (load GPR:$rs))]>;

// store (long)
def MOVL_RpR : I2_OpSzLdLdRdRs<SIZE_L, LD_INDIRECT, LD_DIRECT,
                               (outs), (ins GPR:$rd, GPR:$rs),
                               "mov.l $rs, [$rd]",
                               [(store GPR:$rs, GPR:$rd)]>;

// NOTE *extload* 上位ビット拡張ロード
// displacement load (byte)
def MOVB_D16R : I4_OpSzLdRsRdD16<SIZE_B, (outs GPR:$rd),
                                 (ins GPR:$rs, dsp16b:$dsp),
                                 "mov.b $dsp[$rs], $rd",
                                 [(set GPR:$rd, (sextloadi8 (addr GPR:$rs, dsp16b:$dsp)))]>;
def : Pat<(extloadi8 (addr GPR:$rs, dsp16b:$dsp)), (MOVB_D16R GPR:$rs, dsp16b:$dsp)>;

// displacement load (word)
def MOVW_D16R : I4_OpSzLdRsRdD16<SIZE_W, (outs GPR:$rd),
                                 (ins GPR:$rs, dsp16w:$dsp),
                                 "mov.w $dsp[$rs], $rd",
                                 [(set GPR:$rd, (sextloadi16 (addr GPR:$rs, dsp16w:$dsp)))]>;
def : Pat<(extloadi16 (addr GPR:$rs, dsp16w:$dsp)), (MOVW_D16R GPR:$rs, dsp16w:$dsp)>;

// displacement load (long)
def MOVL_D16R : I4_OpSzLdRsRdD16<SIZE_L, (outs GPR:$rd),
                                 (ins GPR:$rs, dsp16l:$dsp),
                                 "mov.l $dsp[$rs], $rd",
                                 [(set GPR:$rd, (load (addr GPR:$rs, dsp16l:$dsp)))]>;

// NOTE truncstore* 上位ビット切り捨てストア
// displacement store (byte)
def MOVB_RD16 : I4_OpSzLdRdRsD16<SIZE_B, (outs),
                                 (ins GPR:$rs, GPR:$rd, dsp16b:$dsp),
                                 "mov.b $rs, $dsp[$rd]",
                                 [(truncstorei8 GPR:$rs, (addr GPR:$rd, dsp16b:$dsp))]>;

// displacement store (word)
def MOVW_RD16 : I4_OpSzLdRdRsD16<SIZE_W, (outs),
                                 (ins GPR:$rs, GPR:$rd, dsp16b:$dsp),
                                 "mov.w $rs, $dsp[$rd]",
                                 [(truncstorei16 GPR:$rs, (addr GPR:$rd, dsp16b:$dsp))]>;

// displacement store (long)
def MOVL_RD16 : I4_OpSzLdRdRsD16<SIZE_L, (outs),
                                 (ins GPR:$rs, GPR:$rd, dsp16l:$dsp),
                                 "mov.l $rs, $dsp[$rd]",
                                 [(store GPR:$rs, (addr GPR:$rd, dsp16l:$dsp))]>;

// displacement store imm8
def MOVB_I8D16 : I5_OpLdRdLiSzD16I8<0b111110, SIZE_B, (outs),
                                    (ins imm8:$imm, GPR:$rd, dsp16b:$dsp),
                                    "mov.b #${imm}:8, $dsp[$rd]",
                                    [(truncstorei8 (i32 imm8:$imm), (addr GPR:$rd, dsp16b:$dsp))]>;

// displacement store imm16
def MOVW_I16D16 : I6_OpLdRdLiSzD16I16<0b111110, SIZE_W, (outs),
                                      (ins imm16:$imm, GPR:$rd, dsp16w:$dsp),
                                      "mov.w #${imm}:16, $dsp[$rd]",
                                      [(truncstorei16 (i32 imm16:$imm), (addr GPR:$rd, dsp16w:$dsp))]>;

// displacement store imm32
def MOVL_I32D16 : I8_OpLdRdLiSzD16I32<0b111110, SIZE_L, (outs),
                                      (ins imm32:$imm, GPR:$rd, dsp16l:$dsp),
                                      "mov.l #$imm, $dsp[$rd]",
                                      [(store (i32 imm32:$imm), (addr GPR:$rd, dsp16l:$dsp))]>;

// displacement load unsigned (byte)
def MOVUB_D16R : I4_OpSLdRsRdD16<0b01011, SIZE1_B, (outs GPR:$rd),
                                 (ins GPR:$rs, dsp16b:$dsp),
                                 "movu.b $dsp[$rs], $rd",
                                 [(set GPR:$rd, (zextloadi8 (addr GPR:$rs, dsp16b:$dsp)))]>;

// displacement load unsigned (word)
def MOVUW_D16R : I4_OpSLdRsRdD16<0b01011, SIZE1_W, (outs GPR:$rd),
                                 (ins GPR:$rs, dsp16w:$dsp),
                                 "movu.w $dsp[$rs], $rd",
                                 [(set GPR:$rd, (zextloadi16 (addr GPR:$rs, dsp16w:$dsp)))]>;

let Defs = [R0], Uses = [R0] in {
// NOTE 未使用
// pop レジスタ
let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def POP : I2_OpRd<0b011111101011, (outs GPR:$rd), (ins), "pop $rd", []>;

// NOTE 未使用
// push レジスタ
let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def PUSHL_R : I2_OpSzRs<0b0111111010, SIZE_L, (outs), (ins GPR:$rs),
                        "push.l $rs", []>;
}

// 比較
let hasSideEffects = 1, mayLoad = 0, mayStore = 0 in {
def CMP_RR : I2_OpLdRsRs<0b010001, LD_DIRECT,
                         (outs), (ins GPR:$rs, GPR:$rs2),
                         "cmp $rs, $rs2", []>;

// NOTE CMP_I32Rとは命令長が違うだけなので、asm出力しかしないなら差はない
def CMP_UI4R : I2_OpUi4Rs<0b01100001, (outs), (ins imm32:$imm, GPR:$rs),
                          "cmp #$imm, $rs", []>;

def CMP_I32R : I6_OpLiRsI32<0b011101, (outs), (ins imm32:$imm, GPR:$rs),
                            "cmp #$imm, $rs", []>;
}

// 相対条件分岐
let hasSideEffects = 0, mayLoad = 0, mayStore = 0,
    isBranch = 1, isTerminator = 1 in
class BranchReg<RXCd cd, string asmstr>
    : I2_OpCdDsp<cd, (outs), (ins pcdsp8:$dsp),
                 !strconcat(asmstr, " $dsp"), []>;
def BEQ  : BranchReg<CD_EQ, "beq">;    // ==
def BNE  : BranchReg<CD_NE, "bne">;    // !=
def BGE  : BranchReg<CD_GE, "bge">;    // <= (符号付き)
def BLE  : BranchReg<CD_LE, "ble">;    // >= (符号付き)
def BGT  : BranchReg<CD_GT, "bgt">;    // <  (符号付き)
def BLT  : BranchReg<CD_LT, "blt">;    // >  (符号付き)
def BGEU : BranchReg<CD_GEU, "bgeu">;  // <=
def BLEU : BranchReg<CD_LEU, "bleu">;  // >=
def BGTU : BranchReg<CD_GTU, "bgtu">;  // <
def BLTU : BranchReg<CD_LTU, "bltu">;  // >

// 分岐仮想命令
// 後の処理で<比較>と<相対条件分岐>に変換される
let isBranch = 1, isTerminator = 1 in
class BrcondPseudo<PatFrag Cond>
    : RXInstPseudo<(outs), (ins GPRIMM:$lhs, GPR:$rhs, pcdsp8:$dsp),
                   "", [(brcond (i32 (Cond i32:$lhs, GPR:$rhs)), bb:$dsp)]>;
def pBRCOND_EQ  : BrcondPseudo<seteq>;
def pBRCOND_NE  : BrcondPseudo<setne>;
def pBRCOND_LT  : BrcondPseudo<setlt>;
def pBRCOND_ULT : BrcondPseudo<setult>;
def pBRCOND_GT  : BrcondPseudo<setgt>;
def pBRCOND_UGT : BrcondPseudo<setugt>;
def pBRCOND_LE  : BrcondPseudo<setle>;
def pBRCOND_ULE : BrcondPseudo<setule>;
def pBRCOND_GE  : BrcondPseudo<setge>;
def pBRCOND_UGE : BrcondPseudo<setuge>;

def : Pat<(brcond GPR:$cond, bb:$target), (pBRCOND_NE 0, GPR:$cond, bb:$target)>;


// 条件設定
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class StoreCondReg<RXCd cd, string asmstr>
    : I3_OpSzLdRdCd<SIZE_L, LD_DIRECT, cd, (outs GPR:$rd), (ins),
                    !strconcat(asmstr, " $rd"), []>;
def SCEQ  : StoreCondReg<CD_EQ, "sceq.l">;    // ==
def SCNE  : StoreCondReg<CD_NE, "scne.l">;    // !=
def SCGE  : StoreCondReg<CD_GE, "scge.l">;    // <= (符号付き)
def SCLE  : StoreCondReg<CD_LE, "scle.l">;    // >= (符号付き)
def SCGT  : StoreCondReg<CD_GT, "scgt.l">;    // <  (符号付き)
def SCLT  : StoreCondReg<CD_LT, "sclt.l">;    // >  (符号付き)
def SCGEU : StoreCondReg<CD_GEU, "scgeu.l">;  // <=
def SCLEU : StoreCondReg<CD_LEU, "scleu.l">;  // >=
def SCGTU : StoreCondReg<CD_GTU, "scgtu.l">;  // <
def SCLTU : StoreCondReg<CD_LTU, "scltu.l">;  // >

// 条件設定仮想命令
// 後の処理で<比較>と<条件設定>に変換される
class SetccPseudo<PatFrag Cond>
    : RXInstPseudo<(outs GPR:$rd), (ins GPRIMM:$lhs, GPR:$rhs),
                   "", [(set GPR:$rd, (Cond i32:$lhs, GPR:$rhs))]>;
def pSETCC_EQ  : SetccPseudo<seteq>;
def pSETCC_NE  : SetccPseudo<setne>;
def pSETCC_LT  : SetccPseudo<setlt>;
def pSETCC_ULT : SetccPseudo<setult>;
def pSETCC_GT  : SetccPseudo<setgt>;
def pSETCC_UGT : SetccPseudo<setugt>;
def pSETCC_LE  : SetccPseudo<setle>;
def pSETCC_ULE : SetccPseudo<setule>;
def pSETCC_GE  : SetccPseudo<setge>;
def pSETCC_UGE : SetccPseudo<setuge>;


// 相対無条件分岐
// BRA命令は24bitまでの相対アドレス
let isBranch = 1, isTerminator = 1, isBarrier = 1 in
def BRA : I2_OpRs<0b011111110100, (outs), (ins pcdsp24:$rs),
                  "bra $rs", [(br bb:$rs)]>;

// TODO ほぼRISCV
let usesCustomInserter = 1 in
class SelectCC_rrirr<RegisterClass valty, RegisterClass cmpty>
    : RXInstPseudo<(outs valty:$dst),
                   (ins cmpty:$lhs, cmpty:$rhs, imm32:$imm,
                    valty:$truev, valty:$falsev), "",
                   [(set valty:$dst, (RXSelectCC cmpty:$lhs, cmpty:$rhs,
                    (i32 imm32:$imm), valty:$truev, valty:$falsev))]>;

def Select_GPR_Using_CC_GPR : SelectCC_rrirr<GPR, GPR>;

// Callの開始終了を表す疑似命令
let Defs = [R0], Uses = [R0] in {
def ADJCALLSTACKDOWN : RXInstPseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                                    "!ADJCALLSTACKDOWN $amt1",
                                    [(callseq_start timm:$amt1, timm:$amt2)]>;
def ADJCALLSTACKUP   : RXInstPseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                                    "!ADJCALLSTACKUP $amt1",
                                    [(callseq_end timm:$amt1, timm:$amt2)]>;
}
