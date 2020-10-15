; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @rem_reg_reg(i32 %var1, i32 %var2) {
; CHECK-LABEL: rem_reg_reg:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   mov.l r1, r3
; CHECK-NEXT:   div r2, r3
; CHECK-NEXT:   mul r3, r2, r2
; CHECK-NEXT:   sub r2, r1, r1
; CHECK-NEXT:   rts
  %result = srem i32 %var1, %var2
  ret i32 %result
}
