cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(sdram_testbench)

set(APP_HW_TARGET           SLICEKIT-XC200-X1.xn)
#set(APP_HW_TARGET           xcore_ai_sdram_test_board.xn)

set(APP_DEPENDENT_MODULES   "lib_sdram")
set(APP_INCLUDES src)
set(APP_COMPILER_FLAGS      -g -O2)

set(APP_PCA_ENABLE          ON)

set(XMOS_SANDBOX_DIR        ${CMAKE_CURRENT_LIST_DIR}/../../..)

XMOS_REGISTER_APP()
