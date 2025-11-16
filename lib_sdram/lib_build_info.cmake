set(LIB_NAME lib_sdram)
set(LIB_VERSION 3.3.0)
set(LIB_INCLUDES api src)

set(LIB_DEPENDENT_MODULES "")

set(LIB_COMPILER_FLAGS -O3
                       -Wno-unusual-code
                       -fasm-linenum
                       -fcomment-asm
                       -g)

XMOS_REGISTER_MODULE()
