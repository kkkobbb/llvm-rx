# LLVM backend for the RX
* asm出力のみ対応
* アセンブルはgnu as


## Sub Target
* rxv1


## 準備
1. オリジナルのLLVMソースコード取得
    * `git clone https://github.com/llvm/llvm-project.git`
    * llvmソースコードのトップディレクトリを `$LLVM_ROOT` とする
2. ソースコード修正
    * `cd $LLVM_ROOT`
    * `git checkout llvmorg-10.0.0`
        * バージョンを指定する
    * `git apply ~/llvm-rx/patches/rx.patch`
        * `patches/` 内のパッチファイルを `$LLVM_ROOT` に適用する
3. 追加ソースコードの配置
    * `ln -s ~/llvm-rx/RX $LLVM_ROOT/llvm/lib/Target/RX`
        * `Target/` にシンボリックリンクを作成


## ビルド
* `cd $LLVM_ROOT && mkdir _build_rx && cd _build_rx`
* `cmake ../llvm -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=RX -DLLVM_TARGETS_TO_BUILD=RX -DLLVM_DEFAULT_TARGET_TRIPLE=rxv1-unknown-unknown`
* `cmake --build . --target llc`


## 使い方
* llcのみ対応
    * `llc tests/void_func.ll`
        * アセンブリ .sファイル が.llファイルと同じ場所に生成される
