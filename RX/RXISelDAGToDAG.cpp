//===-- RXISelDAGToDAG.cpp - A dag to dag inst selector for RX ------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines an instruction selector for the RX target.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/RXMCTargetDesc.h"
#include "RX.h"
#include "RXTargetMachine.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

#define DEBUG_TYPE "rx-iseldagtodag"

// RX-specific code to select RX machine instructions for
// SelectionDAG operations.
namespace {
class RXDAGToDAGISel final : public SelectionDAGISel {
  const RXSubtarget *Subtarget;

public:
  explicit RXDAGToDAGISel(RXTargetMachine &TargetMachine)
      : SelectionDAGISel(TargetMachine) {}

  StringRef getPassName() const override {
    LLVM_DEBUG(dbgs() << "### getPassName\n");
    return "RX DAG->DAG Pattern Instruction Selection";
  }

  bool runOnMachineFunction(MachineFunction &MF) override {
    LLVM_DEBUG(dbgs() << "### runOnMachineFunction\n");
    Subtarget = &MF.getSubtarget<RXSubtarget>();
    return SelectionDAGISel::runOnMachineFunction(MF);
  }

  void Select(SDNode *Node) override;

  // Complex Pattern.
  bool SelectAddr(SDNode *Op, SDValue Addr, SDValue &Base, SDValue &Offset);

// Include the pieces autogenerated from the target description.
#include "RXGenDAGISel.inc"
};
}

void RXDAGToDAGISel::Select(SDNode *Node) {
  LLVM_DEBUG(dbgs() << "### Select\n");

  // If we have a custom node, we have already selected.
  if (Node->isMachineOpcode()) {
    LLVM_DEBUG(dbgs() << "== "; Node->dump(CurDAG); dbgs() << "\n");
    Node->setNodeId(-1);
    return;
  }

  // Select the default instruction.
  SelectCode(Node);
}

bool RXDAGToDAGISel::SelectAddr(SDNode *Op, SDValue Addr, SDValue &Base, SDValue &Offset) {
  LLVM_DEBUG(dbgs() << "### SelectAddr\n");
  EVT VT = Addr.getValueType();
  SDLoc dl(Op);

  Offset = CurDAG->getTargetConstant(0, dl, VT);

  if (auto FIN = dyn_cast<FrameIndexSDNode>(Addr)) {
    Base = CurDAG->getTargetFrameIndex(FIN->getIndex(), VT);
    return true;
  }

  Base = Addr;
  return true;
}

// This pass converts a legalized DAG into a RX-specific DAG, ready
// for instruction scheduling.
FunctionPass *llvm::createRXISelDag(RXTargetMachine &TM) {
  return new RXDAGToDAGISel(TM);
}
