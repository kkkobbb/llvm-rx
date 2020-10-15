; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @call_arg8_i32() {
; CHECK-LABEL: call_arg8_i32:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   add #-32, r0, r0
; CHECK-NEXT:   add #8, r0, r1
; CHECK-NEXT:   mov.l #7, 0[r1]
; CHECK-NEXT:   add #12, r0, r1
; CHECK-NEXT:   mov.l #8, 0[r1]
; CHECK-NEXT:   add #4, r0, r1
; CHECK-NEXT:   mov.l #6, 0[r1]
; CHECK-NEXT:   mov.l #5, 0[r0]
; CHECK-NEXT:   mov #1, r1
; CHECK-NEXT:   mov #2, r2
; CHECK-NEXT:   mov #3, r3
; CHECK-NEXT:   mov #4, r4
; CHECK-NEXT:   bsr arg8_i32
; CHECK-NEXT:   add #32, r0, r0
; CHECK-NEXT:   rts
  %ret = call i32 @arg8_i32(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7,
                            i32 8)
  ret i32 %ret
}

define i32 @arg8_i32(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g,
                     i32 %h) {
; CHECK-LABEL: arg8_i32:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   mov.l 16[r0], r5
; CHECK-NEXT:   mov.l 12[r0], r14
; CHECK-NEXT:   add r14, r5, r5
; CHECK-NEXT:   mov.l 8[r0], r14
; CHECK-NEXT:   mov.l 4[r0], r15
; CHECK-NEXT:   add r15, r14, r14
; CHECK-NEXT:   add r14, r5, r5
; CHECK-NEXT:   add r3, r4, r3
; CHECK-NEXT:   add r1, r2, r1
; CHECK-NEXT:   add r1, r3, r1
; CHECK-NEXT:   add r1, r5, r1
; CHECK-NEXT:   rts
  %ret1 = add i32 %a, %b
  %ret2 = add i32 %c, %d
  %ret3 = add i32 %e, %f
  %ret4 = add i32 %g, %h
  %ret5 = add i32 %ret1, %ret2
  %ret6 = add i32 %ret3, %ret4
  %ret7 = add i32 %ret5, %ret6
  ret i32 %ret7
}
