.text
.globl _start

_start:  ; 0x10000000 に割り当てられるはず
	; 0xffffff80 以降は固定ベクタテーブル
	; 割り込みスタックポインタの初期化
	mvtc #0xffffff00, isp
	; ユーザースタックポインタの初期化
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
	; 各レジスタの初期化
	xor r1, r1
	xor r2, r2
	xor r3, r3
	xor r4, r4
	xor r5, r5
	xor r6, r6
	xor r7, r7
	xor r8, r8
	xor r9, r9
	xor r10, r10
	xor r11, r11
	xor r12, r12
	xor r13, r13
	xor r14, r14
	xor r15, r15

	; 外部関数実行
	bsr run

	; ユーザーモードなのでINT命令で特権モードにして、wait実行して終了
	int #0

int0:
	wait  ; 停止 (特権モードが必要)

inttable:  ; 以降1024byteがベクタテーブル
	.long int0
	.skip 1020
