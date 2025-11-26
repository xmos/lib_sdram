cmake_minimum_required(VERSION 3.21)
include($ENV{XMOS_CMAKE_PATH}/xcommon.cmake)
project(lib_sdram_tests)

add_subdirectory(sdram_benchmark)
add_subdirectory(sdram_multi_client_test)
add_subdirectory(sdram_testbench)