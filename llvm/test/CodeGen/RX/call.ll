; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @call_function() {
; CHECK-LABEL: call_function:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   mov #1, r1
; CHECK-NEXT:   bsr callee
; CHECK-NEXT:   rts
  %ret = call i32 @callee(i32 1)
  ret i32 %ret
}

define i32 @callee(i32) {
; CHECK-LABEL: callee:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   add #1, r1, r1
; CHECK-NEXT:   rts
  %a = add i32 %0, 1
  ret i32 %a
}
