cmake_minimum_required(VERSION 3.16)
project(PortHostTests LANGUAGES C)
enable_testing()
get_filename_component(REPO_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
add_executable(test_lift_assets test_lift_assets.c "${REPO_ROOT}/src/host/lift_assets.c")
target_include_directories(test_lift_assets PRIVATE
  "${REPO_ROOT}/include" "${REPO_ROOT}/lib/model2/include"
  "${REPO_ROOT}/lib/model2/host")
add_test(NAME explicit_asset_loading COMMAND test_lift_assets)
add_executable(test_game_loop test_game_loop.c
  "${REPO_ROOT}/src/game/game_dispatch_main.c"
  "${REPO_ROOT}/lib/model2/host/i960_regs.c")
target_include_directories(test_game_loop PRIVATE
  "${REPO_ROOT}/include" "${REPO_ROOT}/lib/model2/include"
  "${REPO_ROOT}/lib/model2/host")
add_test(NAME game_loop_boundary COMMAND test_game_loop)
add_library(ios_host_compile OBJECT
  "${REPO_ROOT}/platform/ios/viewer_ios.c"
  "${REPO_ROOT}/platform/ios/port_input.c")
target_include_directories(ios_host_compile PRIVATE
  "${REPO_ROOT}/platform/ios" "${REPO_ROOT}/include"
  "${REPO_ROOT}/lib/model2/include" "${REPO_ROOT}/lib/model2/host"
  "${REPO_ROOT}/lib/model2/geo/include" "${REPO_ROOT}/lib/model2/snd/include"
  "${REPO_ROOT}/lib/model2/hw/include")
add_executable(test_port_input test_port_input.c "${REPO_ROOT}/platform/ios/port_input.c")
target_include_directories(test_port_input PRIVATE
  "${REPO_ROOT}/platform/ios" "${REPO_ROOT}/include"
  "${REPO_ROOT}/lib/model2/include" "${REPO_ROOT}/lib/model2/host"
  "${REPO_ROOT}/lib/model2/geo/include")
target_link_libraries(test_port_input PRIVATE m)
add_test(NAME native_input_mapping COMMAND test_port_input)
add_executable(test_native_nvram test_native_nvram.c "${REPO_ROOT}/src/host/model2_nvram.c")
target_compile_definitions(test_native_nvram PRIVATE SEGAMOD2_IOS _POSIX_C_SOURCE=200809L)
target_include_directories(test_native_nvram PRIVATE
  "${REPO_ROOT}/include" "${REPO_ROOT}/lib/model2/include" "${REPO_ROOT}/lib/model2/host")
add_test(NAME native_atomic_nvram COMMAND test_native_nvram)
find_package(ZLIB REQUIRED)
find_package(Python3 COMPONENTS Interpreter REQUIRED)
add_executable(rom_import_driver rom_import_driver.c
  "${REPO_ROOT}/platform/ios/port_zip.c"
  "${REPO_ROOT}/platform/ios/port_rom_import.c"
  "${REPO_ROOT}/lib/model2/host/model2_rom_check.c")
target_include_directories(rom_import_driver PRIVATE
  "${REPO_ROOT}/platform/ios" "${REPO_ROOT}/include" "${REPO_ROOT}/lib/model2/include" "${REPO_ROOT}/lib/model2/host")
target_link_libraries(rom_import_driver PRIVATE ZLIB::ZLIB)
add_test(NAME zip_rom_preparation COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_LIST_DIR}/test_rom_zip.py" $<TARGET_FILE:rom_import_driver>)
add_executable(startup_probe startup_probe.c
  "${REPO_ROOT}/lib/model2/host/model2_rom_check.c"
  "${REPO_ROOT}/lib/model2/snd/model2_snd_rom.c")
target_include_directories(startup_probe PRIVATE
  "${REPO_ROOT}/lib/model2/include" "${REPO_ROOT}/lib/model2/host"
  "${REPO_ROOT}/lib/model2/snd/include")
add_test(NAME native_startup_paths COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_LIST_DIR}/test_startup_paths.py" $<TARGET_FILE:startup_probe>)
