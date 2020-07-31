define i32 @arg8(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g,
                 i32 %h) {
  %ret1 = add i32 %a, %b
  %ret2 = add i32 %c, %d
  %ret3 = add i32 %e, %f
  %ret4 = add i32 %g, %h
  %ret5 = add i32 %ret1, %ret2
  %ret6 = add i32 %ret3, %ret4
  %ret7 = add i32 %ret5, %ret6
  ret i32 %ret7
}
