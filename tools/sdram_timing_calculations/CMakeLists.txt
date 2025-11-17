cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(sdram_timing_calculations)

set(XMOS_SANDBOX_DIR ${CMAKE_CURRENT_LIST_DIR}/../../..)
set(APP_HW_TARGET XU316-1024-FB265-C24)
set(APP_COMPILER_FLAGS -O3 -Wall)
set(APP_PCA_ENABLE ON)
set(APP_DEPENDENT_MODULES)
set(APP_INCLUDES src)

XMOS_REGISTER_APP()
