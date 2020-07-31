.text
.globl _start

_start:
	; ユーザースタックポインタの設定
	mvtc #0xf0000000, usp
	; INT命令用ベクタテーブルの設定
	mvtc #inttable, intb

	; スタックにユーザモード用のpsw,pcをセットする
	mvfc psw, r1
	or #0x00100000, r1  ; ユーザーモードにする (PMビットを1にする)
	push.l r1
	mov.l #usermode_code, r1  ; ユーザーモードで実行する場所
	push.l r1

	; ユーザーモードに移行
	rte

usermode_code:
	; 外部関数実行
	bsr run

	; ユーザーモードなのでINT命令で特権モードになり、wait実行して終了
	int #0

int0:
	wait  ; 終了 (特権モードが必要)

inttable:  ; 以降1024byteがベクタテーブル
	.long int0
	.skip 1020
