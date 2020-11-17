; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @select(i32 %a, i32 %b) noinline optnone {
; CHECK-LABEL: select:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov.l r1, r3
; CHECK-NEXT:    mov #2, r4
; CHECK-NEXT:    mov #1, r1
; CHECK-NEXT:    cmp r3, r2
; CHECK-NEXT:    beq .LBB0_2
; CHECK-NEXT:  ; %bb.1: ; %entry
; CHECK-NEXT:    mov.l r4, r1
; CHECK-NEXT:  .LBB0_2: ; %entry
; CHECK-NEXT:    rts
entry:
  %0 = icmp eq i32 %a, %b
  %ret = select i1 %0, i32 1, i32 2

  ret i32 %ret
}
