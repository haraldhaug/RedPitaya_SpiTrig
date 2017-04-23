`timescale 1ns / 1ps

module rp_spi_sim_tb;/*#(
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
  repeat(600) @(posedge clk);
  $finish();
end

rp_spi_sim mySim (
  .rstn (rstn),
  .clk (clk),
  .sys_addr (sys_addr),
  .sys_wdata (sys_wdata),
  .sys_wen (sys_wen),
  .cs (cs),
  .sclk (sclk),
  .mosi (mosi),
  .miso (miso)
);

endmodule
