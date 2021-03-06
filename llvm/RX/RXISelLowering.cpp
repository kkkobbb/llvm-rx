//===-- RXISelLowering.cpp - RX DAG Lowering Implementation  --------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the interfaces that RX uses to lower LLVM code into a
// selection DAG.
//
//===----------------------------------------------------------------------===//

#include "RXISelLowering.h"
#include "RX.h"
#include "RXMachineFunctionInfo.h"
#include "RXRegisterInfo.h"
#include "RXSubtarget.h"
#include "RXTargetMachine.h"
#include "MCTargetDesc/RXMCTargetDesc.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/ValueTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/DiagnosticPrinter.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "rx-isellowering"

//===----------------------------------------------------------------------===//
//             Formal Arguments Calling Convention Implementation
//===----------------------------------------------------------------------===//

#include "RXGenCallingConv.inc"

RXTargetLowering::RXTargetLowering(const TargetMachine &TM,
                                   const RXSubtarget &STI)
    : TargetLowering(TM), Subtarget(STI) {

  // Set up the register classes.
  addRegisterClass(MVT::i32, &RX::GPRRegClass);

  // Compute derived properties from the register classes.
  computeRegisterProperties(STI.getRegisterInfo());

  // スタックポインタの登録
  setStackPointerRegisterToSaveRestore(RX::R0);

  // NOTE Promote 型を大きな型として扱う
  setOperationAction(ISD::EXTLOAD,  MVT::i1,  Promote);
  setOperationAction(ISD::EXTLOAD,  MVT::i8,  Promote);
  setOperationAction(ISD::EXTLOAD,  MVT::i16, Promote);
  setOperationAction(ISD::ZEXTLOAD, MVT::i1,  Promote);
  setOperationAction(ISD::ZEXTLOAD, MVT::i8,  Promote);
  setOperationAction(ISD::ZEXTLOAD, MVT::i16, Promote);
  setOperationAction(ISD::SEXTLOAD, MVT::i1,  Promote);
  setOperationAction(ISD::SEXTLOAD, MVT::i8,  Promote);
  setOperationAction(ISD::SEXTLOAD, MVT::i16, Promote);

  // NOTE Expand 他の命令に展開する
  // NOTE (*rem a, b) -> (*divrem a, b) -> (sub a, (mul (div a, b), b)) に展開される
  setOperationAction(ISD::UREM, MVT::i32, Expand);
  setOperationAction(ISD::SREM, MVT::i32, Expand);
  setOperationAction(ISD::UDIVREM, MVT::i32, Expand);
  setOperationAction(ISD::SDIVREM, MVT::i32, Expand);
  // NOTE (br_cc set*, lhs, rhs, dest) -> (brcond (set* lhs, rhs), dest)
  setOperationAction(ISD::BR_CC, MVT::i32, Expand);
  // 即値で割る除算はデフォルトでは即値の乗算に変換する (除算が乗算より遅い想定)
  // a:32bit変数 b:32bit即値  a / b = a * (2^32 / b) の上位32bit
  // NOTE (*div reg, imm)
  //      -> t = (sra (add (mulhs reg, i32), (mul reg, 0)), 1), (add t, (srl t 31))
  //      -> t = (sra (add (smul_lohi reg, i32):1, (mul reg 0)), 1), (add t, (srl t, 31))
  setOperationAction(ISD::MULHS, MVT::i32, Expand);
  setOperationAction(ISD::MULHU, MVT::i32, Expand);

  // NOTE Custom LowerOperation()に渡す
  // NOTE グローバル変数へのアクセス
  setOperationAction(ISD::GlobalAddress, MVT::i32, Custom);

  // NOTE SELECT_CCをSELECTにする
  setOperationAction(ISD::SELECT, MVT::i32, Custom);
  setOperationAction(ISD::SELECT_CC, MVT::i32, Expand);

  // 可変長引数の対応
  setOperationAction(ISD::VASTART, MVT::Other, Custom);
  setOperationAction(ISD::VAARG, MVT::Other, Expand);
  setOperationAction(ISD::VACOPY, MVT::Other, Expand);
  setOperationAction(ISD::VAEND, MVT::Other, Expand);

  // NOTE llvm/include/llvm/CodeGen/TargetLowering.h setMaxAtomicSizeInBitsSupported
  // NOTE バックエンドがサポートする最大のアトミック操作のサイズ
  // これより大きい場合、__atomic_*ライブラリに展開される
  setMaxAtomicSizeInBitsSupported(0);

  // booleanの表現型
  setBooleanContents(ZeroOrOneBooleanContent);

  // jumptableを生成する最小値を大きな値にしてjumptableを生成しないようにしてるっぽい
  // Effectively disable jump table generation.
  setMinimumJumpTableEntries(INT_MAX);
}

SDValue RXTargetLowering::LowerOperation(SDValue Op,
                                         SelectionDAG &DAG) const {
  // Custom に指定したノードに対する操作
  switch (Op.getOpcode()) {
  default:
    report_fatal_error("unimplemented operand");
  case ISD::GlobalAddress:
    return lowerGlobalAddress(Op, DAG);
  case ISD::SELECT:
    return lowerSELECT(Op, DAG);
  case ISD::VASTART:
    return lowerVASTART(Op, DAG);
  }
}

SDValue RXTargetLowering::lowerGlobalAddress(SDValue Op,
                                             SelectionDAG &DAG) const {
  // NOTE RISCV参考
  SDLoc DL(Op);
  EVT Ty = Op.getValueType();
  GlobalAddressSDNode *N = cast<GlobalAddressSDNode>(Op);
  int64_t Offset = N->getOffset();

  // NOTE 絶対アドレスを格納するのでPICは不可
  if(isPositionIndependent())
    report_fatal_error("Unsupported position independent code");

  // NOTE 絶対アドレスを格納するのでBSR命令では使えない
  // TODO 相対アドレスを格納することは可能? その場合、BSR以外の命令に影響は?
  //      以下使えそうな命令
  //        'MVFC PC,R1' この命令の番地をR1に格納する
  //        'PUSHC PC'   この命令の番地をスタックに格納する
  //      アセンブリレベルでは'BSR 絶対アドレス'と書けばアセンブル時に相対アドレスのオペランドにするはず
  SDValue Target = DAG.getTargetGlobalAddress(N->getGlobal(), DL, Ty, 0, 0);
  SDValue Addr = SDValue(DAG.getMachineNode(RX::MOV_I32R, SDLoc(N), Ty, Target), 0);

  if (Offset != 0)
    return DAG.getNode(ISD::ADD, DL, Ty, Addr,
                       DAG.getConstant(Offset, DL, MVT::i32));
  return Addr;
}

// Changes the condition code and swaps operands if necessary, so the SetCC
// operation matches one of the comparisons supported directly in the RISC-V
// ISA.
static void normaliseSetCC(SDValue &LHS, SDValue &RHS, ISD::CondCode &CC) {
  // NOTE ほぼRISCV
  switch (CC) {
  default:
    break;
  case ISD::SETGT:
  case ISD::SETLE:
  case ISD::SETUGT:
  case ISD::SETULE:
    CC = ISD::getSetCCSwappedOperands(CC);
    std::swap(LHS, RHS);
    break;
  }
}

// Return the RX branch opcode that matches the given DAG integer
// condition code. The CondCode must be one of those supported by the RX
// ISA (see normaliseSetCC).
static unsigned getBranchOpcodeForIntCondCode(ISD::CondCode CC) {
  // NOTE ほぼRISCV
  switch (CC) {
  default:
    llvm_unreachable("Unsupported CondCode");
  case ISD::SETEQ:
    return RX::pBRCOND_EQ;
  case ISD::SETNE:
    return RX::pBRCOND_NE;
  case ISD::SETLT:
    return RX::pBRCOND_LT;
  case ISD::SETGE:
    return RX::pBRCOND_GE;
  case ISD::SETULT:
    return RX::pBRCOND_ULT;
  case ISD::SETUGE:
    return RX::pBRCOND_UGE;
  }
}

SDValue RXTargetLowering::lowerSELECT(SDValue Op, SelectionDAG &DAG) const {
  // TODO ほぼRISCV
  SDValue CondV = Op.getOperand(0);
  SDValue TrueV = Op.getOperand(1);
  SDValue FalseV = Op.getOperand(2);
  SDLoc DL(Op);
  MVT XLenVT = MVT::i32;

  // If the result type is XLenVT and CondV is the output of a SETCC node
  // which also operated on XLenVT inputs, then merge the SETCC node into the
  // lowered RXISD::SELECT_CC to take advantage of the integer
  // compare+branch instructions. i.e.:
  // (select (setcc lhs, rhs, cc), truev, falsev)
  // -> (rxisd::select_cc lhs, rhs, cc, truev, falsev)
  if (Op.getSimpleValueType() == XLenVT && CondV.getOpcode() == ISD::SETCC &&
      CondV.getOperand(0).getSimpleValueType() == XLenVT) {
    SDValue LHS = CondV.getOperand(0);
    SDValue RHS = CondV.getOperand(1);
    auto CC = cast<CondCodeSDNode>(CondV.getOperand(2));
    ISD::CondCode CCVal = CC->get();

    normaliseSetCC(LHS, RHS, CCVal);

    SDValue TargetCC = DAG.getConstant(CCVal, DL, XLenVT);
    SDVTList VTs = DAG.getVTList(Op.getValueType(), MVT::Glue);
    SDValue Ops[] = {LHS, RHS, TargetCC, TrueV, FalseV};
    return DAG.getNode(RXISD::SELECT_CC, DL, VTs, Ops);
  }

  // Otherwise:
  // (select condv, truev, falsev)
  // -> (rxisd::select_cc condv, zero, setne, truev, falsev)
  SDValue Zero = DAG.getConstant(0, DL, XLenVT);
  SDValue SetNE = DAG.getConstant(ISD::SETNE, DL, XLenVT);

  SDVTList VTs = DAG.getVTList(Op.getValueType(), MVT::Glue);
  SDValue Ops[] = {CondV, Zero, SetNE, TrueV, FalseV};

  return DAG.getNode(RXISD::SELECT_CC, DL, VTs, Ops);
}

SDValue RXTargetLowering::lowerVASTART(SDValue Op, SelectionDAG &DAG) const {
  // TODO ほぼRISCV
  MachineFunction &MF = DAG.getMachineFunction();
  RXMachineFunctionInfo *FuncInfo = MF.getInfo<RXMachineFunctionInfo>();

  SDLoc DL(Op);
  SDValue FI = DAG.getFrameIndex(FuncInfo->getVarArgsFrameIndex(),
                                 getPointerTy(MF.getDataLayout()));

  // vastart just stores the address of the VarArgsFrameIndex slot into the
  // memory location argument.
  const Value *SV = cast<SrcValueSDNode>(Op.getOperand(2))->getValue();
  return DAG.getStore(Op.getOperand(0), DL, FI, Op.getOperand(1),
                      MachinePointerInfo(SV));
}

static bool isSelectPseudo(MachineInstr &MI) {
  switch (MI.getOpcode()) {
  default:
    return false;
  case RX::Select_GPR_Using_CC_GPR:
    return true;
  }
}

static MachineBasicBlock *emitSelectPseudo(MachineInstr &MI,
                                           MachineBasicBlock *BB) {
  // NOTE ほぼRISCV

  // To "insert" Select_* instructions, we actually have to insert the triangle
  // control-flow pattern.  The incoming instructions know the destination vreg
  // to set, the condition code register to branch on, the true/false values to
  // select between, and the condcode to use to select the appropriate branch.
  //
  // We produce the following control flow:
  //     HeadMBB
  //     |  \
  //     |  IfFalseMBB
  //     | /
  //    TailMBB
  //
  // When we find a sequence of selects we attempt to optimize their emission
  // by sharing the control flow. Currently we only handle cases where we have
  // multiple selects with the exact same condition (same LHS, RHS and CC).
  // The selects may be interleaved with other instructions if the other
  // instructions meet some requirements we deem safe:
  // - They are debug instructions. Otherwise,
  // - They do not have side-effects, do not access memory and their inputs do
  //   not depend on the results of the select pseudo-instructions.
  // The TrueV/FalseV operands of the selects cannot depend on the result of
  // previous selects in the sequence.
  // These conditions could be further relaxed. See the X86 target for a
  // related approach and more information.
  Register LHS = MI.getOperand(1).getReg();
  Register RHS = MI.getOperand(2).getReg();
  auto CC = static_cast<ISD::CondCode>(MI.getOperand(3).getImm());

  SmallVector<MachineInstr *, 4> SelectDebugValues;
  SmallSet<Register, 4> SelectDests;
  SelectDests.insert(MI.getOperand(0).getReg());

  MachineInstr *LastSelectPseudo = &MI;

  for (auto E = BB->end(), SequenceMBBI = MachineBasicBlock::iterator(MI);
       SequenceMBBI != E; ++SequenceMBBI) {
    if (SequenceMBBI->isDebugInstr())
      continue;
    else if (isSelectPseudo(*SequenceMBBI)) {
      if (SequenceMBBI->getOperand(1).getReg() != LHS ||
          SequenceMBBI->getOperand(2).getReg() != RHS ||
          SequenceMBBI->getOperand(3).getImm() != CC ||
          SelectDests.count(SequenceMBBI->getOperand(4).getReg()) ||
          SelectDests.count(SequenceMBBI->getOperand(5).getReg()))
        break;
      LastSelectPseudo = &*SequenceMBBI;
      SequenceMBBI->collectDebugValues(SelectDebugValues);
      SelectDests.insert(SequenceMBBI->getOperand(0).getReg());
    } else {
      if (SequenceMBBI->hasUnmodeledSideEffects() ||
          SequenceMBBI->mayLoadOrStore())
        break;
      if (llvm::any_of(SequenceMBBI->operands(), [&](MachineOperand &MO) {
            return MO.isReg() && MO.isUse() && SelectDests.count(MO.getReg());
          }))
        break;
    }
  }

  const TargetInstrInfo &TII = *BB->getParent()->getSubtarget().getInstrInfo();
  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  DebugLoc DL = MI.getDebugLoc();
  MachineFunction::iterator I = ++BB->getIterator();

  MachineBasicBlock *HeadMBB = BB;
  MachineFunction *F = BB->getParent();
  MachineBasicBlock *TailMBB = F->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *IfFalseMBB = F->CreateMachineBasicBlock(LLVM_BB);

  F->insert(I, IfFalseMBB);
  F->insert(I, TailMBB);

  // Transfer debug instructions associated with the selects to TailMBB.
  for (MachineInstr *DebugInstr : SelectDebugValues) {
    TailMBB->push_back(DebugInstr->removeFromParent());
  }

  // Move all instructions after the sequence to TailMBB.
  TailMBB->splice(TailMBB->end(), HeadMBB,
                  std::next(LastSelectPseudo->getIterator()), HeadMBB->end());
  // Update machine-CFG edges by transferring all successors of the current
  // block to the new block which will contain the Phi nodes for the selects.
  TailMBB->transferSuccessorsAndUpdatePHIs(HeadMBB);
  // Set the successors for HeadMBB.
  HeadMBB->addSuccessor(IfFalseMBB);
  HeadMBB->addSuccessor(TailMBB);

  // Insert appropriate branch.
  unsigned Opcode = getBranchOpcodeForIntCondCode(CC);

  BuildMI(HeadMBB, DL, TII.get(Opcode))
    .addReg(LHS)
    .addReg(RHS)
    .addMBB(TailMBB);

  // IfFalseMBB just falls through to TailMBB.
  IfFalseMBB->addSuccessor(TailMBB);

  // Create PHIs for all of the select pseudo-instructions.
  auto SelectMBBI = MI.getIterator();
  auto SelectEnd = std::next(LastSelectPseudo->getIterator());
  auto InsertionPoint = TailMBB->begin();
  while (SelectMBBI != SelectEnd) {
    auto Next = std::next(SelectMBBI);
    if (isSelectPseudo(*SelectMBBI)) {
      // %Result = phi [ %TrueValue, HeadMBB ], [ %FalseValue, IfFalseMBB ]
      BuildMI(*TailMBB, InsertionPoint, SelectMBBI->getDebugLoc(),
              TII.get(RX::PHI), SelectMBBI->getOperand(0).getReg())
          .addReg(SelectMBBI->getOperand(4).getReg())
          .addMBB(HeadMBB)
          .addReg(SelectMBBI->getOperand(5).getReg())
          .addMBB(IfFalseMBB);
      SelectMBBI->eraseFromParent();
    }
    SelectMBBI = Next;
  }

  F->getProperties().reset(MachineFunctionProperties::Property::NoPHIs);
  return TailMBB;
}

MachineBasicBlock *
RXTargetLowering::EmitInstrWithCustomInserter(MachineInstr &MI,
                                              MachineBasicBlock *BB) const {
  switch (MI.getOpcode()) {
  default:
    llvm_unreachable("Unexpected instr type to insert");
  case RX::Select_GPR_Using_CC_GPR:
    return emitSelectPseudo(MI, BB);
  }
}

static const MCPhysReg ArgGPRs[] = {
  RX::R1, RX::R2, RX::R3, RX::R4
};

// NOTE llvm/include/llvm/CodeGen/TargetLowering.h LowerFormalArguments
// Transform physical registers into virtual registers.
SDValue RXTargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &DL,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const {
  LLVM_DEBUG(dbgs() << "### LowerFormalArguments\n");

  switch (CallConv) {
  default:
    report_fatal_error("Unsupported calling convention");
  case CallingConv::C:
  case CallingConv::Fast:
    break;
  }

  MachineFunction &MF = DAG.getMachineFunction();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  MachineRegisterInfo &RegInfo = MF.getRegInfo();

  const Function &Func = MF.getFunction();
  if (Func.hasFnAttribute("interrupt")) {
    if (!Func.arg_empty())
      report_fatal_error(
        "Functions with the interrupt attribute cannot have arguments!");

    StringRef Kind =
      MF.getFunction().getFnAttribute("interrupt").getValueAsString();

    if (!(Kind == "user" || Kind == "supervisor" || Kind == "machine"))
      report_fatal_error(
        "Function interrupt attribute argument not supported!");
  }

  // Assign locations to all of the incoming arguments.
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeFormalArguments(Ins, CC_RX);

  for (unsigned i = 0, e = ArgLocs.size(); i != e; ++i) {
    CCValAssign &VA = ArgLocs[i];
    if (VA.isRegLoc()) {
      // 引数がレジスタ経由で渡された場合
      LLVM_DEBUG(dbgs() << "### LowerFormalArguments Reg\n");

      if (VA.getLocInfo() != CCValAssign::Full) {
        llvm_unreachable("not supported yet");
      }

      // 使用するレジスタクラスを指定
      const TargetRegisterClass *RC = &RX::GPRRegClass;
      // 仮想レジスタを作成
      Register VReg = RegInfo.createVirtualRegister(RC);
      RegInfo.addLiveIn(VA.getLocReg(), VReg);
      EVT RegVT = VA.getLocVT();
      SDValue ArgValue = DAG.getCopyFromReg(Chain, DL, VReg, RegVT);
      InVals.push_back(ArgValue);
    } else {
      // 引数がスタック経由で渡された場合
      LLVM_DEBUG(dbgs() << "### LowerFormalArguments Mem\n");

      assert(VA.isMemLoc());

      unsigned ObjSize = VA.getLocVT().getSizeInBits() / 8;
      // 関数呼び出し時にスタックに戻り先アドレス(4byte)をpushするため、
      // SPOffset(第二引数)を+4している
      int FI = MFI.CreateFixedObject(ObjSize, VA.getLocMemOffset() + 4, true);

      // スタックから引数を取得する
      SDValue FIN = DAG.getFrameIndex(FI, MVT::i32);
      InVals.push_back(DAG.getLoad(VA.getLocVT(), DL, Chain, FIN,
                  MachinePointerInfo::getFixedStack(MF, FI)));
    }
  }

  // Used with vargs to acumulate store chains.
  std::vector<SDValue> OutChains;

  if (IsVarArg) {
    // 可変引数の処理
    // TODO ほぼRISCV
    const unsigned Bytes = 4;
    ArrayRef<MCPhysReg> ArgRegs = makeArrayRef(ArgGPRs);
    unsigned Idx = CCInfo.getFirstUnallocated(ArgRegs);
    const TargetRegisterClass *RC = &RX::GPRRegClass;
    MachineFrameInfo &MFI = MF.getFrameInfo();
    MachineRegisterInfo &RegInfo = MF.getRegInfo();
    RXMachineFunctionInfo *RXFI = MF.getInfo<RXMachineFunctionInfo>();

    // Offset of the first variable argument from stack pointer, and size of
    // the vararg save area. For now, the varargs save area is either zero or
    // large enough to hold r1-r4.
    int VaArgOffset;

    // If all registers are allocated, then all varargs must be passed on the
    // stack and we don't need to save any argregs.
    if (ArgRegs.size() == Idx) {
      LLVM_DEBUG(dbgs() << "### LowerFormalArguments Vararg ArgRegs.size() == Idx (Idx = " << Idx << ")\n");
      VaArgOffset = CCInfo.getNextStackOffset();
    } else {
      LLVM_DEBUG(dbgs() << "### LowerFormalArguments Vararg ArgRegs.size() != Idx (Idx = " << Idx << ")\n");
      VaArgOffset = -(Bytes * (ArgRegs.size() - Idx));
    }

    // 関数呼び出し時にスタックに戻り先アドレス(4byte)をpushするため、+4している
    VaArgOffset += 4;

    // Record the frame index of the first variable argument
    // which is a value necessary to VASTART.
    int FI = MFI.CreateFixedObject(Bytes, VaArgOffset, true);
    RXFI->setVarArgsFrameIndex(FI);

    // Copy the integer registers that may have been used for passing varargs
    // to the vararg save area.
    for (unsigned I = Idx; I < ArgRegs.size();
         ++I, VaArgOffset += Bytes) {
      const Register Reg = RegInfo.createVirtualRegister(RC);
      RegInfo.addLiveIn(ArgRegs[I], Reg);
      SDValue ArgValue = DAG.getCopyFromReg(Chain, DL, Reg, MVT::i32);
      FI = MFI.CreateFixedObject(Bytes, VaArgOffset, true);
      SDValue PtrOff = DAG.getFrameIndex(FI, getPointerTy(DAG.getDataLayout()));
      SDValue Store = DAG.getStore(Chain, DL, ArgValue, PtrOff,
                                   MachinePointerInfo::getFixedStack(MF, FI));
      cast<StoreSDNode>(Store.getNode())
          ->getMemOperand()
          ->setValue((Value *)nullptr);
      OutChains.push_back(Store);
    }
  }

  // All stores are grouped in one node to allow the matching between
  // the size of Ins and InVals. This only happens for vararg functions.
  if (!OutChains.empty()) {
    OutChains.push_back(Chain);
    Chain = DAG.getNode(ISD::TokenFactor, DL, MVT::Other, OutChains);
  }

  return Chain;
}

// NOTE llvm/include/llvm/CodeGen/TargetLowering.h LowerCall
// Lower a call to a callseq_start + CALL + callseq_end chain, and add input
// and output parameter nodes.
SDValue RXTargetLowering::LowerCall(CallLoweringInfo &CLI,
                                    SmallVectorImpl<SDValue> &InVals) const {
  LLVM_DEBUG(dbgs() << "### LowerCall\n");

  // NOTE AVR参考
  SelectionDAG &DAG = CLI.DAG;
  SDLoc &DL = CLI.DL;
  SmallVectorImpl<ISD::OutputArg> &Outs = CLI.Outs;
  SmallVectorImpl<SDValue> &OutVals = CLI.OutVals;
  SmallVectorImpl<ISD::InputArg> &Ins = CLI.Ins;
  SDValue Chain = CLI.Chain;
  SDValue Callee = CLI.Callee;
  bool &isTailCall = CLI.IsTailCall;
  CallingConv::ID CallConv = CLI.CallConv;
  bool isVarArg = CLI.IsVarArg;

  MachineFunction &MF = DAG.getMachineFunction();

  // RX does not yet support tail call optimization.
  isTailCall = false;

  // Analyze operands of the call, assigning locations to each operand.
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(), ArgLocs,
                 *DAG.getContext());

  // If the callee is a GlobalAddress/ExternalSymbol node (quite common, every
  // direct call is) turn it into a TargetGlobalAddress/TargetExternalSymbol
  // node so that legalize doesn't hack it.
  if (const GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee)) {
    const GlobalValue *GV = G->getGlobal();

    Callee =
        DAG.getTargetGlobalAddress(GV, DL, getPointerTy(DAG.getDataLayout()));
  } else if (const ExternalSymbolSDNode *ES =
                 dyn_cast<ExternalSymbolSDNode>(Callee)) {
    Callee = DAG.getTargetExternalSymbol(ES->getSymbol(),
                                         getPointerTy(DAG.getDataLayout()));
  }

  // NOTE 関数呼び出し時の引数の処理
  CCInfo.AnalyzeCallOperands(Outs, CC_RX);

  // Get a count of how many bytes are to be pushed on the stack.
  unsigned NumBytes = CCInfo.getNextStackOffset();

  Chain = DAG.getCALLSEQ_START(Chain, NumBytes, 0, DL);

  SmallVector<std::pair<unsigned, SDValue>, 8> RegsToPass;

  // First, walk the register assignments, inserting copies.
  unsigned AI, AE;
  bool HasStackArgs = false;
  for (AI = 0, AE = ArgLocs.size(); AI != AE; ++AI) {
    CCValAssign &VA = ArgLocs[AI];
    EVT RegVT = VA.getLocVT();
    SDValue Arg = OutVals[AI];

    // Promote the value if needed. With Clang this should not happen.
    switch (VA.getLocInfo()) {
    default:
      llvm_unreachable("Unknown loc info!");
    case CCValAssign::Full:
      break;
    case CCValAssign::SExt:
      Arg = DAG.getNode(ISD::SIGN_EXTEND, DL, RegVT, Arg);
      break;
    case CCValAssign::ZExt:
      Arg = DAG.getNode(ISD::ZERO_EXTEND, DL, RegVT, Arg);
      break;
    case CCValAssign::AExt:
      Arg = DAG.getNode(ISD::ANY_EXTEND, DL, RegVT, Arg);
      break;
    case CCValAssign::BCvt:
      Arg = DAG.getNode(ISD::BITCAST, DL, RegVT, Arg);
      break;
    }

    // Stop when we encounter a stack argument, we need to process them
    // in reverse order in the loop below.
    if (VA.isMemLoc()) {
      HasStackArgs = true;
      break;
    }

    // Arguments that can be passed on registers must be kept in the RegsToPass
    // vector.
    RegsToPass.push_back(std::make_pair(VA.getLocReg(), Arg));
  }

  // Second, stack arguments have to walked in reverse order by inserting
  // chained stores, this ensures their order is not changed by the scheduler
  // and that the push instruction sequence generated is correct, otherwise they
  // can be freely intermixed.
  if (HasStackArgs) {
    LLVM_DEBUG(dbgs() << "### LowerCall HasStack\n");
    for (AE = AI, AI = ArgLocs.size(); AI != AE; --AI) {
      unsigned Loc = AI - 1;
      CCValAssign &VA = ArgLocs[Loc];
      SDValue Arg = OutVals[Loc];

      assert(VA.isMemLoc());

      // スタックに引数を格納する
      SDValue PtrOff = DAG.getNode(
          ISD::ADD, DL, getPointerTy(DAG.getDataLayout()),
          DAG.getRegister(RX::R0, getPointerTy(DAG.getDataLayout())),
          DAG.getIntPtrConstant(VA.getLocMemOffset(), DL));

      Chain = DAG.getStore(Chain, DL, Arg, PtrOff,
                       MachinePointerInfo::getStack(MF, VA.getLocMemOffset()),
                       0);
    }
  }

  // Build a sequence of copy-to-reg nodes chained together with token chain and
  // flag operands which copy the outgoing args into registers.  The InFlag in
  // necessary since all emited instructions must be stuck together.
  SDValue InFlag;
  for (auto Reg : RegsToPass) {
    Chain = DAG.getCopyToReg(Chain, DL, Reg.first, Reg.second, InFlag);
    InFlag = Chain.getValue(1);
  }

  // Returns a chain & a flag for retval copy to use.
  SDVTList NodeTys = DAG.getVTList(MVT::Other, MVT::Glue);
  SmallVector<SDValue, 8> Ops;
  Ops.push_back(Chain);
  Ops.push_back(Callee);

  // Add argument registers to the end of the list so that they are known live
  // into the call.
  for (auto Reg : RegsToPass) {
    Ops.push_back(DAG.getRegister(Reg.first, Reg.second.getValueType()));
  }

  // Add a register mask operand representing the call-preserved registers.
  const TargetRegisterInfo *TRI = Subtarget.getRegisterInfo();
  const uint32_t *Mask =
      TRI->getCallPreservedMask(DAG.getMachineFunction(), CallConv);
  assert(Mask && "Missing call preserved mask for calling convention");
  Ops.push_back(DAG.getRegisterMask(Mask));

  if (InFlag.getNode()) {
    Ops.push_back(InFlag);
  }

  // 関数呼び出し命令生成
  Chain = DAG.getNode(RXISD::BSR, DL, NodeTys, Ops);
  InFlag = Chain.getValue(1);

  // Create the CALLSEQ_END node.
  Chain = DAG.getCALLSEQ_END(Chain, DAG.getIntPtrConstant(NumBytes, DL, true),
                             DAG.getIntPtrConstant(0, DL, true), InFlag, DL);

  if (!Ins.empty()) {
    InFlag = Chain.getValue(1);
  }

  // Handle result values, copying them out of physregs into vregs that we
  // return.
  return LowerCallResult(Chain, InFlag, CallConv, isVarArg, Ins, DL, DAG,
                         InVals);
}

/// Lower the result values of a call into the
/// appropriate copies out of appropriate physical registers.
///
SDValue RXTargetLowering::LowerCallResult(
    SDValue Chain, SDValue InFlag, CallingConv::ID CallConv, bool isVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &dl, SelectionDAG &DAG,
    SmallVectorImpl<SDValue> &InVals) const {

  // Assign locations to each value returned by this call.
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, isVarArg, DAG.getMachineFunction(), RVLocs,
                 *DAG.getContext());

  // Handle runtime calling convs.
  CCInfo.AnalyzeCallResult(Ins, RetCC_RX);

  // Copy all of the result registers out of their specified physreg.
  for (CCValAssign const &RVLoc : RVLocs) {
    Chain = DAG.getCopyFromReg(Chain, dl, RVLoc.getLocReg(), RVLoc.getValVT(),
                               InFlag)
                .getValue(1);
    InFlag = Chain.getValue(2);
    InVals.push_back(Chain.getValue(0));
  }

  return Chain;
}

SDValue
RXTargetLowering::LowerReturn(SDValue Chain, CallingConv::ID CallConv,
                              bool IsVarArg,
                              const SmallVectorImpl<ISD::OutputArg> &Outs,
                              const SmallVectorImpl<SDValue> &OutVals,
                              const SDLoc &DL, SelectionDAG &DAG) const {
  LLVM_DEBUG(dbgs() << "### LowerReturn\n");
  LLVM_DEBUG(Chain->dumpr());

  // NOTE RISCV参考

  // Stores the assignment of the return value to a location.
  SmallVector<CCValAssign, 16> RVLocs;

  // Info about the registers and stack slot.
  CCState CCInfo(CallConv, IsVarArg, DAG.getMachineFunction(), RVLocs,
                 *DAG.getContext());

  CCInfo.AnalyzeReturn(Outs, RetCC_RX);

  SDValue Glue;
  SmallVector<SDValue, 4> RetOps(1, Chain);

  // Copy the result values into the output registers.
  for (unsigned i = 0, e = RVLocs.size(); i < e; ++i) {
    SDValue Val = OutVals[i];
    CCValAssign &VA = RVLocs[i];
    assert(VA.isRegLoc() && "Can only return in registers!");

    // Handle a 'normal' return.
    Chain = DAG.getCopyToReg(Chain, DL, VA.getLocReg(), Val, Glue);

    // Guarantee that all emitted copies are stuck together.
    Glue = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(VA.getLocReg(), VA.getLocVT()));
  }

  RetOps[0] = Chain; // Update chain.

  // Add the glue node if we have it.
  if (Glue.getNode()) {
    RetOps.push_back(Glue);
  }

  return DAG.getNode(RXISD::RTS, DL, MVT::Other, RetOps);
}

// NOTE llvm/lib/CodeGen/SelectionDAG/TargetLowering.cpp getTargetNodeName
// ノード名を返す
const char *RXTargetLowering::getTargetNodeName(unsigned Opcode) const {
  switch ((RXISD::NodeType)Opcode) {
  case RXISD::FIRST_NUMBER:
    break;

  case RXISD::SELECT_CC:
    return "RXISD::SELECT_CC";

  case RXISD::BSR:
    return "RXISD::BSR";
  case RXISD::RTS:
    return "RXISD::RTS";
  }

  return nullptr;
}
