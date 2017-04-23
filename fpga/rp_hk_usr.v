/**
 * $Id: red_pitaya_hk.v 961 2014-01-21 11:40:39Z matej.oblak $
 *
 * @brief Red Pitaya house keeping.
 *
 * @Author Matej Oblak
 *
 * (c) Red Pitaya  http://www.redpitaya.com
 *
 * This part of code is written in Verilog hardware description language (HDL).
 * Please visit http://en.wikipedia.org/wiki/Verilog
 * for more details on the language used herein.
 */

/**
 * GENERAL DESCRIPTION:
 *
 * House keeping module takes care of system identification.
 *
 *
 * This module takes care of system identification via DNA readout at startup and
 * ID register which user can define at compile time.
 *
 * Beside that it is currently also used to test expansion connector and for
 * driving LEDs.
 * 
 */

/* HH apr 19 2017:
   changed this module to support SPI simulation / SPI trigger
 */

//module red_pitaya_hk #(
module rp_hk_usr #(
  parameter DWL = 8, // data width for LED
  parameter DWE = 8, // data width for extension
  parameter [57-1:0] DNA = 57'h0823456789ABCDE
)(
  // system signals
  input                clk_i      ,  // clock
  input                rstn_i     ,  // reset - active low
  // LED
  output reg [DWL-1:0] led_o      ,  // LED output
  // global configuration
  output reg           digital_loop,
  // Expansion connector
  input      [DWE-1:0] exp_p_dat_i,  // exp. con. input data
  output reg [DWE-1:0] exp_p_dat_o,  // exp. con. output data
  output reg [DWE-1:0] exp_p_dir_o,  // exp. con. 1-output enable
  input      [DWE-1:0] exp_n_dat_i,  //
  output reg [DWE-1:0] exp_n_dat_o,  //
  output reg [DWE-1:0] exp_n_dir_o,  //
  // System bus
  input      [ 32-1:0] sys_addr   ,  // bus address
  input      [ 32-1:0] sys_wdata  ,  // bus write data
  input                sys_wen    ,  // bus write enable
  input                sys_ren    ,  // bus read enable
  output reg [ 32-1:0] sys_rdata  ,  // bus read data
  output reg           sys_err    ,  // bus error indicator
  output reg           sys_ack       // bus acknowledge signal
);

//---------------------------------------------------------------------------------
//
//  Read device DNA

wire           dna_dout ;
reg            dna_clk  ;
reg            dna_read ;
reg            dna_shift;
reg  [ 9-1: 0] dna_cnt  ;
reg  [57-1: 0] dna_value;
reg            dna_done ;

always @(posedge clk_i)
if (rstn_i == 1'b0) begin
  dna_clk   <=  1'b0;
  dna_read  <=  1'b0;
  dna_shift <=  1'b0;
  dna_cnt   <=  9'd0;
  dna_value <= 57'd0;
  dna_done  <=  1'b0;
end else begin
  if (!dna_done)
    dna_cnt <= dna_cnt + 1'd1;

  dna_clk <= dna_cnt[2] ;
  dna_read  <= (dna_cnt < 9'd10);
  dna_shift <= (dna_cnt > 9'd18);

  if ((dna_cnt[2:0]==3'h0) && !dna_done)
    dna_value <= {dna_value[57-2:0], dna_dout};

  if (dna_cnt > 9'd465)
    dna_done <= 1'b1;
end

// parameter specifies a sample 57-bit DNA value for simulation
DNA_PORT #(.SIM_DNA_VALUE (DNA)) i_DNA (
  .DOUT  ( dna_dout   ), // 1-bit output: DNA output data.
  .CLK   ( dna_clk    ), // 1-bit input: Clock input.
  .DIN   ( 1'b0       ), // 1-bit input: User data input pin.
  .READ  ( dna_read   ), // 1-bit input: Active high load DNA, active low read input.
  .SHIFT ( dna_shift  )  // 1-bit input: Active high shift enable input.
);

//---------------------------------------------------------------------------------
//
//  Desing identification

wire [32-1: 0] id_value;

assign id_value[31: 4] = 28'h0; // reserved
assign id_value[ 3: 0] =  4'h1; // board type   1 - release 1

//---------------------------------------------------------------------------------
//
//  System bus connection

// HH apr 19, 2017
// define SPI signals as connection between the SPI simulator and the SPI trigger and the GPIO ports.

wire spi_cs_o;
wire spi_sclk_o;
wire spi_mosi_o;
wire spi_miso_o;
wire spi_trg_o;
wire spi_mosi_trg_o;

rp_spi_sim spiSim (
  .clk (clk_i),
  .rstn (rstn_i),
  .sys_addr (sys_addr),  // bus address
  .sys_wdata (sys_wdata),  // bus write data
  .sys_wen (sys_wen),
  .cs (spi_cs_o),
  .sclk (spi_sclk_o),
  .mosi (spi_mosi_o),
  .miso (spi_miso_o)
);

spi_trig spiTrg (
  .clk (clk_i),
  .rstn (rstn_i),
  .sys_addr (sys_addr),  // bus address
  .sys_wdata (sys_wdata),  // bus write data
  .sys_wen (sys_wen),
  .cs (exp_n_dat_o[0]),
  .sclk (exp_n_dat_o[1]),
  .mosi (exp_n_dat_o[2]),
  .miso (exp_n_dat_o[3]),
  .mosiTrig (spi_mosi_trg_o),
  .trg (spi_trg_o)
);

always @(posedge clk_i)
if (rstn_i == 1'b0) begin
  led_o        <= {DWL{1'b0}};
  exp_p_dat_o  <= {DWE{1'b0}};
  exp_p_dir_o  <= {DWE{1'b0}};
  exp_n_dat_o  <= {DWE{1'b0}};
  exp_n_dir_o  <= {DWE{1'h3F}};
  
end else if (sys_wen) begin
  if (sys_addr[19:0]==20'h0c)   digital_loop <= sys_wdata[0];

  //if (sys_addr[19:0]==20'h10)   exp_p_dir_o  <= sys_wdata[DWE-1:0];
  //if (sys_addr[19:0]==20'h14)   exp_n_dir_o  <= sys_wdata[DWE-1:0];
  //if (sys_addr[19:0]==20'h18)   exp_p_dat_o  <= sys_wdata[DWE-1:0];
  //if (sys_addr[19:0]==20'h1C)   exp_n_dat_o  <= sys_wdata[DWE-1:0];

  //if (sys_addr[19:0]==20'h30)   led_o        <= sys_wdata[DWL-1:0];
  //uint32_t sim_flag;     // 0x34 - flag 'use the SPI simulation output'
  //uint32_t sim_bits;     // 0x38 - number of bits on the simulated SPI
  //uint32_t sim_mosi0;    // 0x3C - first MOSI message to be transmitted
  //uint32_t sim_mosi1;    // 0x40
  //uint32_t sim_mosi2;    // 0x44
  //uint32_t sim_mosi3;    // 0x48
  //uint32_t sim_mosi4;    // 0x4C
  //uint32_t sim_mosi5;    // 0x50
  //uint32_t sim_mosi6;    // 0x54
  //uint32_t sim_mosi7;    // 0x58
  //uint32_t sim_period;   // 0x5C - number of clock cycles for 1 SCLK at the simulated SPI
  //uint32_t tr_mosi_mask; // 0x60 - mask for the MOSI trigger - mask specific bits as 'do not care'
  //uint32_t tr_mosi;      // 0x64 - MOSI pattern for trigger
  //uint32_t tr_miso_flag; // 0x68 - flag 'trigger on MISO only after the MOSI trigger pattern was OK'
  //uint32_t tr_miso_mask; // 0x6C - mask for the MISO trigger - mask special bits as 'do not care'
  //uint32_t tr_miso;      // 0x70 - MISO pattern for trigger
end else begin
  led_o[0] <= spi_cs_o; // connect the SPI signals to the LEDs
  led_o[1] <= spi_sclk_o;
  led_o[2] <= spi_mosi_o;
  led_o[3] <= spi_miso_o;
  led_o[4] <= spi_trg_o;
  led_o[5] <= spi_mosi_trg_o;
  exp_n_dat_o[0] <= spi_cs_o; // connect the SPI signals to the expansion connector N
  exp_n_dat_o[1] <= spi_sclk_o;
  exp_n_dat_o[2] <= spi_mosi_o;
  exp_n_dat_o[3] <= spi_miso_o;
  exp_n_dat_o[4] <= spi_trg_o;
  exp_n_dat_o[5] <= spi_mosi_trg_o;
end

wire sys_en;
assign sys_en = sys_wen | sys_ren;

always @(posedge clk_i) // HH apr 19 2017: this module does not support to read back any data from SPI trigger
if (rstn_i == 1'b0) begin
  sys_err <= 1'b0;
  sys_ack <= 1'b0;
end else begin
  sys_err <= 1'b0;

  casez (sys_addr[19:0])
    20'h00000: begin sys_ack <= sys_en;  sys_rdata <= {                id_value          }; end
    20'h00004: begin sys_ack <= sys_en;  sys_rdata <= {                dna_value[32-1: 0]}; end
    20'h00008: begin sys_ack <= sys_en;  sys_rdata <= {{64- 57{1'b0}}, dna_value[57-1:32]}; end
    20'h0000c: begin sys_ack <= sys_en;  sys_rdata <= {{32-  1{1'b0}}, digital_loop      }; end

    20'h00010: begin sys_ack <= sys_en;  sys_rdata <= {{32-DWE{1'b0}}, exp_p_dir_o}       ; end
    20'h00014: begin sys_ack <= sys_en;  sys_rdata <= {{32-DWE{1'b0}}, exp_n_dir_o}       ; end
    20'h00018: begin sys_ack <= sys_en;  sys_rdata <= {{32-DWE{1'b0}}, exp_p_dat_o}       ; end
    20'h0001C: begin sys_ack <= sys_en;  sys_rdata <= {{32-DWE{1'b0}}, exp_n_dat_o}       ; end
    20'h00020: begin sys_ack <= sys_en;  sys_rdata <= {{32-DWE{1'b0}}, exp_p_dat_i}       ; end
    20'h00024: begin sys_ack <= sys_en;  sys_rdata <= {{32-DWE{1'b0}}, exp_n_dat_i}       ; end

    20'h00030: begin sys_ack <= sys_en;  sys_rdata <= {{32-DWL{1'b0}}, led_o}             ; end

      default: begin sys_ack <= sys_en;  sys_rdata <=  32'h0                              ; end
  endcase
end

endmodule
