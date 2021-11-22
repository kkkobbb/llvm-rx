# RX Inst Code

## 1byte

### I1_Op
```
NOP  00000011
RTS  00000010
```

## 2byte

### I2_OpRs
```
JSR       011111110001 rs--
BRA       011111110100 rs--
```

### I2_OpRd
```
POP       011111101011 rd--
```

### I2_OpSzLdLdRsRd
```
MOVL_RR   11 sz 11 11 rs-- rd--
MOVL_pRR  11 sz 11 ld rs-- rd--
```

### I2_OpSzLdLdRdRs
```
MOVL_RpR  11 sz ld 11 rd-- rs--
```

### I2_OpSzRs
```
PUSHL_R   0111111010 sz rs--
```

### I2_OpLdRsRs
```
CMP_RR    010001 ld rs1- rs2-
```

### I2_OpUi4Rs
```
CMP_UI4R  01100001 imm- rs2-
```

### I2_OpCdDsp
```
B---       0010 cd-- pcdsp---
```


## 3byte

### I3_OpRdRsRs
```
ADD_RRR    111111110010 rd-- rs-- rs2-
SUB_RRR    111111110000 rd-- rs-- rs2-
MUL_RRR    111111110011 rd-- rs-- rs2-
AND_RRR    111111110100 rd-- rs-- rs2-
OR_RRR     111111110101 rd-- rs-- rs2-
```

### I3_OpLdRsRd
```
DIV_RR     11111100001000 ld rs-- rd--
DIVU_RR    11111100001001 ld rs-- rd--
ABS_RR     11111100000011 ld rs-- rd-- (ld=11 only)
MAX_RR     11111100000100 ld rs-- rd--
MIN_RR     11111100000101 ld rs-- rd--
XOR_RR     11111100001101 ld rs-- rd--
```

### I3_OpI5RsRd
```
SHAR_I5RR  11111101101 imm-- rs2- rd--
SHLL_I5RR  11111101110 imm-- rs2- rd--
SHLR_I5RR  11111101100 imm-- rs2- rd--
```

### I3_OpRsRd
```
SHAR_RR    1111110101100001 rs-- rd--
SHLL_RR    1111110101100010 rs-- rd--
SHLR_RR    1111110101100000 rs-- rd--
ROTL_RR    1111110101100110 rs-- rd--
ROTR_RR    1111110101100100 rs-- rd--
```

### I3_OpSzLd
```
SC---  111111001101 sz ld rd-- cd--
```


## 4byte命令

### I4_OpPcdsp
```
BSRA        000000101 pcdsp24bit
```

### I4_OpSzLdRsRdD16
```
MOVB_D16R   11 sz 11 ld rs-- rd-- dsp16bit (ld=10 only)
MOVW_D16R   11 sz 11 ld rs-- rd-- dsp16bit (ld=10 only)
MOVL_D16R   11 sz 11 ld rs-- rd-- dsp16bit (ld=10 only)
```

### I4_OpSzLdRdRsD16
```
MOVB_RD16   11 sz ld 11 rd-- rs-- dsp16bit (ld=10 only)
MOVW_RD16   11 sz ld 11 rd-- rs-- dsp16bit (ld=10 only)
MOVL_RD16   11 sz ld 11 rd-- rs-- dsp16bit (ld=10 only)
```

### I4_OpSLdRsRdD16
```
MOVUB_D16R  01011 s ld rs-- rd-- dsp16bit (ld=10 only)
MOVUW_D16R  01011 s ld rs-- rd-- dsp16bit (ld=10 only)
```


## 5byte命令

### I5_OpLdRdLiSzD16I8
```
MOVB_I8D16  111110 ld rd-- li sz dsp16bit imm8bit (ld=10, li=01 only)
```


## 6byte命令

### I6_OpLiRsRdI32
```
ADD_I32RR    011100 li rs2- rd-- imm32bit (li=00 only)
```

### I6_OpRdLiI32
```
MOV_I32R     11111011 rd-- li 10 imm32bit (li=00 only)
```

### I6_OpLdRdLiSzD16I16
```
MOVW_I16D16  111110 ld rd-- li sz dsp16bit imm16bit (ld=10, li=10 only)
```

### I6_OpLiRsI32
```
CMP_I32R     011101 li 0000 rs2- imm32bit (li=00 only)
```


## 7byte命令

### I7_OpLiRdI32
```
EMUL_I32R  111111010111 li 000110 rd-- imm32bit (li=00 only)
```


## 8byte命令

### I8_OpLdRdLiSzD16I32
```
MOVL_I32D16 111110 ld rd-- li sz dsp16bit imm32bit (ld=10, li=00 only)
```
