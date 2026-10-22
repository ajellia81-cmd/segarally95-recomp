# Configure the repository root, not this directory.
if(NOT TARGET segamod2_core)
  message(FATAL_ERROR "Configure the repository root with CMAKE_SYSTEM_NAME=iOS")
endif()
set(SEGAMOD2_BUNDLE_ID "local.personal.segarally95" CACHE STRING "Personal app bundle identifier")
add_executable(SegaRallyIOS MACOSX_BUNDLE main.m PortRenderer.m PortAudio.m PortROMPreparation.m port_zip.c port_rom_import.c Assets.xcassets)
target_compile_options(SegaRallyIOS PRIVATE "$<$<COMPILE_LANGUAGE:OBJC>:-fobjc-arc>")
target_link_libraries(SegaRallyIOS PRIVATE segamod2_core z
  "-framework UIKit" "-framework CoreGraphics" "-framework Metal" "-framework MetalKit"
  "-framework AVFoundation" "-framework GameController")
set_target_properties(SegaRallyIOS PROPERTIES
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
  MACOSX_BUNDLE_GUI_IDENTIFIER "${SEGAMOD2_BUNDLE_ID}"
  XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${SEGAMOD2_BUNDLE_ID}"
  XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1"
  XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "15.0"
  XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
  XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon")
# No assets, signing identity, provisioning profile, archive or export targets.
find_program(XCRUN xcrun REQUIRED)
set(PORT_METALLIB "${CMAKE_CURRENT_BINARY_DIR}/PortShaders.metallib")
add_custom_command(OUTPUT "${PORT_METALLIB}"
  COMMAND "${XCRUN}" --sdk "${CMAKE_OSX_SYSROOT}" metal -c
    "${CMAKE_CURRENT_SOURCE_DIR}/Shaders.metal" -o "${CMAKE_CURRENT_BINARY_DIR}/PortShaders.air"
  COMMAND "${XCRUN}" --sdk "${CMAKE_OSX_SYSROOT}" metallib
    "${CMAKE_CURRENT_BINARY_DIR}/PortShaders.air" -o "${PORT_METALLIB}"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/Shaders.metal" VERBATIM)
set_source_files_properties("${PORT_METALLIB}" PROPERTIES GENERATED TRUE MACOSX_PACKAGE_LOCATION Resources)
target_sources(SegaRallyIOS PRIVATE "${PORT_METALLIB}")

set_source_files_properties(Assets.xcassets PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
