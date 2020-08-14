define i32 @run() {
entry:
  %b = alloca i32
  store i32 0, i32* %b
  br label %lbl2

lbl1:
  store i32 1, i32* %b
  br label %lbl3

lbl2:
  store i32 2, i32* %b
  br label %lbl3

lbl3:
  %result = load i32, i32* %b
  ret i32 %result
}
