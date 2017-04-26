# The TARGET variable determines what target system the application is
# compiled for. It either refers to an XN file in the source directories
# or a valid argument for the --target option when compiling
ifeq ($(CONFIG), xs2) 
	TARGET = SLICEKIT-XC200-X1
endif
ifeq ($(CONFIG), xs1) 
	TARGET = SLICEKIT-A16
endif

# The APP_NAME variable determines the name of the final .xe file. It should
# not include the .xe postfix. If left blank the name will default to
# the project name
APP_NAME = sdram_demo

# The USED_MODULES variable lists other module used by the application.
USED_MODULES = lib_sdram

# The flags passed to xcc when building the application
# You can also set the following to override flags for a particular language:
# XCC_XC_FLAGS, XCC_C_FLAGS, XCC_ASM_FLAGS, XCC_CPP_FLAGS
# If the variable XCC_MAP_FLAGS is set it overrides the flags passed to
# xcc for the final link (mapping) stage.
BUILD_FLAGS = -g -O2

#xCORE200 slicekit
XCC_FLAGS_xs2 = $(BUILD_FLAGS)
INCLUDE_ONLY_IN_xs2 = 
#XS1-A slicekit
XCC_FLAGS_xs1 = $(BUILD_FLAGS)
INCLUDE_ONLY_IN_xs1 = 

# The VERBOSE variable, if set to 1, enables verbose output from the make system.
VERBOSE = 0

sim_xs2: bin/xs2/sdram_demo_xs2.xe
	xsim bin/xs2/sdram_demo_xs2.xe --max-cycles 1000000 \
	--trace-plugin VcdPlugin.dll '-tile tile[0] -o trace.vcd -xe bin/xs2/sdram_demo_xs2.xe -ports-detailed -clock-blocks' \
	#--xscope "-offline trace.xmt" \
	#--trace-to trace.txt

#=============================================================================
# The following part of the Makefile includes the common build infrastructure
# for compiling XMOS applications. You should not need to edit below here.

XMOS_MAKE_PATH ?= ../..
include $(XMOS_MAKE_PATH)/xcommon/module_xcommon/build/Makefile.common
