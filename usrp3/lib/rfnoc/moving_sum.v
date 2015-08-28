//
// Copyright 2014 Ettus Research LLC
//

module moving_sum
  #(parameter MAX_LEN_LOG2=10,
    parameter WIDTH=16)
   (input clk, input reset, input clear,
    input [15:0] len,
    input [WIDTH-1:0] i_tdata, input i_tlast, input i_tvalid, output i_tready,
    output [WIDTH+MAX_LEN_LOG2-1:0] o_tdata, output o_tlast, output o_tvalid, input o_tready);

   reg [WIDTH+MAX_LEN_LOG2-1:0]     sum;
   reg [15:0] 			    full_count;
   wire 			    full = full_count == len;

   wire 			    do_op = i_tvalid & i_tready;

   wire [WIDTH-1:0] 		    fifo_out;
   
   axi_fifo #(.WIDTH(WIDTH), .SIZE(MAX_LEN_LOG2)) sample_fifo
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata(i_tdata), .i_tvalid(do_op), .i_tready(),
      .o_tdata(fifo_out), .o_tvalid(), .o_tready(do_op&full));

   always @(posedge clk)
     if(reset | clear)
       full_count <= 0;
     else
       if(do_op & ~full)
	 full_count <= full_count + 1;     // FIXME careful if len changes during operation you must clear

   always @(posedge clk)
     if(reset | clear)
       sum <= 0;
     else if(do_op)
       sum <= sum + { {MAX_LEN_LOG2{i_tdata[WIDTH-1]}}, i_tdata } - (full ? {{MAX_LEN_LOG2{fifo_out[WIDTH-1]}}, fifo_out} : 0);

   axi_fifo_flop #(.WIDTH(WIDTH+MAX_LEN_LOG2+1)) axi_fifo_flop_output
     (.clk(clk), .reset(reset), .clear(clear),
      .i_tdata({i_tlast,sum}), .i_tvalid(i_tvalid), .i_tready(i_tready),
      .o_tdata({o_tlast,o_tdata}), .o_tvalid(o_tvalid), .o_tready(o_tready),
      .occupied(), .space());

endmodule // moving_sum
