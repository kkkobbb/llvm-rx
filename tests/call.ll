define i32 @run() {
  %ret = call i32 @callee(i32 1)
  ret i32 %ret
}

define i32 @callee(i32) {
  %a = add i32 %0, 1
  ret i32 %a
}
