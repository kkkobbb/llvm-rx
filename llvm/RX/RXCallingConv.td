//===-- RXCallingConv.td - Calling Conventions RX ---------*- tablegen -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// レジスタの役割
// R0      フレームレジスタ
// R1-R4   戻り値
// R1-R4   引数格納
// R5      呼び出し元退避
// R6-R13  呼び出し先退避
// R14-R15 呼び出し元退避

// 引数
def CC_RX : CallingConv<[
    // i8型の引数はi32型に昇格する
    CCIfType<[i8], CCPromoteToType<i32>>,
    // i16型の引数はi32型に昇格する
    CCIfType<[i16], CCPromoteToType<i32>>,
    // i32型はレジスタ渡し
    CCIfType<[i32], CCAssignToReg<[R1, R2, R3, R4]>>,
    // レジスタに収まらなかった場合、スタックに渡す
    // NOTE llvm/include/llvm/Target/TargetCallingConv.td CCAssignToStack
    // NOTE CCAssignToStack<確保するサイス、アラインメント> (0の場合ABIの値を使用する)
    CCIfType<[i32], CCAssignToStack<0, 0>>
]>;

// 戻り値
def RetCC_RX : CallingConv<[
    // i32型はレジスタに渡す
    CCIfType<[i32], CCAssignToReg<[R1, R2, R3, R4]>>
]>;

// 呼び出し先退避レジスタ
def CSR : CalleeSavedRegs<(sequence "R%u", 6, 13)>;
