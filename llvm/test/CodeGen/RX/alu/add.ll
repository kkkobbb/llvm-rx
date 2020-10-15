; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @add_reg_reg(i32 %var1, i32 %var2) {
; CHECK-LABEL: add_reg_reg:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   add r1, r2, r1
; CHECK-NEXT:   rts
  %result = add i32 %var1, %var2
  ret i32 %result
}

define i32 @add_reg_imm(i32 %var1) {
; CHECK-LABEL: add_reg_imm:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   add #5, r1, r1
; CHECK-NEXT:   rts
  %result = add i32 %var1, 5
  ret i32 %result
}

define i32 @add_reg_ptr(i32 %var1, i32* %var2_ptr) {
; CHECK-LABEL: add_reg_ptr:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   mov.l 0[r2], r2
; CHECK-NEXT:   add r1, r2, r1
; CHECK-NEXT:   rts
  %var2 = load i32, i32* %var2_ptr
  %result = add i32 %var1, %var2
  ret i32 %result
}
