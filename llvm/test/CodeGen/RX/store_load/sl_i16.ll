; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i16 @store_load_i16() noinline optnone {
; CHECK-LABEL: store_load_i16:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   add #-2, r0, r0
; CHECK-NEXT:   mov.w #2:16, 0[r0]
; CHECK-NEXT:   mov.w 0[r0], r1
; CHECK-NEXT:   add #2, r0, r0
; CHECK-NEXT:   rts
  %a = alloca i16
  store i16 2, i16* %a
  %ret = load i16, i16* %a
  ret i16 %ret
}
