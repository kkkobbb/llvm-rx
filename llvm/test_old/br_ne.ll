define i32 @run(i32 %a, i32 %b) {
entry:
  %c = alloca i32
  %0 = icmp ne i32 %a, %b
  br i1 %0, label %then, label %else

then:
  store i32 1, i32* %c
  br label %ifret

else:
  store i32 2, i32* %c
  br label %ifret

ifret:
  %result = load i32, i32* %c
  ret i32 %result
}
