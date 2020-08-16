define i32 @run() noinline optnone {
  %a = alloca i32
  store i32 2, i32* %a
  %ret = load i32, i32* %a
  ret i32 %ret
}
