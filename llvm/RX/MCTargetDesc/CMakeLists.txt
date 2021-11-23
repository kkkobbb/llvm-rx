add_llvm_component_library(LLVMRXDesc
  RXAsmBackend.cpp
  RXELFObjectWriter.cpp
  RXInstPrinter.cpp
  RXMCAsmInfo.cpp
  RXMCCodeEmitter.cpp
  RXMCTargetDesc.cpp
  RXTargetStreamer.cpp

  LINK_COMPONENTS
  MC
  RXInfo
  Support

  ADD_TO_COMPONENT
  RX
)
