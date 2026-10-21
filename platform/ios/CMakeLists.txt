cmake_minimum_required(VERSION 3.20)
project(SegaRallyIOSScaffold LANGUAGES OBJC)
if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
  message(FATAL_ERROR "This scaffold requires the iOS SDK; configure with -DCMAKE_SYSTEM_NAME=iOS")
endif()
add_executable(SegaRallyIOS MACOSX_BUNDLE main.m)
target_compile_options(SegaRallyIOS PRIVATE -fobjc-arc)
target_link_libraries(SegaRallyIOS PRIVATE
  "-framework UIKit" "-framework Metal" "-framework MetalKit")
set_target_properties(SegaRallyIOS PROPERTIES
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
  MACOSX_BUNDLE_GUI_IDENTIFIER "local.personal.segarally95.scaffold"
  XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
  XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "15.0")
# Deliberately no ROM resources, game entry point, desktop SDL/GL or signing team.
