add_llvm_component_group(RX)

set(LLVM_TARGET_DEFINITIONS RX.td)

tablegen(LLVM RXGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM RXGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM RXGenCallingConv.inc -gen-callingconv)
tablegen(LLVM RXGenDAGISel.inc -gen-dag-isel)
tablegen(LLVM RXGenDisassemblerTables.inc -gen-disassembler)
tablegen(LLVM RXGenGlobalISel.inc -gen-global-isel)
tablegen(LLVM RXGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM RXGenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM RXGenMCPseudoLowering.inc -gen-pseudo-lowering)
tablegen(LLVM RXGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM RXGenSubtargetInfo.inc -gen-subtarget)

add_public_tablegen_target(RXCommonTableGen)

add_llvm_target(RXCodeGen
  RXAsmPrinter.cpp
  RXExpandPseudoInsts.cpp
  RXFrameLowering.cpp
  RXISelDAGToDAG.cpp
  RXISelLowering.cpp
  RXInstrInfo.cpp
  RXMCInstLower.cpp
  RXRegisterInfo.cpp
  RXSubtarget.cpp
  RXTargetMachine.cpp

  LINK_COMPONENTS
  Analysis
  AsmPrinter
  Core
  CodeGen
  MC
  RXDesc
  RXInfo
  SelectionDAG
  Support
  Target

  ADD_TO_COMPONENT
  RX
  )

add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
