define i32 @run() {
  %ret = call i32 @arg4(i32 1, i32 2, i32 3, i32 4)
  ret i32 %ret
}

define i32 @arg4(i32 %a, i32 %b, i32 %c, i32 %d) {
  %ret1 = add i32 %a, %b
  %ret2 = add i32 %c, %d
  %ret3 = add i32 %ret1, %ret2
  ret i32 %ret3
}
