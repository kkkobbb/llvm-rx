@aaa = global i32 3, align 4

define i32 @run() noinline optnone {
entry:
  %0 = load i32, i32* @aaa, align 4
  %add = add nsw i32 %0, 2
  ret i32 %add
}
