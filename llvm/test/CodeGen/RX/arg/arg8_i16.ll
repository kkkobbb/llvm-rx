; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i16 @call_arg8_i16() {
; CHECK-LABEL: call_arg8_i16:
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
; CHECK-NEXT:    bsr arg8_i16
; CHECK-NEXT:    add #32, r0, r0
; CHECK-NEXT:    rts
  %ret = call i16 @arg8_i16(i16 1, i16 2, i16 3, i16 4, i16 5, i16 6, i16 7,
                            i16 8)
  ret i16 %ret
}

define i16 @arg8_i16(i16 %a, i16 %b, i16 %c, i16 %d, i16 %e, i16 %f, i16 %g,
                     i16 %h) {
; CHECK-LABEL: arg8_i16:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov.w 16[r0], r5
; CHECK-NEXT:    mov.w 12[r0], r14
; CHECK-NEXT:    add r14, r5, r5
; CHECK-NEXT:    mov.w 8[r0], r14
; CHECK-NEXT:    mov.w 4[r0], r15
; CHECK-NEXT:    add r15, r14, r14
; CHECK-NEXT:    add r14, r5, r5
; CHECK-NEXT:    add r3, r4, r3
; CHECK-NEXT:    add r1, r2, r1
; CHECK-NEXT:    add r1, r3, r1
; CHECK-NEXT:    add r1, r5, r1
; CHECK-NEXT:    rts
  %ret1 = add i16 %a, %b
  %ret2 = add i16 %c, %d
  %ret3 = add i16 %e, %f
  %ret4 = add i16 %g, %h
  %ret5 = add i16 %ret1, %ret2
  %ret6 = add i16 %ret3, %ret4
  %ret7 = add i16 %ret5, %ret6
  ret i16 %ret7
}
