define i32 @run(i32 %var1, i32 %var2) {
  %result = srem i32 %var1, %var2
  ret i32 %result
}
