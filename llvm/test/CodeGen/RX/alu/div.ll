; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @div_reg_imm(i32 %a) {
; CHECK-LABEL: div_reg_imm:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   mov.l r1, r2
; CHECK-NEXT:   emul #1717986919, r2 ; r3
; CHECK-NEXT:   shlr #31, r3, r1
; CHECK-NEXT:   shar #1, r3, r2
; CHECK-NEXT:   add r2, r1, r1
; CHECK-NEXT:   rts
  %div = sdiv i32 %a, 5
  ret i32 %div
}
