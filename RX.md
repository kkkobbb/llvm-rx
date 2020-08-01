# RX 仕様

## 命令セット等 参考
* <https://www.renesas.com/jp/ja/doc/products/mpumcu/doc/rx_family/001/r01us0032jj0130-rxv1sm.pdf>
* gcc
* binutils

## asm動作確認
binutilsを使用する
* gas ldでelf生成
* GDBのシミュレータで実行

### binutilsの準備
* `sudo apt install texinfo bison flex`
* `git clone git://sourceware.org/git/binutils-gdb.git`
    * cloneしたディレクトリを`$BIN_ROOT`とする
* `mkdir $BIN_ROOT/_build_rx && cd $BIN_ROOT/_build_rx`
* `../configure --target=rx-elf --disable-nls --prefix=${HOME}/rx-binutils`
    * インストール先は`~/rx-binutils`
* `make && make install`

### 実行
* `~/rx-binutils/bin/rx-elf-as rx_asm.s -o rx_asm.o`
    * `rx_asm.o`が出力される
* `~/rx-binutils/bin/rx-elf-ld rx_asm.o`
    * `_start`ラベルがない場合、警告がでる
    * `0x10000000`から配置されるはず
* `~/rx-binutils/bin/rx-elf-gdb a.out`
    * `target sim`
        * シミュレータ起動
    * `load`
        * シミュレータの実行ファイル読み込み
    * `break start` or `break *0x10000000`
        * 実行開始位置にブレークポイントを設定
    * `run`
        * 実行開始位置でブレークする
    * `i r`
        * レジスタ表示
    * `disas`
        * ディスアセンブル
    * `x/16bx`
        * メモリ表示 16byte 16進数表記
