; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i8 @call_arg8_i8() {
; CHECK-LABEL: call_arg8_i8:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    add #-32, r0, r0
; CHECK-NEXT:    add #8, r0, r1
; CHECK-NEXT:    mov.l #7, 0[r1]
; CHECK-NEXT:    add #12, r0, r1
; CHECK-NEXT:    mov.l #8, 0[r1]
; CHECK-NEXT:    add #4, r0, r1
; CHECK-NEXT:    mov.l #6, 0[r1]
; CHECK-NEXT:    mov.l #5, 0[r0]
; CHECK-NEXT:    mov #1, r1
; CHECK-NEXT:    mov #2, r2
; CHECK-NEXT:    mov #3, r3
; CHECK-NEXT:    mov #4, r4
; CHECK-NEXT:    bsr arg8_i8
; CHECK-NEXT:    add #32, r0, r0
; CHECK-NEXT:    rts
  %ret = call i8 @arg8_i8(i8 1, i8 2, i8 3, i8 4, i8 5, i8 6, i8 7, i8 8)
  ret i8 %ret
}

define i8 @arg8_i8(i8 %a, i8 %b, i8 %c, i8 %d, i8 %e, i8 %f, i8 %g, i8 %h) {
; CHECK-LABEL: arg8_i8:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov.b 16[r0], r5
; CHECK-NEXT:    mov.b 12[r0], r14
; CHECK-NEXT:    add r14, r5, r5
; CHECK-NEXT:    mov.b 8[r0], r14
; CHECK-NEXT:    mov.b 4[r0], r15
; CHECK-NEXT:    add r15, r14, r14
; CHECK-NEXT:    add r14, r5, r5
; CHECK-NEXT:    add r3, r4, r3
; CHECK-NEXT:    add r1, r2, r1
; CHECK-NEXT:    add r1, r3, r1
; CHECK-NEXT:    add r1, r5, r1
; CHECK-NEXT:    rts
  %ret1 = add i8 %a, %b
  %ret2 = add i8 %c, %d
  %ret3 = add i8 %e, %f
  %ret4 = add i8 %g, %h
  %ret5 = add i8 %ret1, %ret2
  %ret6 = add i8 %ret3, %ret4
  %ret7 = add i8 %ret5, %ret6
  ret i8 %ret7
}
