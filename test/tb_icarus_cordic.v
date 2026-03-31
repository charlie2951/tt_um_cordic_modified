`default_nettype none
`timescale 1ns / 1ps
`include "project.v"
/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
  tt_um_cordic user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  //temporary regs
  reg valid,sin_cos;
  reg [1:0] byte_select;
  reg [3:0] angle_data;
  reg [15:0] y;
  integer theta;
  reg [15:0] angle_in;
  real angle_deg;
  real expected_result;
  real dut_result;
  real err;

  //separating inputs and controls
  always @(*) begin
     ui_in[7]=valid;
     ui_in[6]=sin_cos;
    ui_in[5:4]=byte_select;
    ui_in[3:0]=angle_data;
    y = {uio_out,uo_out};
  end
  
  function real fixed_to_real;
    input signed [15:0] val;
    begin
      fixed_to_real = val / (2.0**13);
    end
  endfunction
  function signed [15:0] real_to_fixed;
    input real val;
    begin
      real_to_fixed = val * (2.0**13);
    end
  endfunction

  // Applying Test vectors
  initial
  begin
    rst_n = 0;clk=0;
    #200;
    rst_n = 1;
    // Run test
    // SINE TEST for
    $display("SINE/COSINE TEST....");
    sin_cos=1;
for(theta=-180; theta <=180 ; theta=theta+15)
    begin
      // Convert to fixed Q1.14
      angle_in = real_to_fixed(3.141592653589793*theta/180);//convert deg->rad->fixed pt
      valid = 1;
      byte_select = 2'b00;
      angle_data = angle_in[3:0];
      #100; //send 1st 4 bit;
      byte_select = 2'b01;
      angle_data = angle_in[7:4];
      #100; //send 2nd 4 bit;
      byte_select = 2'b10;
      angle_data = angle_in[11:8];
      #100; //send 3rd 4 bit;
      byte_select = 2'b11;
      angle_data = angle_in[15:12];
      #100; //send last 4 bit;
      #100000; //wait for finishing the conversion
      // Convert results
     dut_result = fixed_to_real(y);

      if(sin_cos==0)
        expected_result = $sin(3.141592653589793*theta/180);
      else
        expected_result = $cos(3.141592653589793*theta/180);


      err = dut_result - expected_result;

      $display("--------------------------------------------------");
      $display("Mode: %d (1-> Sine, 2-> Cosine), Angle(Degree) = %d", sin_cos, theta);
      $display("RESULT -> DUT: %f  Expected: %f  Error: %0.4e",
               dut_result, expected_result, $abs(err));

      #10000;
    end
    
    $display("Test Completed.");
    #100000;
    $finish;
  end
always #5 clk=!clk;
endmodule
