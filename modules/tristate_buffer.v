// https://nandland.com/create-tri-state-buffer-in-vhdl-and-verilog/
module tristate_buffer (out, data, en);
  input data, en;
  output out;
  assign out = en ? data : 1'bz;
endmodule