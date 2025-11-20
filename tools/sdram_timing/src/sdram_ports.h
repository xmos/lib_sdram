#include <platform.h>

#if defined(__XS3A__)
// SDRAM test board for XU316
#define SERVER_TILE 1
#define PORT_SDRAM_DQ_AH XS1_PORT_16A
#define PORT_SDRAM_CAS   XS1_PORT_1A
#define PORT_SDRAM_RAS   XS1_PORT_1P
#define PORT_SDRAM_WE    XS1_PORT_1M
#define PORT_SDRAM_CLK   XS1_PORT_1F
#define CLOCK_SDRAM      XS1_CLKBLK_1
#elif defined(__XS2A__)
// Triangle slot tile 0 for XU216 of XP-SKC-X200 slice kit board
#define SERVER_TILE 0
#define PORT_SDRAM_DQ_AH XS1_PORT_16B
#define PORT_SDRAM_CAS   XS1_PORT_1J
#define PORT_SDRAM_RAS   XS1_PORT_1I
#define PORT_SDRAM_WE    XS1_PORT_1K
#define PORT_SDRAM_CLK   XS1_PORT_1L
#define CLOCK_SDRAM      XS1_CLKBLK_2
#else
// Square slot on A16 slicekit
#define SERVER_TILE 1
#define PORT_SDRAM_DQ_AH XS1_PORT_16A
#define PORT_SDRAM_CAS   XS1_PORT_1B
#define PORT_SDRAM_RAS   XS1_PORT_1G
#define PORT_SDRAM_WE    XS1_PORT_1C
#define PORT_SDRAM_CLK   XS1_PORT_1F
#define CLOCK_SDRAM      XS1_CLKBLK_2
#endif
