.text
.globl print_for_gdbsim

; gdb sim環境で標準出力に文字を出力する
; r2: 表示する文字列(終端0)の先頭アドレス
; return (r1): 表示した文字数
print_for_gdbsim:
	; 初期化
	push.l r3
	push.l r4
	mov.l r2, r1
	mov #0x00088263, r3

loop_print:
	mov.b [r1], r4
	add #1, r1
	cmp #0, r4
	bz end_print  ; 0なら終了

	mov.l r4, [r3]
	bra loop_print

end_print:
	sub r2, r1
	pop r4
	pop r3
	rts
