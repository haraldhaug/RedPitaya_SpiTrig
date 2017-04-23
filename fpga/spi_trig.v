/* SPI trigger
   This module reads in SPI data and checks for specific data patterns on MOSI and optionally on MISO

   This module can be used in combination with SPI simulator for debugging or training purpose.
   This module uses the RedPitaya data busses for calibration.
   This module was written for the RedPitaya.
*/

module spi_trig(
  // system signals
  input                clk      ,  // clock
  input                rstn     ,  // reset - active low
  // System bus
  input      [ 31:0] sys_addr   ,  // bus address
  input      [ 31:0] sys_wdata  ,  // bus write data
  input                sys_wen    ,  // bus write enable
  // simulated SPI bus
  input cs,  // SPI chip select - master output
  input sclk, // SPI clk - master output
  input mosi, // SPI mosi - simulated master output
  input miso,  // SPI miso - simulated slave output
  output reg mosiTrig, // data output indicating trigger event on MOSI
  output reg trg // data output indication trigger event
);

reg [31:0] mosiShift; // shift register fo MOSI data
reg [31:0] misoShift; // shift register for MISO data
reg [31:0] mosiPattern; // trigger pattern for MOSI data
reg [31:0] mosiMask;    // indicates valid bits of the MOSI data
reg [31:0] mosiData; // take the result of the shift register at the rising slope of CS
reg [31:0] misoPattern; // trigger pattern for MISO data
reg [31:0] misoMask;    // indicates valid bits of the MISO data
reg [31:0] misoData; // take the result of the shift register at the rising slope of CS
reg csLevel; // store the las valid CS level detected by the csShift
reg [1:0] csShift; // shift register to lowpass filter the cs
reg misoFlag; // =0 if MISO data shall be ignored
reg sclkLevel; // indicates a rising slope on the clock
reg [2:0] sclkShift; // shift register to implement a slope detection on the sclk
reg [1:0] msgEndFlag; // indicates a rising slope on the CS
reg [31:0] cntMask; // count the number of bits in a message // mask out unused bits

// get the calibration data
always @(posedge clk)
if (rstn== 1'b0) begin
  mosiPattern <= 32'h33AA; // trigger on example MOSI data - see also SPI simulator default messages
  mosiMask <= 32'hFFFFFFFF; // no bits to be ignored
  misoPattern <= 32'h3303; // trigger on example MISO data - see also SPI simulator default messages
  misoMask <= 32'hFFFFFF07; // consider only the most significant byte and the least significant 3 bits.
  misoFlag = 1'b1; // by default trigger on MISO
end else if (sys_wen ) begin
  //uint32_t tr_mosi_mask; // 0x60 - mask for the MOSI trigger - mask specific bits as 'do not care'
  if (sys_addr[19:0]==20'h60) mosiMask <= sys_wdata[31:0];
  //uint32_t tr_mosi;      // 0x64 - MOSI pattern for trigger
  if (sys_addr[19:0]==20'h64) mosiPattern <= sys_wdata[31:0];
  //uint32_t tr_miso_flag; // 0x68 - flag 'trigger on MISO only after the MOSI trigger pattern was OK'
  if (sys_addr[19:0]==20'h68) misoFlag <= sys_wdata[31:0] != 32'b0;
  //uint32_t tr_miso_mask; // 0x6C - mask for the MISO trigger - mask special bits as 'do not care'
  if (sys_addr[19:0]==20'h6C) misoMask <= sys_wdata[31:0];
  //uint32_t tr_miso;      // 0x70 - MISO pattern for trigger
  if (sys_addr[19:0]==20'h70) misoPattern <= sys_wdata[31:0];
end

// load the shift registers
always @(posedge sclk)
if (cs == 1'b0) begin
  // there is no reset, if the SPI telegram uses less than 32bit then
  // the MSBs might have sporadic data.
  mosiShift <= { mosiShift[30:0], mosi }; // shift the new data to the register at the LSB
  misoShift <= { misoShift[30:0], miso }; // shift the new data to the register at the LSB
end

// read the cs
// determine the rising slope of CS 
// the trigger pulse shall be created at the rising slope.
always @(posedge clk)
if (rstn== 1'b0) begin
  csLevel <= 1'b1; // CS idle value is high
  csShift <= 2'b11; // assign empty shift register "all high"
  msgEndFlag <= 2'b0; // no end of SPI message
end
else begin
  csShift <= { csShift[0], cs}; // load the CS shift register, move in new data at the LSB
  if ( csLevel == 1'b1 & (csShift == 2'b00 | (csShift == 2'b01 & cs == 1'b0) | (csShift == 2'b10 & cs == 1'b0 )) ) begin
    // set level to 0 if 2 out of 3 items in the shift register are 0
    csLevel <= 1'b0; 
  end
  else if ( csLevel == 1'b0 & (csShift == 2'b11 | (csShift == 2'b10 & cs == 1'b1) | (csShift == 2'b01 & cs == 1'b1)) ) begin
    // set level to 1 if 2 out of 3 items in the shift register are 1
    csLevel <= 1'b1;
    msgEndFlag[0] <= 1'b1; // set the message end flag when the CS rising slope was detected.
  end
  else msgEndFlag[0] <= 1'b0; // reset the message end flag
  msgEndFlag[1] <= msgEndFlag[0]; // remember the previous state of the message end flag
end

// read the sclk
// determine the rising slope of the clock
// this assumes that this module is operated at minimum 50MHz
// where the SPI clock is smaller than 10MHz
always @(posedge clk)
if (rstn== 1'b0) begin
  sclkLevel <= 1'b0; // initialize the clk to low
  sclkShift <= 3'b0; // assign empty shift register
end
else begin
  sclkShift <= { sclkShift[1:0], sclk}; // load the shift register
  if ( sclkLevel == 1'b0 & sclkShift == 3'b001 & sclk == 1'b1 ) begin
    // detect the rising slope of the sclk
    sclkLevel <= 1'b1; 
  end
  else sclkLevel <= 1'b0; // no rising slope at the sclk
end

// determine the number of bits
// count the number of rising slopes at the sclk
always @(posedge clk)
if (rstn== 1'b0) begin
  cntMask <= 32'b0; // reset the counter
end
else if (csLevel == 1'b0 & sclkLevel == 1'b1) begin
  cntMask <= {cntMask[30:0] , 1'b1}; // sclk detected
end 
else if (msgEndFlag[1] == 1'b1) begin
  cntMask <= 32'b0; // reset the counter when the message end flag is over
end

// check if the MOSI pattern matches
always @(posedge clk)
if (rstn== 1'b0) begin
  mosiTrig <= 1'b0;
end
else if (msgEndFlag[0] == 1'b1) begin
  // always check at the rising slope of the CS signal
  // in case there are less than 32 bit in the message then ignore the unused MSBs
  // ignore all bits that are masked out by the user
  // the trigger flag will latch till the next CS rising slope
  if ( (mosiShift & cntMask & mosiMask) == (mosiPattern & mosiMask) ) mosiTrig <= 1'b1;
  else mosiTrig <= 1'b0;
end

// check if the MISO pattern matches
always @(posedge clk)
if (rstn== 1'b0) begin
  trg <= 1'b0;
end
else if (msgEndFlag[0] == 1'b1) begin
  // always check at the rising slope of the CS signal
  // in case there are less than 32 bit in the message then ignore the unused MSBs
  // ignore all bits that are masked out by the user
  // the trigger flag will latch till the next CS rising slope
  if (misoFlag == 1'b1) begin
    // trigger on both MOSI and MISO data
    if (  mosiTrig == 1'b1 & (misoShift & cntMask & misoMask) == (misoPattern & misoMask) ) trg <= 1'b1;
    else trg <= 1'b0;
  end
  else begin
    // trigger on MOSI only
    // in this case the 2 flags trg and mosiTrig are redundant.
    if ( (mosiShift & cntMask & mosiMask) == (mosiPattern & mosiMask) ) trg <= 1'b1;
    else trg <= 1'b0; 
  end
end


endmodule
