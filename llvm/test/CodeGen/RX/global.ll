; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s
; RUN: not --crash llc -mtriple=rxv1 -relocation-model=pic -verify-machineinstrs < %s \
; RUN: 2>&1 | FileCheck -check-prefix=RXPIC %s

; RXPIC: LLVM ERROR: Unsupported position independent code

@aaa = global i32 3, align 4
@func_ptr = global i32 (...)* bitcast (i32 ()* @zerofunc to i32 (...)*), align 4

define i32 @load_global() noinline optnone {
; CHECK-LABEL: load_global:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov #aaa, r1
; CHECK-NEXT:    mov.l 0[r1], r1
; CHECK-NEXT:    add #2, r1, r1
; CHECK-NEXT:    rts
entry:
  %0 = load i32, i32* @aaa, align 4
  %add = add nsw i32 %0, 2
  ret i32 %add
}

define i32 @zerofunc() noinline optnone {
; CHECK-LABEL: zerofunc:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov #0, r1
; CHECK-NEXT:    rts
entry:
  ret i32 0
}

define i32 @call_global() noinline optnone {
; CHECK-LABEL: call_global:
; CHECK:       ; %bb.0:
; CHECK-NEXT:    mov #func_ptr, r1
; CHECK-NEXT:    mov.l 0[r1], r1
; CHECK-NEXT:    jsr r1
; CHECK-NEXT:    rts
entry:
  %0 = load i32 (...)*, i32 (...)** @func_ptr, align 4
  %callee.knr.cast = bitcast i32 (...)* %0 to i32 ()*
  %call = call i32 %callee.knr.cast()
  ret i32 %call
}
