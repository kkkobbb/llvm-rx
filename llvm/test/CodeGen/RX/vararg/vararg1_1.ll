; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

; Function Attrs: noinline nounwind optnone
define i32 @varargsum(i32 %base, ...) noinline nounwind optnone {
; CHECK-LABEL: varargsum:
; CHECK:       ; %bb.0: ; %entry
; CHECK-NEXT:    add #-24, r0, r0
; CHECK-NEXT:    mov.l r4, 24[r0]
; CHECK-NEXT:    mov.l r3, 20[r0]
; CHECK-NEXT:    mov.l r2, 16[r0]
; CHECK-NEXT:    mov.l r1, 12[r0]
; CHECK-NEXT:    mov.l 12[r0], r1
; CHECK-NEXT:    mov.l r1, 8[r0]
; CHECK-NEXT:    add #16, r0, r1
; CHECK-NEXT:    mov.l r1, 4[r0]
; CHECK-NEXT:    mov.l 4[r0], r1
; CHECK-NEXT:    add #3, r1, r1
; CHECK-NEXT:    mov #-4, r2
; CHECK-NEXT:    and r2, r1, r1
; CHECK-NEXT:    add #4, r1, r2
; CHECK-NEXT:    mov.l r2, 4[r0]
; CHECK-NEXT:    mov.l 0[r1], r1
; CHECK-NEXT:    mov.l r1, 0[r0]
; CHECK-NEXT:    mov.l 0[r0], r1
; CHECK-NEXT:    mov.l 8[r0], r2
; CHECK-NEXT:    add r2, r1, r1
; CHECK-NEXT:    mov.l r1, 8[r0]
; CHECK-NEXT:    mov.l 8[r0], r1
; CHECK-NEXT:    add #24, r0, r0
; CHECK-NEXT:    rts
entry:
  %base.addr = alloca i32
  %sum = alloca i32
  %ap = alloca i8*
  %varet = alloca i32
  store i32 %base, i32* %base.addr
  %0 = load i32, i32* %base.addr
  store i32 %0, i32* %sum
  %ap1 = bitcast i8** %ap to i8*
  call void @llvm.va_start(i8* %ap1)
  %1 = va_arg i8** %ap, i32
  store i32 %1, i32* %varet
  %2 = load i32, i32* %varet
  %3 = load i32, i32* %sum
  %add = add nsw i32 %3, %2
  store i32 %add, i32* %sum
  %ap2 = bitcast i8** %ap to i8*
  call void @llvm.va_end(i8* %ap2)
  %4 = load i32, i32* %sum
  ret i32 %4
}

declare void @llvm.va_start(i8*) nounwind

declare void @llvm.va_end(i8*) nounwind

define i32 @call_vararg() noinline nounwind optnone {
; CHECK-LABEL: call_vararg:
; CHECK:       ; %bb.0: ; %entry
; CHECK-NEXT:    add #-32, r0, r0
; CHECK-NEXT:    mov.l #0, 28[r0]
; CHECK-NEXT:    mov #1, r1
; CHECK-NEXT:    mov #2, r2
; CHECK-NEXT:    bsr varargsum
; CHECK-NEXT:    add #32, r0, r0
; CHECK-NEXT:    rts
entry:
  %retval = alloca i32
  store i32 0, i32* %retval
  %call = call i32 (i32, ...) @varargsum(i32 1, i32 2)
  ret i32 %call
}
