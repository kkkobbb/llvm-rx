; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i8 @store_load_i8() noinline optnone {
; CHECK-LABEL: store_load_i8:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    add #-1, r0, r0
; CHECK-NEXT:    mov.b #2:8, 0[r0]
; CHECK-NEXT:    mov.b 0[r0], r1
; CHECK-NEXT:    add #1, r0, r0
; CHECK-NEXT:    rts
  %a = alloca i8
  store i8 2, i8* %a
  %ret = load i8, i8* %a
  ret i8 %ret
}
