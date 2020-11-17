; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @call_arg4() {
; CHECK-LABEL: call_arg4:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov #1, r1
; CHECK-NEXT:    mov #2, r2
; CHECK-NEXT:    mov #3, r3
; CHECK-NEXT:    mov #4, r4
; CHECK-NEXT:    bsr arg4
; CHECK-NEXT:    rts
  %ret = call i32 @arg4(i32 1, i32 2, i32 3, i32 4)
  ret i32 %ret
}

define i32 @arg4(i32 %a, i32 %b, i32 %c, i32 %d) {
; CHECK-LABEL: arg4:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    add r3, r4, r3
; CHECK-NEXT:    add r1, r2, r1
; CHECK-NEXT:    add r1, r3, r1
; CHECK-NEXT:    rts
  %ret1 = add i32 %a, %b
  %ret2 = add i32 %c, %d
  %ret3 = add i32 %ret1, %ret2
  ret i32 %ret3
}
