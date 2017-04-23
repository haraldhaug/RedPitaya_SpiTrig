/* SPI simulator
   This module creates a pseudo SPI bus.
   This module is at the same time SPI master and SPI slave.
   This module has outputs cs, sclk and MOSI thus simulating an SPI master.
   This module has output miso thus simulaiting an SPI slave that would respond 
   on the MOSI of the master.
   This module is intended to provide test data for the SPI trigger.

   This module is intended to be used on a RedPitaya.
   This module uses the RedPitaya data busses for calibration.
   This module was written for the RedPitaya.
*/

module rp_spi_sim(
  // system signals
  input                clk      ,  // clock
  input                rstn     ,  // reset - active low
  // System bus
  input      [ 31:0] sys_addr   ,  // bus address
  input      [ 31:0] sys_wdata  ,  // bus write data
  input                sys_wen    ,  // bus write enable
  // simulated SPI bus
  output cs,  // SPI chip select - master output
  output sclk, // SPI clk - master output
  output mosi, // SPI mosi - simulated master output
  output miso  // SPI miso - simulated slave output
);

reg simFlag;  // SPI simulation flag
reg [5:0] simBits; // ((number of bits)-1) created by a simulated SPI message
reg [31:0] clkCnt; // SPI simulator clock counter
reg simClk; // SPI simulator clock
reg outClk; // output clock - continusous version of the SCLK
reg [31:0] clkPeriod; // SPI simulator clock period - multiple of the clk intput
reg [3:0] simState; // SPI simulator state machine
reg [5:0] stateCnt;    // SPI simulator state machine counter
reg stateEn; // SPI simulator state machine enable
reg shiftEn; // enable the shift register
reg [5:0] msgNum; // number of different MOSI values
reg [5:0] msgCnt; // counter register to count from 1 to spiSimNumMosi
reg [31:0] mosiShift; // shift register fo MOSI data
reg [31:0] mosiPattern [4:0]; // memory containing 5 items of 32 bit registers
reg [31:0] prevMosi; // previous MOSI pattern, required for MISO data
reg [31:0] misoShift; // shift register for MISO data
reg [7:0] misoData [4:0]; // remember the current variable byte of the MISO data
reg [7:0] misoByte; // manipulate the variable part of the MISO data

// handle the SPI simulation flag
// handle the number of bits for SPI simulation 
// handle the clock period for SPI simulation 
always @(posedge clk)
if (rstn== 1'b0) begin
  simFlag <= 1'b1; // simation active by default
  simBits <= 6'hF; // simation 16 bit messages
  clkPeriod <= 32'h014; // default clock period
end else if (sys_wen ) begin
  //uint32_t sim_flag;     // 0x34 - flag 'use the SPI simulation output'
  if (sys_addr[19:0]==20'h34) simFlag <= sys_wdata[31:0] != 20'h00;
  //uint32_t sim_bits;     // 0x38 - number of bits on the simulated SPI
  if (sys_addr[19:0]==20'h38) simBits <= sys_wdata[5:0] - 6'h01;
  //uint32_t sim_period;   // 0x5C - number of clock cycles for 1 SCLK at the simulated SPI
  if (sys_addr[19:0]==20'h5C) clkPeriod <= sys_wdata;
end


// build the SPI simulation clock
always @(posedge clk)
if (rstn == 1'b0) begin
  clkCnt <= 32'h0; // initialize the counter
  simClk <= 1'b0;
  outClk <= 1'b0;
  stateEn <= 1'b0;
  shiftEn <= 1'b0;
end else begin
  if ( clkCnt < clkPeriod) begin
    // apply a clock divider
    clkCnt <= clkCnt +32'h01; // increment the counter
    stateEn <= 1'b0; // reset the state machine enable signal
  end else begin
    // clock divider timeout
    if ( simClk == 1'b0) stateEn <= 1'b1; // set the enable for the rising simClk slope 
    else stateEn <= 1'b0; // keep low for the falling simClk slope
    clkCnt <= 32'b0; // reset the counter
    simClk <= ~simClk; // toggle the simClk
    
  end
  outClk <= simClk; // the output clock is one clk cycle delayed versis simClk
  // the shift enable shall be set when there is MOSI / MISO to shift
  // do not shift the final bit
  if (stateCnt < simBits - 6'b1 & ( simState == 4'h2 | simState == 4'h3 )) shiftEn <= stateEn;
  else shiftEn <= 1'b0;
end

// define thet SPI simulation state machine
always @(posedge clk)
if (rstn == 1'b0) begin
    simState <= 4'b0; // reset the state machine
    stateCnt <= 6'b0; // reset the state machine counter
    msgCnt <= 6'h0;
    //prevMosi <= 32'b0; // empty MOSI data
end else begin
  case (simState)
  4'h1, 4'h4, 4'h5: begin // one of the states that are only one clk long
    simState <= simState + 4'h1; // go to next state
    end
  4'h2: begin // CS low, wait for the next simClk cycle
    if (stateEn == 1'b1) simState <= 4'h3; // go to transmitting
    end
  4'h3: begin // transmitting, transmit the given number of bits according simBits
    if (stateCnt < simBits) begin
      // count the number of bits to be transmitted
      if (stateEn == 1'b1) stateCnt <= stateCnt + 7'h1;
    end
    else if (stateEn == 1'b1) begin
      // reached the number of bits to be transmitted
      stateCnt <= 6'h0; // reset the counter
      simState <= 4'h4; // go MISO byte update
    end
    end 
  4'h6: begin // CS low, wait for the next simClk cycle
    if (stateEn == 1'b1) begin
      if ( msgCnt < msgNum) begin // count number of messages in one block of messages
        // there are more messages in the current block
        simState <= 4'h0; // go to inter-word blanking
        msgCnt <= msgCnt + 6'h1; // increment the message counter 
      end else begin // reached the end of this block
        simState <= 4'h7; // go to inter block blanking
        msgCnt <= 6'h0; // reset the counter
      end
    end
    end
  4'h7: begin // CS high, inter block blanking
    if (stateCnt < simBits) begin 
      // the inter block blanking time is equivalent to the number of bits
      if (stateEn == 1'b1) stateCnt <= stateCnt + 7'h1; // increment the counter
    end
    else if (stateEn == 1'b1) begin // reached the end of the blanking time
      stateCnt <= 6'h0; // restart the state machine: 
      simState <= 4'h0; // go to inter word
    end
    end
  default: begin // assume "0": CS high, inter message blanking
    // this is the starting point of the state machine
    if (stateCnt < 2) begin // wait for a time equivalent to 3 bits
      if (stateEn == 1'b1) stateCnt <= stateCnt + 7'h1; // increment the counter
    end
    else if (stateEn == 1'b1) begin // reached end of the blanking
      stateCnt <= 6'h0; // reset the counter
      simState <= 4'h1; // go to wait
    end
    end  

  endcase
end

// MOSI memory:
// implement an array of MOSI messages to be transmitted in one block
always @(posedge clk)
if (rstn == 1'b0) begin
  mosiPattern[0] <= 32'h33AA; // first message in a block
  mosiPattern[1] <= 32'h44BB; // 2nd message in a block
  mosiPattern[2] <= 32'h55CC; // 3rd message in a block
  mosiPattern[3] <= 32'h55DD; // 4th message in a block
  mosiPattern[4] <= 32'h66EE; // 5th message in a block
end else if (sys_wen ) begin
  // update the messages 
  //uint32_t sim_mosi0;    // 0x3C - first MOSI message to be transmitted
  if (sys_addr[19:0]==20'h3C) mosiPattern[0] <= sys_wdata;
  if (sys_addr[19:0]==20'h40) mosiPattern[1] <= sys_wdata;
  if (sys_addr[19:0]==20'h44) mosiPattern[2] <= sys_wdata;
  if (sys_addr[19:0]==20'h48) mosiPattern[3] <= sys_wdata;
  if (sys_addr[19:0]==20'h4C) mosiPattern[4] <= sys_wdata;
end

// handle the MOSI shift register
always @(posedge clk)
if (rstn == 1'b0) begin
  msgNum <= 6'h01; // by default transmit 2 messages in one block
  mosiShift <= 32'b0; // empty shift register
  prevMosi <= 32'h0;  // previous transmitted MOSI data - to be used to create a MISO message
end else begin
  case (simState) // the content of the shift register depends on the state machine
  4'h1: begin
    // load the MOSI shift register with the next data
    // take the data from the MOSI memory
    mosiShift[31:0] <= mosiPattern[msgCnt];
    end
  4'h2: begin // keep the data from step 1
    end
  4'h3: begin // shift right (transmit MSB first)
    if (shiftEn == 1'b1) mosiShift[31:0] <= { mosiShift[30:0], 1'b0 };
    end
  4'h4: begin
    // remember the MOSI data fror the next message transfer
    prevMosi <= mosiPattern[msgCnt];
    mosiShift <= 32'b0; // reset the shift register
    end
  default: begin
    mosiShift <= 32'b0; // reset the shift register
    end
  endcase
end

// handle the MISO shift register
always @(posedge clk)
if (rstn == 1'b0) begin
  //msgNum <= 6'h02;
  misoShift <= 32'b0; // empty shift register
  misoData[0] <= 8'b1; // different content data for the MISO messages
  misoData[1] <= 8'b1;
  misoData[2] <= 8'b1;
  misoData[3] <= 8'b1;
  misoData[4] <= 8'b1;
end else begin
  case (simState)
  4'h1: begin
    // load the MOSI shift register with the next data
    if (prevMosi == 32'h0) misoShift <= 32'h0; // there was no MOSI data previously
    else misoShift[31:0] <= { prevMosi[31:8], misoData[msgCnt] }; // initialize the MISO
    misoByte <= misoData[msgCnt]; // remember the MISO data for manipulation
    end
  4'h2: begin // keep the data from step 1
    end
  4'h3: begin // shift right (transmit MSB first)
    if (shiftEn == 1'b1) misoShift[31:0] <= { misoShift[30:0], 1'b0 };
    end
  4'h4: begin
    case (prevMosi[1:0]) // update the 8-bit MISO data for the next transfer
    // the update depends on the previous MOSI data
    2'h1: misoByte <= {misoByte[6:0], misoByte[7]}; // shift left
    2'h2: misoByte <= misoByte + 8'h1; // count
    2'h3: misoByte <= {misoByte[0], misoByte[7:1]}; // shift right
    endcase
    misoShift <= 32'b0; // reset the shift register
    end
  4'h5: begin
    misoData[msgCnt] <= misoByte; // remember the MISO data for the next transfer
    end
  default: begin
    misoShift <= 32'b0; // reset the shift register
    end
  endcase
end

// the SPI clock is the continuous running outClk masked with 
// state machine state "transmit"
assign sclk = outClk & simState == 4'h3;
// the CS is high during blanking times
assign cs = simState == 4'h0 | simState == 4'h7;
// the MOSI output port is the MSB of the MOSI shift register
assign mosi = mosiShift[simBits];
// the MISO output port is the MSB of the MISO shift register
assign miso = misoShift[simBits];

endmodule
