//===-- RXRegisterInfo.td - RX Register defs ------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the RX register files
//===----------------------------------------------------------------------===//

// General purpose register definition.
class RXReg<bits<4> Enc, string n> : Register<n> {
  let HWEncoding{3-0} = Enc;
  let Namespace = "RX";
}

def R0  : RXReg<0,  "R0">,  DwarfRegNum<[0]> {
  let AltNames = ["SP"];
}
def R1  : RXReg<1,  "R1">,  DwarfRegNum<[1]>;
def R2  : RXReg<2,  "R2">,  DwarfRegNum<[2]>;
def R3  : RXReg<3,  "R3">,  DwarfRegNum<[3]>;
def R4  : RXReg<4,  "R4">,  DwarfRegNum<[4]>;
def R5  : RXReg<5,  "R5">,  DwarfRegNum<[5]>;
def R6  : RXReg<6,  "R6">,  DwarfRegNum<[6]>;
def R7  : RXReg<7,  "R7">,  DwarfRegNum<[7]>;
def R8  : RXReg<8,  "R8">,  DwarfRegNum<[8]>;
def R9  : RXReg<9,  "R9">,  DwarfRegNum<[9]>;
def R10 : RXReg<10, "R10">, DwarfRegNum<[10]>;
def R11 : RXReg<11, "R11">, DwarfRegNum<[11]>;
def R12 : RXReg<12, "R12">, DwarfRegNum<[12]>;
def R13 : RXReg<13, "R13">, DwarfRegNum<[13]>;
def R14 : RXReg<14, "R14">, DwarfRegNum<[14]>;
def R15 : RXReg<15, "R15">, DwarfRegNum<[15]>;

def AllRegs : RegisterClass<"RX", [i32], 32,
  (add  (sequence "R%u", 0, 15))>;

def GPR : RegisterClass<"RX", [i32], 32,
  (add  (sequence "R%u", 1, 15))>;
