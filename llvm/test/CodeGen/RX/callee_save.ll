; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @main() {
; CHECK-LABEL: main:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov #1, r1
; CHECK-NEXT:    mov #2, r2
; CHECK-NEXT:    mov #3, r3
; CHECK-NEXT:    mov #4, r4
; CHECK-NEXT:    bsr callee
; CHECK-NEXT:    rts
  %ret = call i32 @callee(i32 1, i32 2, i32 3, i32 4)
  ret i32 %ret
}

define i32 @callee(i32 %a, i32 %b, i32 %c, i32 %d) optnone noinline {
; CHECK-LABEL: callee:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    add #-4, r0, r0
; CHECK-NEXT:    mov.l r6, 0[r0]
; CHECK-NEXT:    add r1, r2, r5
; CHECK-NEXT:    add r3, r4, r14
; CHECK-NEXT:    add r1, r3, r15
; CHECK-NEXT:    add r2, r4, r6
; CHECK-NEXT:    add r1, r4, r1
; CHECK-NEXT:    add r2, r3, r2
; CHECK-NEXT:    add r5, r14, r3
; CHECK-NEXT:    add r15, r6, r4
; CHECK-NEXT:    add r1, r2, r1
; CHECK-NEXT:    add r3, r4, r2
; CHECK-NEXT:    add r1, r2, r1
; CHECK-NEXT:    add r1, r5, r1
; CHECK-NEXT:    mov.l 0[r0], r6
; CHECK-NEXT:    add #4, r0, r0
; CHECK-NEXT:    rts
  %ret1 = add i32 %a, %b
  %ret2 = add i32 %c, %d
  %ret3 = add i32 %a, %c
  %ret4 = add i32 %b, %d
  %ret5 = add i32 %a, %d
  %ret6 = add i32 %b, %c
  %ret7 = add i32 %ret1, %ret2
  %ret8 = add i32 %ret3, %ret4
  %ret9 = add i32 %ret5, %ret6
  %ret10 = add i32 %ret7, %ret8
  %ret11 = add i32 %ret9, %ret10
  %ret12 = add i32 %ret11, %ret1
  ret i32 %ret12
}
