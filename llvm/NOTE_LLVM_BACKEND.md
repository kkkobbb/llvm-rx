# LLVMバックエンドメモ

## LLVM 処理

### 処理の流れ
1. IR
    * LLVM IR
2. SelectionDAG
    * class SDNode
    * `$LLVM_ROOT/llvm/include/llvm/CodeGen/SelectionDAGNodes.h`
3. MachineDAG
    * class SDNode ?
    * `XXXInstrInfo.td`で定義した命令
4. MachineInstr
    * class MachineInstr
    * `$LLVM_ROOT/llvm/include/llvm/CodeGen/MachineInstr.h`
5. MCInst
    * class MCInst
    * `$LLVM_ROOT/llvm/include/llvm/MC/MCInst.h`

### llvm共通部分のコード
* `Tied` 2つのオペランドが同じレジスタにマッピングされたことを表す
    * `$LLVM_ROOT/llvm/include/llvm/MC/MCInstrDesc.h` `TIED_TO`
* 同じレジスタへのマッピング関係の処理？
    * `$LLVM_ROOT/llvm/lib/CodeGen/TwoAddressInstructionPass.cpp` `tryInstructionTransform`
* SelectionDAGノードのリスト、説明
    * `$LLVM_ROOT/llvm/include/llvm/CodeGen/ISDOpcodes.h`
* 最後にコード追加
    * `$LLVM_ROOT/llvm/include/llvm/MC/MCStreamer.h` finish()
    * 参考 `$LLVM_ROOT/llvm/lib/Target/AVR/MCTargetDesc/AVRTargetStreamer.cpp` finish()
* `ProcessorModel`
    * `SubtargetFeature`を置き換える新しいクラス?
    * 参考 `$LLVM_ROOT/llvm/include/llvm/Target/Target.td`


## 移植作業例

### エディタ設定
* vim用の llvm関係シンタックスハイライト定義ファイル
    * `$LLVM_ROOT/llvm/utils/vim/syntax/tablegen.vim`
        * バックエンド記述の `*.td` ファイル用
    * `$LLVM_ROOT/llvm/utils/vim/syntax/llvm.vim`
        * llvm中間表現 `*.ll` ファイル用
* 使い方
    * `~/.vim/syntax`に定義ファイルを置く
    * `$LLVM_ROOT/llvm/utils/vim/vimrc`を参考に`~/.vimrc`を修正する

### ターゲット追加
* 前提
    * ターゲット名`XXX`
    * asm出力のみでオブジェクトファイル(elf)は生成しない
    * とりあえずビルドを通す
* 最初にtdファイルを最低限記述するほうが楽かも
    * `XXXRegisterInfo.td`にレジスタ関連を記述
    * `XXXCallingConv.td`に関数呼び出し規約を記述
    * `XXXInstrFormat.td` `XXXInstrInfo.td`に命令を記述
        * 最初は簡単なもの(nop等)のみでもいい
        * `ADJCALLSTACKUP` `ADJCALLSTACKDOWN`はほぼコピペでいい
    * `XXX.td`は必要なtdファイルをinclude等
        * subtargetがある場合、`XXXSubTarget.{cpp,h}`等を記述してからの方がいい
* マシン情報の記述
    * 以下を記述 (ビルド通すだけなら適当でもいい) (`=0`のメソッドのみ実装等)
        * `XXX.h`
        * `XXXTargetMahine.{cpp,h}`
        * `XXXSubTarget.{cpp,h}`
        * `MCTargetDesc/XXXInstPrinter.{cpp,h}`
        * `MCTargetDesc/XXXMCAsmInfo.{cpp,h}`
        * `MCTargetDesc/XXXMCTargetDesc.{cpp,h}`
        * `MCTargetDesc/XXXTargetStreamer.{cpp,h}`
        * `TargetInfo/XXXTargetInfo.{cpp,h}`
* asm生成までの各段階でのターゲット固有の処理を記述
    * `XXXRegisterInfo.{cpp,h}`
    * `XXXISelLowering.{cpp, h}`
    * `XXXISelDAGToDAG.cpp`
    * `XXXFrameLowering.{cpp,h}`
    * `xXXInstrInfo.{cpp,h}`
* asm出力処理を記述 (ビルド通すだけならターゲット依存はあまりない)
    * `XXXAsmPrinter.cpp`
* elfを生成しなくともビルドするために必要 (ビルド通すだけならターゲット依存はあまりない)
    * `XXXTargetObjectFile.{cpp,h}`
* よくわからないけど必要 (ビルド通すだけならターゲット依存はあまりない)
    * `XXXMCInstLower.cpp`
    * `XXXMachineFunctionInfo.h`
* ディレクトリごとに`CMakeLists.txt` `LLVMBuild.txt`を修正
* llvm共通部分のコード修正
    * `$LLVM_ROOT/llvm/include/llvm/ADT/Triple.h`
    * `$LLVM_ROOT/llvm/lib/Support/Triple.cpp`
    * `$LLVM_ROOT/llvm/lib/Target/LLVMBuild.txt`

### ターゲット追加時のビルド
#### cmake
* `cmake ../llvm -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=XXX -DLLVM_TARGETS_TO_BUILD=XXX -DLLVM_DEFAULT_TARGET_TRIPLE=xxx-unknown-unknown`
    * `-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=XXX`
        * 試験的なターゲットの場合、このオプションで指定する必要がある
            * 公式にあるターゲットでも必要な場合がある
        * 自分で追加した場合はこのオプションを指定する
        * `Target/` に配置したディレクトリ名を指定する
    * `-DLLVM_TARGETS_TO_BUILD=XXX`
        * このオプションで指定したマシンのみビルド対象にする
        * `Target/` に配置したディレクトリ名を指定する
        * 複数指定する場合は `;` で区切る (その場合、`'`で囲わないとshが`;`を処理してしまう)
            * 例 `-DLLVM_TARGETS_TO_BUILD='RISCV;XXX'`
    * `-DLLVM_DEFAULT_TARGET_TRIPLE=xxx-unknown-unknown`
        * デフォルトのターゲットトリプルを変更するオプション
        * 指定なしの場合、ホストマシンと同じ値となる
    * 全てビルドするとかなり時間がかかるので一部だけビルドする
        * `cmake --build . --target llc` or `make llc`
        * `llc`のみなら4GBでもビルドは成功する

### 実行
* `./bin/llc --march=xxx -debug -print-after-all`
    * `--march` 出力するasmのアーキテクチャを指定する
    * `-debug` デバッグ情報を表示する
    * `-print-after-all` 各パスで処理後のIRを表示する


## ターゲット固有の実装時メモ

### ビルドエラー
* `llvm::CGIOperandList::getSubOperandNumber(unsigned int) const: Assertion i < OperandList.size() && "Invalid flat operand #"' failed.`
    * tdファイルで、親classで定義した全ての変数に値が設定されていない場合でるっぽい
* 対応するパターンがない場合、(set reg reg)の命令にマッチすることが多い

### デバッグ出力追加
* `#include "llvm/Support/Debug.h"`
* `#define DEBUG_TYPE "<識別用の文字列>"`
* `LLVM_DEBUG(dbgs() << "<デバッグメッセージ>");`

### debugオプション指定時のメッセージ
* `ISEL: Starting pattern match`でのindex番号は以下参考
    * `ビルド用ディレクトリ/lib/Target/RX/RXGenDAGISel.inc` `MatcherTable`

### ASM出力時のフォーマット調整
* `RX/MCTargetDesc/RXMCAsmInfo.cpp`
* 変更可能な部分の例
    * コメントを表す文字
    * ラベルの末尾の文字
    * アラインメントの有無
    * デバッグ情報の有無
    * 一部のディレクティブの有無

### アセンブリの記述
* `RX/RXInstrInfo.td`
    * 各命令の動作記述
* `RX/RXInstrFormats.td`
    * 命令のフォーマット
* `RX/RXRegisterInfo.td`
    * レジスタの定義
* `RX/RXInstrInfo.cpp`
    * tdファイルで記述できない部分の処理
    * レジスタの一時退避時のコード等

### LLVM IRにターゲット固有の変換を実施
* `RX/RXISelLowering.cpp`
    * 関数呼び出し時の引数の扱い等
* `RX/RXFrameLowering.cpp`
    * 関数呼び出し時のスタックの処理等
    * prologue、epilogue処理の記述もここ

### setOperationAction()について
* LLVM IRの変換を制御する
* `Promote`は指定した命令の型をより大きな型に変換する
* `Expand`は指定した命令を他の命令に変換する
* `Custom`は指定した命令をLowerOperation()に渡し、ターゲット固有の処理を行う
* 変換実例
    * `setOperationAction(ISD::BR_CC, MVT::i32, Expand)`
        * `(br_cc ...)` -> `(brcond (seteq等 ...) ...)`
    * `setOperationAction(ISD::BR_JT, MVT::Other, Expand);`
        * `(br_jt reg, jumptable)` -> `(brind reg)`

### analyzeBranch()
* 分岐命令の最適化ができる部分を探すための分析 (llvmに最適化のヒントを与える)
* この関数を実装することで(分岐命令 + 無条件分岐命令)を分岐命令のみに変換してくれるようになる
* これを実装した場合、`removeBranch()`、`insertBranch()`も実装する必要がある
    * `reverseBranchCondition()`もあったほうがいいかも
* 実装しなくても問題ない

### 分岐命令の変換
1. `br_cc`ノードが`brcond`命令に変換される
    * `setOperationAction(ISD::BR_CC, MVT::i32, Extend)`と指定したため
2. RXInstrInfo.tdでの記述から、`pBRCOND_*`仮想命令に変換する
    * `analyzeBranch()`で分岐命令の挿入、削除をする可能性があり処理を簡単にするため、一時的に分岐を1命令で表す
3. `expandPostRAPseudo()`で`CMP`命令、`B*`命令に変換する


## 参考
* 公式のバックエンドのソースコード `$LLVM_ROOT/llvm/lib/Target/*`
    * 特に`RISCV`、`AVR`
* きつねさん
* <https://jonathan2251.github.io/lbd/index.html>
* <https://llvm.org/devmtg/2014-04/PDFs/Talks/Building%20an%20LLVM%20backend.pdf>
* <https://scholarworks.rit.edu/cgi/viewcontent.cgi?article=10699&context=theses>