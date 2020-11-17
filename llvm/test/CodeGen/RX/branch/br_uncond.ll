; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @br_uncond() {
; CHECK-LABEL: br_uncond:
; CHECK:       ; %bb.0: ; %entry
; CHECK-NEXT:    add #-4, r0, r0
; CHECK-NEXT:    mov.l #0, 0[r0]
; CHECK-NEXT:    mov.l #2, 0[r0]
; CHECK-NEXT:    mov.l 0[r0], r1
; CHECK-NEXT:    add #4, r0, r0
; CHECK-NEXT:    rts
entry:
  %b = alloca i32
  store i32 0, i32* %b
  br label %lbl2

lbl1:
  store i32 1, i32* %b
  br label %lbl3

lbl2:
  store i32 2, i32* %b
  br label %lbl3

lbl3:
  %result = load i32, i32* %b
  ret i32 %result
}
