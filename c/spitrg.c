/* HH apr 22, 2017
  example code to demonstrate the interface functions for SPI simulation / SPI trigger
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "redpitaya/rp.h"

int main (int argc, char **argv) {
    
    printf("SPI Trigger\n");
    
    if (rp_Init() != RP_OK) {
        fprintf(stderr, "Red Pitaya API init failed!\n");
        return EXIT_FAILURE;
    }

    
    rp_spi_SetSimFlag(1);
    rp_spi_SetSimBits(16);
    rp_spi_SetSimPeriod((uint32_t) 0x01FFFFF);
    rp_spi_SetMosi((uint32_t) /*mask*/ 0x0FFFF, (uint32_t) /*pattern*/ 0x033AA);
    rp_spi_SetMisoFlag(1);
    rp_spi_SetMiso((uint32_t) /*mask*/ 0x0FF07, (uint32_t) /*pattern*/ 0x03303);
    // Releasing resources
    rp_Release();

    return EXIT_SUCCESS;
}
