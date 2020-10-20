; RUN: llc -mtriple=rxv1 -verify-machineinstrs < %s | FileCheck %s

define i32 @jumptable(i32 %a) noinline optnone {
; CHECK-LABEL: jumptable:
; CHECK:      ; %bb.0:
; CHECK-NEXT:   mov #1, r2
; CHECK-NEXT:   cmp r1, r2
; CHECK-NEXT:   beq .LBB0_5
; CHECK-NEXT:   bra .LBB0_1
; CHECK-NEXT: .LBB0_1:
; CHECK-NEXT:   mov #2, r2
; CHECK-NEXT:   cmp r1, r2
; CHECK-NEXT:   beq .LBB0_6
; CHECK-NEXT:   bra .LBB0_2
; CHECK-NEXT: .LBB0_2:
; CHECK-NEXT:   mov #3, r2
; CHECK-NEXT:   cmp r1, r2
; CHECK-NEXT:   beq .LBB0_7
; CHECK-NEXT:   bra .LBB0_3
; CHECK-NEXT: .LBB0_3:
; CHECK-NEXT:   mov #4, r2
; CHECK-NEXT:   cmp r1, r2
; CHECK-NEXT:   beq .LBB0_8
; CHECK-NEXT:   bra .LBB0_4
; CHECK-NEXT: .LBB0_4: ; %case_default
; CHECK-NEXT:   mov #0, r1
; CHECK-NEXT:   rts
; CHECK-NEXT: .LBB0_5: ; %case_1
; CHECK-NEXT:   mov #1, r1
; CHECK-NEXT:   rts
; CHECK-NEXT: .LBB0_6: ; %case_2
; CHECK-NEXT:   mov #2, r1
; CHECK-NEXT:   rts
; CHECK-NEXT: .LBB0_7: ; %case_3
; CHECK-NEXT:   mov #3, r1
; CHECK-NEXT:   rts
; CHECK-NEXT: .LBB0_8: ; %case_4
; CHECK-NEXT:   mov #4, r1
; CHECK-NEXT:   rts
  ; 分岐が4より少ない場合、jumptableは生成されない
  switch i32 %a, label %case_default [
    i32 1, label %case_1
    i32 2, label %case_2
    i32 3, label %case_3
    i32 4, label %case_4
  ]

case_default:
  ret i32 0
case_1:
  ret i32 1
case_2:
  ret i32 2
case_3:
  ret i32 3
case_4:
  ret i32 4
}
