; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @br_const() noinline optnone {
; CHECK-LABEL: br_const:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   mov #0, r1
; CHECK-NEXT:   cmp #0, r1
; CHECK-NEXT:   bne .LBB0_2
; CHECK-NEXT:   bra .LBB0_1
; CHECK-NEXT: .LBB0_1: ; %label1
; CHECK-NEXT:   mov #1, r1
; CHECK-NEXT:   rts
; CHECK-NEXT: .LBB0_2: ; %label2
; CHECK-NEXT:   mov #2, r1
; CHECK-NEXT:   rts
  br i1 true, label %label1, label %label2

label1:
  ret i32 1

label2:
  ret i32 2
}
