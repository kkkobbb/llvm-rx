define i32 @run() noinline optnone {
  br i1 true, label %label1, label %label2

label1:
  ret i32 1

label2:
  ret i32 2
}
