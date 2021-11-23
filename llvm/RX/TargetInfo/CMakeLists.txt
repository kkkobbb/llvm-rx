add_llvm_component_library(LLVMRXInfo
  RXTargetInfo.cpp

  LINK_COMPONENTS
  Support

  ADD_TO_COMPONENT
  RX
  )
