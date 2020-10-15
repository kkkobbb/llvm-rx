; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @store_load_i32() noinline optnone {
; CHECK-LABEL: store_load_i32:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   add #-4, r0, r0
; CHECK-NEXT:   mov.l #2, 0[r0]
; CHECK-NEXT:   mov.l 0[r0], r1
; CHECK-NEXT:   add #4, r0, r0
; CHECK-NEXT:   rts
  %a = alloca i32
  store i32 2, i32* %a
  %ret = load i32, i32* %a
  ret i32 %ret
}
