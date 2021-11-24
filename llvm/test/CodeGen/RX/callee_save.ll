; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @main() {
  %ret = call i32 @callee(i32 1, i32 2, i32 3, i32 4)
  ret i32 %ret
}

define i32 @callee(i32 %a, i32 %b, i32 %c, i32 %d) optnone noinline {
  %ret1 = add i32 %a, %b
  %ret2 = add i32 %c, %d
  %ret3 = add i32 %a, %c
  %ret4 = add i32 %b, %d
  %ret5 = add i32 %a, %d
  %ret6 = add i32 %b, %c
  %ret7 = add i32 %ret1, %ret2
  %ret8 = add i32 %ret3, %ret4
  %ret9 = add i32 %ret5, %ret6
  %ret10 = add i32 %ret7, %ret8
  %ret11 = add i32 %ret9, %ret10
  %ret12 = add i32 %ret11, %ret1
  ret i32 %ret12
}
