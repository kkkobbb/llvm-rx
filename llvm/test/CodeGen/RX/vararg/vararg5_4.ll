; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @varargsum(i32 %a, i32 %b, i32 %c, i32 %d, i32 %base, ...) noinline nounwind optnone {
; CHECK-LABEL: varargsum:
; CHECK:       ; %bb.0: ; %entry
; CHECK-NEXT:    add #-40, r0, r0
; CHECK-NEXT:    mov.l 44[r0], r5
; CHECK-NEXT:    mov.l r1, 36[r0]
; CHECK-NEXT:    mov.l r2, 32[r0]
; CHECK-NEXT:    mov.l r3, 28[r0]
; CHECK-NEXT:    mov.l r4, 24[r0]
; CHECK-NEXT:    mov.l 36[r0], r1
; CHECK-NEXT:    mov.l 32[r0], r2
; CHECK-NEXT:    add r1, r2, r1
; CHECK-NEXT:    mov.l 28[r0], r2
; CHECK-NEXT:    add r1, r2, r1
; CHECK-NEXT:    mov.l 24[r0], r2
; CHECK-NEXT:    add r1, r2, r1
; CHECK-NEXT:    mov.l 44[r0], r2
; CHECK-NEXT:    add r1, r2, r1
; CHECK-NEXT:    mov.l r1, 20[r0]
; CHECK-NEXT:    add #48, r0, r1
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
; CHECK-NEXT:    add #40, r0, r0
; CHECK-NEXT:    rts
entry:
  %a.addr = alloca i32
  %b.addr = alloca i32
  %c.addr = alloca i32
  %d.addr = alloca i32
  %base.addr = alloca i32
  %sum = alloca i32
  %ap = alloca i8*
  %varet = alloca i32
  %varet6 = alloca i32
  %varet8 = alloca i32
  %varet10 = alloca i32
  store i32 %a, i32* %a.addr
  store i32 %b, i32* %b.addr
  store i32 %c, i32* %c.addr
  store i32 %d, i32* %d.addr
  store i32 %base, i32* %base.addr
  %0 = load i32, i32* %a.addr
  %1 = load i32, i32* %b.addr
  %add = add nsw i32 %0, %1
  %2 = load i32, i32* %c.addr
  %add1 = add nsw i32 %add, %2
  %3 = load i32, i32* %d.addr
  %add2 = add nsw i32 %add1, %3
  %4 = load i32, i32* %base.addr
  %add3 = add nsw i32 %add2, %4
  store i32 %add3, i32* %sum
  %ap4 = bitcast i8** %ap to i8*
  call void @llvm.va_start(i8* %ap4)
  %5 = va_arg i8** %ap, i32
  store i32 %5, i32* %varet
  %6 = load i32, i32* %varet
  %7 = load i32, i32* %sum
  %add5 = add nsw i32 %7, %6
  store i32 %add5, i32* %sum
  %8 = va_arg i8** %ap, i32
  store i32 %8, i32* %varet6
  %9 = load i32, i32* %varet6
  %10 = load i32, i32* %sum
  %add7 = add nsw i32 %10, %9
  store i32 %add7, i32* %sum
  %11 = va_arg i8** %ap, i32
  store i32 %11, i32* %varet8
  %12 = load i32, i32* %varet8
  %13 = load i32, i32* %sum
  %add9 = add nsw i32 %13, %12
  store i32 %add9, i32* %sum
  %14 = va_arg i8** %ap, i32
  store i32 %14, i32* %varet10
  %15 = load i32, i32* %varet10
  %16 = load i32, i32* %sum
  %add11 = add nsw i32 %16, %15
  store i32 %add11, i32* %sum
  %ap12 = bitcast i8** %ap to i8*
  call void @llvm.va_end(i8* %ap12)
  %17 = load i32, i32* %sum
  ret i32 %17
}

declare void @llvm.va_start(i8*) nounwind

declare void @llvm.va_end(i8*) nounwind

define i32 @call_vararg() noinline nounwind optnone {
; CHECK-LABEL: call_vararg:
; CHECK:       ; %bb.0: ; %entry
; CHECK-NEXT:    add #-32, r0, r0
; CHECK-NEXT:    mov.l #0, 28[r0]
; CHECK-NEXT:    add #16, r0, r1
; CHECK-NEXT:    mov.l #9, 0[r1]
; CHECK-NEXT:    add #12, r0, r1
; CHECK-NEXT:    mov.l #8, 0[r1]
; CHECK-NEXT:    add #8, r0, r1
; CHECK-NEXT:    mov.l #7, 0[r1]
; CHECK-NEXT:    add #4, r0, r1
; CHECK-NEXT:    mov.l #6, 0[r1]
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
  %call = call i32 (i32, i32, i32, i32, i32, ...) @varargsum(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9)
  ret i32 %call
}
