define i32 @zerofunc() noinline optnone {
entry:
  ret i32 0
}

define i32 @run() noinline optnone {
entry:
  %func_ptr = alloca i32 (...)*, align 4
  store i32 (...)* bitcast (i32 ()* @zerofunc to i32 (...)*), i32 (...)** %func_ptr, align 4
  %0 = load i32 (...)*, i32 (...)** %func_ptr, align 4
  %callee.knr.cast = bitcast i32 (...)* %0 to i32 ()*
  %call = call i32 %callee.knr.cast()
  ret i32 %call
}