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
    * `git checkout llvmorg-10.0.0`
        * バージョンを指定する
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
* `cmake --build . --target llc`

### 使い方
* `llc llvm/tests/void_func.ll`
    * アセンブリ .sファイル が.llファイルと同じ場所に生成される


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
