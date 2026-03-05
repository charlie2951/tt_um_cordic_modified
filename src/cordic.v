module cordic_core (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,//start cordic core
    input  wire signed [15:0] angle_in,   // Q2.13

    output reg  signed [15:0] cos_out,    // Q2.13
    output reg  signed [15:0] sin_out,    // Q2.13
    output reg         done
);

//////////////////////////////////////////////////////////
// Q2.13 Constants
//////////////////////////////////////////////////////////

localparam signed [15:0] PI      = 16'sd25736;
localparam signed [15:0] HALF_PI = 16'sd12868;

//////////////////////////////////////////////////////////
// Internal Registers
//////////////////////////////////////////////////////////

reg signed [15:0] x, y, z;
reg flip;
reg [3:0] iter;
reg busy;

//////////////////////////////////////////////////////////
// atan table Q2.13
//////////////////////////////////////////////////////////

reg signed [15:0] atan_value;

always @(*) begin
    case(iter)
        4'd0:  atan_value = 16'sd6434;
        4'd1:  atan_value = 16'sd3798;
        4'd2:  atan_value = 16'sd2007;
        4'd3:  atan_value = 16'sd1019;
        4'd4:  atan_value = 16'sd510;
        4'd5:  atan_value = 16'sd255;
        4'd6:  atan_value = 16'sd128;
        4'd7:  atan_value = 16'sd64;
        4'd8:  atan_value = 16'sd32;
        4'd9:  atan_value = 16'sd16;
        4'd10: atan_value = 16'sd8;
        4'd11: atan_value = 16'sd4;
        4'd12: atan_value = 16'sd2;
        4'd13: atan_value = 16'sd1;
        default: atan_value = 16'sd0;
    endcase
end

//////////////////////////////////////////////////////////
// Shifted values
//////////////////////////////////////////////////////////

wire signed [15:0] x_shift = x >>> iter;
wire signed [15:0] y_shift = y >>> iter;

//////////////////////////////////////////////////////////
// Sequential Logic
//////////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        busy <= 0;
        done <= 0;
        iter <= 0;
        x <= 0;
        y <= 0;
        z <= 0;
        flip <= 0;
        cos_out <= 0;
        sin_out <= 0;
    end
    else begin

        done <= 0;

        /////////////////////////////////////////////////
        // Start
        /////////////////////////////////////////////////
        if (start && !busy) begin
            busy <= 1;
            iter <= 0;

            // Quadrant correction
            if (angle_in > HALF_PI) begin
                z <= angle_in - PI;
                flip <= 1;
            end
            else if (angle_in < -HALF_PI) begin
                z <= angle_in + PI;
                flip <= 1;
            end
            else begin
                z <= angle_in;
                flip <= 0;
            end

            x <= 16'sd4974;   // K factor
            y <= 16'sd0;
        end

        /////////////////////////////////////////////////
        // Iteration
        /////////////////////////////////////////////////
        else if (busy) begin

            if (iter < 4'd14) begin

                if (z >= 0) begin
                    x <= x - y_shift;
                    y <= y + x_shift;
                    z <= z - atan_value;
                end
                else begin
                    x <= x + y_shift;
                    y <= y - x_shift;
                    z <= z + atan_value;
                end

                iter <= iter + 1;
            end
            else begin
                if (flip) begin
                    cos_out <= -x;
                    sin_out <= -y;
                end
                else begin
                    cos_out <= x;
                    sin_out <= y;
                end

                busy <= 0;
                done <= 1;
            end

        end
    end
end

endmodule
