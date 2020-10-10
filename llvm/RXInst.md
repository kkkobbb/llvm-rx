# RX Inst Code

## 1byte

### RXInst1_Op
```
NOP  00000011
RTS  00000010
```

## 2byte

### RXInst2_OpRs
```
JSR       011111110001 rs==
BRA       011111110100 rs==
```

### RXInst2_OpRd
```
POP       011111101011 rd==
```

### RXInst2_OpSzLdLdRsRd
```
MOVL_RR   11 sz 11 11 rs== rd==
MOVL_pRR  11 sz 11 ld rs== rd==
```

### RXInst2_OpSzLdLdRdRs
```
MOVL_RpR  11 sz ld 11 rd== rs==
```

### RXInst2_OpSzRs
```
PUSHL_R   0111111010 sz rs==
```

### RXInst2_OpLdRsRs
```
CMP_RR    010001 ld rs1= rs2=
```

### RXInst2_OpUi4Rs
```
CMP_UI4R  01100001 imm= rs2=
```

### RXInst2_OpCdDsp
```
B---       0010 cd== pcdsp===
```


## 3byte

### RXInst3_OpRdRsRs
```
ADD_RRR    111111110010 rd== rs== rs2=
SUB_RRR    111111110000 rd== rs== rs2=
MUL_RRR    111111110011 rd== rs== rs2=
AND_RRR    111111110100 rd== rs== rs2=
OR_RRR     111111110101 rd== rs== rs2=
```

### RXInst3_OpLdRsRd
```
DIV_RR     11111100001000 ld rs== rd==
DIVU_RR    11111100001001 ld rs== rd==
ABS_RR     11111100000011 ld rs== rd== (ld=11 only)
MAX_RR     11111100000100 ld rs== rd==
MIN_RR     11111100000101 ld rs== rd==
XOR_RR     11111100001101 ld rs== rd==
```

### RXInst3_OpI5RsRd
```
SHAR_I5RR  11111101101 imm== rs2= rd==
SHLL_I5RR  11111101110 imm== rs2= rd==
SHLR_I5RR  11111101100 imm== rs2= rd==
```

### RXInst3_OpRsRd
```
SHAR_RR    1111110101100001 rs== rd==
SHLL_RR    1111110101100010 rs== rd==
SHLR_RR    1111110101100000 rs== rd==
ROTL_RR    1111110101100110 rs== rd==
ROTR_RR    1111110101100100 rs== rd==
```


## 4byte命令

### RXInst4_OpPcdsp
```
BSRA        000000101 pcdsp24bit
```

### RXInst4_OpSzLdRsRdD16
```
MOVB_D16R   11 sz 11 ld rs== rd== dsp16bit
MOVW_D16R   11 sz 11 ld rs== rd== dsp16bit
MOVL_D16R   11 sz 11 ld rs== rd== dsp16bit
```

### RXInst4_OpSzLdRdRsD16
```
MOVB_RD16   11 sz ld 11 rd== rs== dsp16bit
MOVW_RD16   11 sz ld 11 rd== rs== dsp16bit
MOVL_RD16   11 sz ld 11 rd== rs== dsp16bit
```

### RXInst4_OpSLdRsRdD16
```
MOVUB_D16R  01011 s ld rs== rd== dsp16bit
MOVUW_D16R  01011 s ld rs== rd== dsp16bit
```
