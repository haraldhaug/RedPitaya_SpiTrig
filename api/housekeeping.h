/**
 * $Id: $
 *
 * @brief Red Pitaya library housekeeping module interface
 *
 * @Author Red Pitaya
 *
 * (c) Red Pitaya  http://www.redpitaya.com
 *
 * This part of code is written in C programming language.
 * Please visit http://en.wikipedia.org/wiki/C_(programming_language)
 * for more details on the language used herein.
 */

/* HH apr 22, 2017
  added data structure elements to support SPI simulation and SPI trigger
*/

#ifndef __HOUSEKEEPING_H
#define __HOUSEKEEPING_H

#include <stdint.h>
#include <stdbool.h>

// Base Housekeeping address
static const int HOUSEKEEPING_BASE_ADDR = 0x00000000;
static const int HOUSEKEEPING_BASE_SIZE = 0x70;

// Housekeeping structure declaration
typedef struct housekeeping_control_s {
    uint32_t id;           // 0x00
    uint32_t dna_lo;       // 0x04
    uint32_t dna_hi;       // 0x08
    uint32_t digital_loop; // 0x0C
    uint32_t ex_cd_p;      // 0x10
    uint32_t ex_cd_n;      // 0x14
    uint32_t ex_co_p;      // 0x18
    uint32_t ex_co_n;      // 0x1C
    uint32_t ex_ci_p;      // 0x20
    uint32_t ex_ci_n;      // 0x24
    uint32_t reserved_2;   // 0x28
    uint32_t reserved_3;   // 0x2C
    uint32_t led_control;  // 0x30
    // SPI trigger section
    uint32_t sim_flag;     // 0x34 - flag 'use the SPI simulation output'
    uint32_t sim_bits;     // 0x38 - number of bits on the simulated SPI
    uint32_t sim_mosi0;    // 0x3C - first MOSI message to be transmitted
    uint32_t sim_mosi1;    // 0x40
    uint32_t sim_mosi2;    // 0x44
    uint32_t sim_mosi3;    // 0x48
    uint32_t sim_mosi4;    // 0x4C
    uint32_t sim_mosi5;    // 0x50
    uint32_t sim_mosi6;    // 0x54
    uint32_t sim_mosi7;    // 0x58
    uint32_t sim_period;   // 0x5C - number of clock cycles for 1 SCLK at the simulated SPI
    uint32_t tr_mosi_mask; // 0x60 - mask for the MOSI trigger - mask specific bits as 'do not care'
    uint32_t tr_mosi;      // 0x64 - MOSI pattern for trigger
    uint32_t tr_miso_flag; // 0x68 - flag 'trigger on MISO only after the MOSI trigger pattern was OK'
    uint32_t tr_miso_mask; // 0x6C - mask for the MISO trigger - mask special bits as 'do not care'
    uint32_t tr_miso;      // 0x70 - MISO pattern for trigger
} housekeeping_control_t;


static const uint32_t LED_CONTROL_MASK = 0xFF;
static const uint32_t DIGITAL_LOOP_MASK = 0x1;
static const uint32_t EX_CD_P_MASK = 0xFF;
static const uint32_t EX_CD_N_MASK = 0xFF;
static const uint32_t EX_CO_P_MASK = 0xFF;
static const uint32_t EX_CO_N_MASK = 0xFF;
static const uint32_t EX_CI_P_MASK = 0xFF;
static const uint32_t EX_CI_N_MASK = 0xFF;

int hk_EnableDigitalLoop(bool enable);

static volatile housekeeping_control_t *hk = NULL;

static int hk_Init() {
    cmn_Map(HOUSEKEEPING_BASE_SIZE, HOUSEKEEPING_BASE_ADDR, (void**)&hk);
    return RP_OK;
}

static int hk_Release() {
    cmn_Unmap(HOUSEKEEPING_BASE_SIZE, (void**)&hk);
    return RP_OK;
}

#endif //__HOUSEKEEPING_H
