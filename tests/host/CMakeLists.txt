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
