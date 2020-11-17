; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @varargsum(i32 %base, ...) noinline nounwind optnone {
; CHECK-LABEL: varargsum:
; CHECK:       ; %bb.0: ; %entry
; CHECK-NEXT:    add #-36, r0, r0
; CHECK-NEXT:    mov.l r4, 36[r0]
; CHECK-NEXT:    mov.l r3, 32[r0]
; CHECK-NEXT:    mov.l r2, 28[r0]
; CHECK-NEXT:    mov.l r1, 24[r0]
; CHECK-NEXT:    mov.l 24[r0], r1
; CHECK-NEXT:    mov.l r1, 20[r0]
; CHECK-NEXT:    add #28, r0, r1
; CHECK-NEXT:    mov.l r1, 16[r0]
; CHECK-NEXT:    mov.l 16[r0], r1
; CHECK-NEXT:    add #3, r1, r2
; CHECK-NEXT:    mov #-4, r1
; CHECK-NEXT:    and r1, r2, r2
; CHECK-NEXT:    add #4, r2, r3
; CHECK-NEXT:    mov.l r3, 16[r0]
; CHECK-NEXT:    mov.l 0[r2], r2
; CHECK-NEXT:    mov.l r2, 12[r0]
; CHECK-NEXT:    mov.l 12[r0], r2
; CHECK-NEXT:    mov.l 20[r0], r3
; CHECK-NEXT:    add r3, r2, r2
; CHECK-NEXT:    mov.l r2, 20[r0]
; CHECK-NEXT:    mov.l 16[r0], r2
; CHECK-NEXT:    add #3, r2, r2
; CHECK-NEXT:    and r1, r2, r2
; CHECK-NEXT:    add #4, r2, r3
; CHECK-NEXT:    mov.l r3, 16[r0]
; CHECK-NEXT:    mov.l 0[r2], r2
; CHECK-NEXT:    mov.l r2, 8[r0]
; CHECK-NEXT:    mov.l 8[r0], r2
; CHECK-NEXT:    mov.l 20[r0], r3
; CHECK-NEXT:    add r3, r2, r2
; CHECK-NEXT:    mov.l r2, 20[r0]
; CHECK-NEXT:    mov.l 16[r0], r2
; CHECK-NEXT:    add #3, r2, r2
; CHECK-NEXT:    and r1, r2, r2
; CHECK-NEXT:    add #4, r2, r3
; CHECK-NEXT:    mov.l r3, 16[r0]
; CHECK-NEXT:    mov.l 0[r2], r2
; CHECK-NEXT:    mov.l r2, 4[r0]
; CHECK-NEXT:    mov.l 4[r0], r2
; CHECK-NEXT:    mov.l 20[r0], r3
; CHECK-NEXT:    add r3, r2, r2
; CHECK-NEXT:    mov.l r2, 20[r0]
; CHECK-NEXT:    mov.l 16[r0], r2
; CHECK-NEXT:    add #3, r2, r2
; CHECK-NEXT:    and r1, r2, r1
; CHECK-NEXT:    add #4, r1, r2
; CHECK-NEXT:    mov.l r2, 16[r0]
; CHECK-NEXT:    mov.l 0[r1], r1
; CHECK-NEXT:    mov.l r1, 0[r0]
; CHECK-NEXT:    mov.l 0[r0], r1
; CHECK-NEXT:    mov.l 20[r0], r2
; CHECK-NEXT:    add r2, r1, r1
; CHECK-NEXT:    mov.l r1, 20[r0]
; CHECK-NEXT:    mov.l 20[r0], r1
; CHECK-NEXT:    add #36, r0, r0
; CHECK-NEXT:    rts
entry:
  %base.addr = alloca i32
  %sum = alloca i32
  %ap = alloca i8*
  %varet = alloca i32
  %varet2 = alloca i32
  %varet4 = alloca i32
  %varet6 = alloca i32
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
  %4 = va_arg i8** %ap, i32
  store i32 %4, i32* %varet2
  %5 = load i32, i32* %varet2
  %6 = load i32, i32* %sum
  %add3 = add nsw i32 %6, %5
  store i32 %add3, i32* %sum
  %7 = va_arg i8** %ap, i32
  store i32 %7, i32* %varet4
  %8 = load i32, i32* %varet4
  %9 = load i32, i32* %sum
  %add5 = add nsw i32 %9, %8
  store i32 %add5, i32* %sum
  %10 = va_arg i8** %ap, i32
  store i32 %10, i32* %varet6
  %11 = load i32, i32* %varet6
  %12 = load i32, i32* %sum
  %add7 = add nsw i32 %12, %11
  store i32 %add7, i32* %sum
  %ap8 = bitcast i8** %ap to i8*
  call void @llvm.va_end(i8* %ap8)
  %13 = load i32, i32* %sum
  ret i32 %13
}

declare void @llvm.va_start(i8*) nounwind

declare void @llvm.va_end(i8*) nounwind

define i32 @call_vararg() noinline nounwind optnone {
; CHECK-LABEL: call_vararg:
; CHECK:       ; %bb.0: ; %entry
; CHECK-NEXT:    add #-32, r0, r0
; CHECK-NEXT:    mov.l #0, 28[r0]
; CHECK-NEXT:    mov.l #5, 0[r0]
; CHECK-NEXT:    mov #1, r1
; CHECK-NEXT:    mov #2, r2
; CHECK-NEXT:    mov #3, r3
; CHECK-NEXT:    mov #4, r4
; CHECK-NEXT:    bsr varargsum
; CHECK-NEXT:    add #32, r0, r0
; CHECK-NEXT:    rts
entry:
  %retval = alloca i32
  store i32 0, i32* %retval
  %call = call i32 (i32, ...) @varargsum(i32 1, i32 2, i32 3, i32 4, i32 5)
  ret i32 %call
}
