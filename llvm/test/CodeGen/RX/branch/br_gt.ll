; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @br_gt(i32 %a, i32 %b) {
; CHECK-LABEL: br_gt:
; CHECK:       ; %bb.0: ; %entry
; CHECK-NEXT:    add #-4, r0, r0
; CHECK-NEXT:    cmp r1, r2
; CHECK-NEXT:    ble .LBB0_2
; CHECK-NEXT:  ; %bb.1: ; %then
; CHECK-NEXT:    mov.l #1, 0[r0]
; CHECK-NEXT:    bra .LBB0_3
; CHECK-NEXT:  .LBB0_2: ; %else
; CHECK-NEXT:    mov.l #2, 0[r0]
; CHECK-NEXT:  .LBB0_3: ; %ifret
; CHECK-NEXT:    mov.l 0[r0], r1
; CHECK-NEXT:    add #4, r0, r0
; CHECK-NEXT:    rts
entry:
  %c = alloca i32
  %0 = icmp sgt i32 %a, %b
  br i1 %0, label %then, label %else

then:
  store i32 1, i32* %c
  br label %ifret

else:
  store i32 2, i32* %c
  br label %ifret

ifret:
  %result = load i32, i32* %c
  ret i32 %result
}
