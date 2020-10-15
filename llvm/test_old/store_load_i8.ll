define i8 @run() noinline optnone {
  %a = alloca i8
  store i8 2, i8* %a
  %ret = load i8, i8* %a
  ret i8 %ret
}
