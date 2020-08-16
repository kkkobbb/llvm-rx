define i16 @run() noinline optnone {
  %a = alloca i16
  store i16 2, i16* %a
  %ret = load i16, i16* %a
  ret i16 %ret
}
