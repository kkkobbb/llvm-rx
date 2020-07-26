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

// TODO RX用の記述 Operand


//===----------------------------------------------------------------------===//
// Instruction Formats
//===----------------------------------------------------------------------===//

include "RXInstrFormats.td"


//===----------------------------------------------------------------------===//
// Instructions
//===----------------------------------------------------------------------===//

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def NOP : RXInst1<0b00000011, (outs), (ins), "NOP", []>;

// サブルーチンからの復帰
let isBranch = 1, isTerminator = 1, isBarrier = 1, isReturn = 1 in
def RTS : RXInst1<0b00000010, (outs), (ins), "RTS", [(RXRts)]>;

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
