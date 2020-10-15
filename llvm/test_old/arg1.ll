define i32 @run() {
  %ret = call i32 @arg1(i32 1)
  ret i32 %ret
}

define i32 @arg1(i32 %var) {
  ret i32 %var
}
