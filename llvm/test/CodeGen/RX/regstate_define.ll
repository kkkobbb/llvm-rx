; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @regstate_define() noinline optnone {
; CHECK-LABEL: regstate_define:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    add #-32, r0, r0
; CHECK-NEXT:    mov.l r6, 28[r0]
; CHECK-NEXT:    mov #1, r6
; CHECK-NEXT:    mov.l r6, r1
; CHECK-NEXT:    bsr ret_only
; CHECK-NEXT:    sub r1, r6, r1
; CHECK-NEXT:    mov.l 28[r0], r6
; CHECK-NEXT:    add #32, r0, r0
; CHECK-NEXT:    rts
  %ret = call i32 @ret_only(i32 1)
  %sub = sub i32 1, %ret
  ret i32 %sub
}

define i32 @ret_only(i32 %a) noinline optnone {
; CHECK-LABEL: ret_only:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    rts
  ret i32 %a
}
