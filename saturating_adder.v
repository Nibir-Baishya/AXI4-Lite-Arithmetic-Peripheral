`timescale 1ns / 1ps

module saturating_adder (
    input  wire signed [15:0] a,
    input  wire signed [15:0] b,
    output reg  signed [15:0] result,
    output reg                overflow
);

    // 17-bit for prevention of loss of carry/sign
    reg signed [16:0] sum;

    always @(*) begin
        sum = {a[15], a} + {b[15], b};

        // Default: no overflow
        overflow = 1'b0;

        // Positive overflow
        if (sum > 17'sd32767) begin
            result   = 16'sh7FFF;  // +32767
            overflow = 1'b1;
        end

        // Negative overflow
        else if (sum < -17'sd32768) begin
            result   = 16'sh8000;  // -32768
            overflow = 1'b1;
        end

        // Normal signed addition
        else begin
            result = sum[15:0];
        end
    end

endmodule

