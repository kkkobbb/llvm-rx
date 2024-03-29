# LLVM backend for the RX
* `llc`と`clang`をビルド可能
* asm出力のみ対応
* gnu asでアセンブル可能


## Sub Target
* rxv1


## 準備
1. オリジナルのLLVMソースコード取得
    * `git clone https://github.com/llvm/llvm-project.git`
    * llvmソースコードのトップディレクトリを `$LLVM_ROOT` とする
2. バージョン変更
    * `cd $LLVM_ROOT`
    * `git checkout -b llvm-rx-14.0.6 llvmorg-14.0.6`
        * バージョンを指定してブランチ作成
3. ソースコード修正
    * llvm
        * `cd $LLVM_ROOT`
        * `git apply ~/llvm-rx/llvm/llvm.patch`
        * `ln -s ~/llvm-rx/llvm/RX $LLVM_ROOT/llvm/lib/Target/RX`
    * clang
        * `cd $LLVM_ROOT`
        * `git apply ~/llvm-rx/clang/clang.patch`
        * `ln -s ~/llvm-rx/clang/Targets/RX.h $LLVM_ROOT/clang/lib/Basic/Targets/RX.h`
        * `ln -s ~/llvm-rx/clang/Targets/RX.cpp $LLVM_ROOT/clang/lib/Basic/Targets/RX.cpp`


## llvm
llcのみ対応

### ビルド
* `cd $LLVM_ROOT && mkdir _build_rx && cd _build_rx`
* `cmake ../llvm -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=RX -DLLVM_TARGETS_TO_BUILD=RX -DLLVM_DEFAULT_TARGET_TRIPLE=rxv1-unknown-unknown`
    * ninjaを使う場合は`-G Ninja`を追加
    * ccacheを使う場合は`CC=/usr/lib/ccache/gcc CXX=/usr/lib/ccache/g++`をcmakeの前に追加
* `cmake --build . --target llc`

### 使い方
* `llc llvm/tests/void_func.ll`
    * アセンブリ .sファイル が.llファイルと同じ場所に生成される
* `llc ir.ll --debug`
    * デバッグ出力を有効にする
* `llc ir.ll --print-after-all`
    * 各パスでの処理後のIRを表示する
* `llc ir.ll --march=rxv1`
    * 出力対象のアーキテクチャを指定する
    * 指定可能なアーキテクチャは`llc --version`で確認できる


## clang
* asm生成まで対応 (`-S`オプションを付ける必要がある)
* 標準ライブラリ利用不可

### ビルド
* `cd $LLVM_ROOT && mkdir _build_rx_clang && cd _build_rx_clang`
* `cmake ../llvm -DLLVM_ENABLE_PROJECTS=clang -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=RX -DLLVM_TARGETS_TO_BUILD=RX -DLLVM_DEFAULT_TARGET_TRIPLE=rxv1-unknown-unknown`
* `cmake --build . --target clang`

### 使い方
* `clang -S a.c`
    * .sファイルが実行した場所に生成される
* `clang -S -emit-llvm a.c`
    * .llファイルが実行した場所に生成される
