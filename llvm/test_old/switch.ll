define i32 @run(i32 %a) noinline optnone {
  ; 分岐が4より少ない場合、jumptableは生成されない
  switch i32 %a, label %case_default [
    i32 1, label %case_1
    i32 2, label %case_2
    i32 3, label %case_3
    i32 4, label %case_4
    i32 5, label %case_5
    i32 6, label %case_6
    i32 7, label %case_7
    i32 8, label %case_8
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

case_5:
  ret i32 5

case_6:
  ret i32 6

case_7:
  ret i32 7

case_8:
  ret i32 8
}
