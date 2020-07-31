define i32 @arg16(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %g,
                  i32 %h, i32 %i, i32 %j, i32 %k, i32 %l, i32 %m, i32 %n,
                  i32 %o, i32 %p) {
  %ret1  = add i32 %a, %b
  %ret2  = add i32 %c, %d
  %ret3  = add i32 %e, %f
  %ret4  = add i32 %g, %h
  %ret5  = add i32 %i, %j
  %ret6  = add i32 %k, %l
  %ret7  = add i32 %m, %n
  %ret8  = add i32 %o, %p
  %ret9  = add i32 %ret1, %ret2
  %ret10 = add i32 %ret3, %ret4
  %ret11 = add i32 %ret5, %ret6
  %ret12 = add i32 %ret7, %ret8
  %ret13 = add i32 %ret9, %ret10
  %ret14 = add i32 %ret11, %ret12
  %ret15 = add i32 %ret13, %ret14
  ret i32 %ret15
}
