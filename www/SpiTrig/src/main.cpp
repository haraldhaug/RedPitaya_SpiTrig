#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/sysinfo.h>
#include <vector>

#include "main.h"

//Parameters
// defined in /opt/redpitaya/rp_sdk/CustomParameters.h
CBooleanParameter simFlag("SPI_SIM_FLAG", CBaseParameter::RW, true, 0); // name, mode, value, fpga_update
CIntParameter simBits("SPI_SIM_BITS", CBaseParameter::RW,16,0,16,32); // name, mode, value, fpga_update, min, max
CIntParameter simPeriod("SPI_SIM_PERIOD", CBaseParameter::RW,600,0,1,4095); // name, mode, value, fpga_update, min, max
CStringParameter trMosiMask("SPI_TR_MOSI_MASK", CBaseParameter::RW, std::string("FFFF"), 0);
CStringParameter trMosi("SPI_TR_MOSI", CBaseParameter::RW, std::string("33AA"), 0);
CBooleanParameter trMisoFlag("SPI_TR_MISO_FLAG", CBaseParameter::RW, true, 0); // name, mode, value, fpga_update
CStringParameter trMisoMask("SPI_TR_MISO_MASK", CBaseParameter::RW, std::string("FF07"), 0);
CStringParameter trMiso("SPI_TR_MISO", CBaseParameter::RW, std::string("3303"), 0);






const char *rp_app_desc(void)
{
    return (const char *)"Red Pitaya LED control.\n";
}


int rp_app_init(void)
{
    fprintf(stderr, "Loading LED control\n");

    // Initialization of API
    if (rpApp_Init() != RP_OK) 
    {
        fprintf(stderr, "Red Pitaya API init failed!\n");
        return EXIT_FAILURE;
    }
    else fprintf(stderr, "Red Pitaya API init success!\n");
    //CDataManager::GetInstance()->SetSignalInterval(10);
    
    return 0;
}


int rp_app_exit(void)
{
    fprintf(stderr, "Unloading LED control\n");

    rpApp_Release();

    return 0;
}


int rp_set_params(rp_app_params_t *p, int len)
{
    return 0;
}


int rp_get_params(rp_app_params_t **p)
{
    return 0;
}


int rp_get_signals(float ***s, int *sig_num, int *sig_len)
{
    return 0;
}








void UpdateSignals(void)
{
    
}


void UpdateParams(void){}


void OnNewParams(void) 
{
    unsigned long vMask, vPattern;
    simFlag.Update();
    trMisoFlag.Update();
    simBits.Update();
    simPeriod.Update();
    trMosiMask.Update();
    trMosi.Update();
    trMisoMask.Update();
    trMiso.Update();

    if ( simFlag.Value() == false){
         rp_spi_SetSimFlag(0);
    }else{
         rp_spi_SetSimFlag(1);
    }
    if ( trMisoFlag.Value() == false){
         rp_spi_SetMisoFlag(0);
    } else {
         rp_spi_SetMisoFlag(1);
    }
    rp_spi_SetSimBits((uint32_t)simBits.Value());
    rp_spi_SetSimPeriod(((uint32_t) simPeriod.Value()) << 15);
    vMask = strtoul(trMosiMask.Value().c_str(),NULL,16);
    vPattern = strtoul(trMosi.Value().c_str(),NULL,16);
    rp_spi_SetMosi((uint32_t)vMask, (uint32_t)vPattern);
    vMask = strtoul(trMisoMask.Value().c_str(),NULL,16);
    vPattern = strtoul(trMiso.Value().c_str(),NULL,16);
    rp_spi_SetMiso((uint32_t)vMask, (uint32_t)vPattern);

}


void OnNewSignals(void){}

void PostUpdateSignals(void){}
