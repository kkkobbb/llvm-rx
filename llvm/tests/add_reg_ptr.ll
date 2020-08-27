define i32 @run(i32 %var1, i32* %var2_ptr) {
  %var2 = load i32, i32* %var2_ptr
  %result = add i32 %var1, %var2
  ret i32 %result
}
