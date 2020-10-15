; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define void @void_func() {
; CHECK-LABEL: void_func:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   rts
  ret void
}
