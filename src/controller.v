module controller (
    input  wire clk,
    input  wire rst_n,

    //from external inputs
    input  wire [3:0] rx_data,//input data
    input  wire valid, //i bit valid input
    input  wire sin_cos, //select sine or cosine output
    input  wire [1:0] byte_select,//send byte number
    //controller output
    output reg  cordic_start, //start signal from cordic
    output reg  [15:0] angle,//to output port
   //input from cordic block
    input  wire [15:0] sin_out, //sin output from cordic
    input  wire [15:0] cos_out,//cos output from cordic
    input  wire cordic_done, //input to start cordic core
 //display result to output
    output reg  [15:0] result
   // output wire ready, //status
   // output reg  done //status
);

localparam IDLE=0,
           RX_A0=1,RX_A1=2,RX_A2=3,RX_A3=4,
           START=5,WAIT=6;

reg [2:0] state;
reg  disp_select;//to select whether sine or cosine output

//assign ready = (state == IDLE);

always @(posedge clk ) begin
    if (!rst_n) begin
        state <= IDLE;
        cordic_start <= 0;
        disp_select <= 0;
        state <= 0;
        //done <= 0;
    end else begin

        cordic_start <= 0;
        //done <= 0;

        case(state)

        IDLE:
            if (valid) begin
                disp_select <= sin_cos;
                state <= RX_A0;
            end

        RX_A0: if (valid && byte_select==2'b00) begin angle[3:0]   <= rx_data; state <= RX_A1; end
        RX_A1: if (valid && byte_select==2'b01) begin angle[7:4]   <= rx_data; state <= RX_A2; end
        RX_A2: if (valid && byte_select==2'b10) begin angle[11:8]  <= rx_data; state <= RX_A3; end
        RX_A3: if (valid && byte_select==2'b11) begin angle[15:12] <= rx_data; state <= START; end

        START: begin
            cordic_start <= 1;
            state <= WAIT;
        end

        WAIT:
            if (cordic_done) begin
                result <= disp_select ? cos_out : sin_out;
               // done <= 1;
                state <= IDLE;
            end

        endcase
    end
end

endmodule
