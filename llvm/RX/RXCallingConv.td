//===-- RXCallingConv.td - Calling Conventions RX ---------*- tablegen -*--===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// レジスタの役割
// R0     フレームレジスタ
// R1     戻り値
// R2-R9  引数受け取り

// 引数
def CC_RX : CallingConv<[
    // i8型の引数はi32型に昇格する
    CCIfType<[i8], CCPromoteToType<i32>>,
    // i16型の引数はi32型に昇格する
    CCIfType<[i16], CCPromoteToType<i32>>,
    // i32型はレジスタ渡し
    CCIfType<[i32], CCAssignToReg<[R2, R3, R4, R5, R6, R7, R8, R9]>>,
    // レジスタに収まらなかった場合、スタックに渡す
    // NOTE llvm/include/llvm/Target/TargetCallingConv.td CCAssignToStack
    // NOTE CCAssignToStack<確保するサイス、アラインメント> (0の場合ABIの値を使用する)
    CCIfType<[i32], CCAssignToStack<0, 0>>
]>;

// 戻り値
def RetCC_RX : CallingConv<[
    // i32型はレジスタに渡す
    CCIfType<[i32], CCAssignToReg<[R1]>>
]>;

// 呼び出し先退避レジスタ
def CSR : CalleeSavedRegs<(add (sequence "R%u", 2, 15))>;
