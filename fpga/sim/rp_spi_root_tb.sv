`timescale 1ns / 1ps

module rp_spi_root_tb;/*#(
  // clock time periods
  realtime  TP = 20ns  // 50MHz
);*/

logic            clk ;  // clock
logic            rstn;  // reset
logic [31:0] sys_addr;
logic [ 31:0] sys_wdata;
logic sys_wen;

logic cs;
logic sclk;
logic mosi;
logic miso;
logic trg;
logic mosiTrg;

initial        clk = 1'h0;
always #(10ns) clk = ~clk;

initial begin
  // initialization
  rstn = 1'b0;
  sys_addr = 32'b0;
  sys_wdata = 32'b0;
  sys_wen = 1'b0;
  repeat(2) @(posedge clk);
  // start
  rstn = 1'b1;
  // 6 clock cycles per SCLK
  // 3 SCLK inter message blabking
  // 16 bits + 1 CS lead + 1 CS lag
  // 1 block is 21 *2 + 19 SCLKs
  // 1 block is 61*6 clks
  // --> 366 clks
  // 732 clks == 2 blocks
  // 1098 clks == 3 blocks
  // 1464 clks == 4 blocks
  // 1830=5, 2196=6
  repeat(4000) @(posedge clk);
  $finish();
end

spi_root spiRoot (
  .rstn (rstn),
  .clk (clk),
  .sys_addr (sys_addr),
  .sys_wdata (sys_wdata),
  .sys_wen (sys_wen),
  .cs (cs),
  .sclk (sclk),
  .mosi (mosi),
  .miso (miso),
  .mosiTrg (mosiTrg),
  .trg (trg)
);

endmodule
