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



