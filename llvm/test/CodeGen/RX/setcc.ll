; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @setcc(i32 %a, i32 %b) noinline optnone {
; CHECK-LABEL: setcc:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    cmp r1, r2
; CHECK-NEXT:    sceq.l r1
; CHECK-NEXT:    rts
  %cmp = icmp eq i32 %a, %b
  %ret = zext i1 %cmp to i32
  ret i32 %ret
}
