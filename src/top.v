
//byte_select-0-> angle[0-3], 1-> [4-7] and so on

module cordic_top (
    input  wire clk,
    input  wire rst_n,
    input  wire valid,
    input  wire sin_cos,
    input wire [1:0] byte_select,
    input wire [3:0] angle_data,//angle data word wise,send LSB 1st
    output wire [15:0] y //result 16 bit
    
);

//////////////////////////////////////////////////////////
// Controller
//////////////////////////////////////////////////////////

wire cordic_start;
wire [15:0] angle;
wire [15:0] sin_out, cos_out;
wire cordic_done;


controller ctrl0 (
    .clk(clk),
    .rst_n(rst_n),
    .rx_data(angle_data),//input data
    .valid(valid), //1 bit valid input
    .sin_cos(sin_cos), //select sine or cosine output
    .byte_select(byte_select),//send byte number
    .cordic_start(cordic_start), //start signal from cordic
    .angle(angle),//to output port
    .sin_out(sin_out), //sin output from cordic
    .cos_out(cos_out),//cos output from cordic
    .cordic_done(cordic_done), //input to start cordic core
    .result(y)
   );

//////////////////////////////////////////////////////////
// CORDIC CORE (Rotation only)
//////////////////////////////////////////////////////////

cordic_core u_cordic (
    .clk(clk),
    .rst_n(rst_n),
    .start(cordic_start),
    .angle_in(angle),
    .cos_out(cos_out),
    .sin_out(sin_out),
    .done(cordic_done)
);


endmodule
