; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @zerofunc() noinline optnone {
; CHECK-LABEL: zerofunc:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov #0, r1
; CHECK-NEXT:    rts
entry:
  ret i32 0
}

define i32 @call_func_ptr() noinline optnone {
; CHECK-LABEL: call_func_ptr
; CHECK:       ; %bb.0:
; CHECK-NEXT:    add #-32, r0, r0
; CHECK-NEXT:    mov #zerofunc, r1
; CHECK-NEXT:    mov.l r1, 28[r0]
; CHECK-NEXT:    mov.l 28[r0], r1
; CHECK-NEXT:    jsr r1
; CHECK-NEXT:    add #32, r0, r0
; CHECK-NEXT:    rts
entry:
  %func_ptr = alloca i32 (...)*, align 4
  store i32 (...)* bitcast (i32 ()* @zerofunc to i32 (...)*), i32 (...)** %func_ptr, align 4
  %0 = load i32 (...)*, i32 (...)** %func_ptr, align 4
  %callee.knr.cast = bitcast i32 (...)* %0 to i32 ()*
  %call = call i32 %callee.knr.cast()
  ret i32 %call
}
