`timescale 1ns / 1ps

module axi4_lite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Global Signals
    input wire aclk,
    input wire aresetn,

    // Write Address Channel
    input wire [ADDR_WIDTH-1:0] awaddr,
    input wire awvalid,
    output wire awready,

    // Write Data Channel
    input wire [DATA_WIDTH-1:0] wdata,
    input wire [(DATA_WIDTH/8)-1:0] wstrb,
    input wire wvalid,
    output wire wready,

    // Write Response Channel
    output wire [1:0] bresp,
    output wire bvalid,
    input wire bready,

    // Read Address Channel
    input wire [ADDR_WIDTH-1:0] araddr,
    input wire arvalid,
    output wire arready,

    // Read Data Channel
    output wire [DATA_WIDTH-1:0] rdata,
    output wire [1:0] rresp,
    output wire rvalid,
    input wire rready
);
    //  DATA_WIDTH = 32.

    // Internal Write Channel Registers
    reg [31:0] awaddr_reg;
    reg [31:0] wdata_reg;
    reg [3:0]  wstrb_reg;

    reg aw_done;
    reg w_done;

    reg bvalid_reg;
    reg [1:0] bresp_reg;

    // Internal Read Channel Registers
    
    reg [31:0] rdata_reg;
    reg [1:0]  rresp_reg;
    reg rvalid_reg;

   
    // Memory-Mapped Registers
    reg [31:0] control_reg;
    reg [31:0] operand_a_reg;
    reg [31:0] operand_b_reg;
    
    // Saturating Adder Signals
    wire [15:0] adder_result;
    wire adder_overflow;

    saturating_adder u_saturating_adder (
        .a(operand_a_reg[15:0]),
        .b(operand_b_reg[15:0]),
        .result(adder_result),
        .overflow(adder_overflow)
    );

    // AXI Handshake Signals
    wire aw_handshake;
    wire w_handshake;

    assign aw_handshake = awvalid && awready;
    assign w_handshake  = wvalid && wready;

    wire [31:0] write_addr_now =
        aw_handshake ? awaddr : awaddr_reg;

    wire [31:0] write_data_now =
        w_handshake ? wdata : wdata_reg;

    wire [3:0] write_strb_now =
        w_handshake ? wstrb : wstrb_reg;

   
    // AXI Output Assignments
    assign awready = aresetn && !aw_done && !bvalid_reg;
    assign wready  = aresetn && !w_done && !bvalid_reg;

    assign bvalid = bvalid_reg;
    assign bresp  = bresp_reg;

    assign arready = aresetn && !rvalid_reg;
    assign rvalid = rvalid_reg;
    assign rdata  = rdata_reg;
    assign rresp  = rresp_reg;

    // Write Channel Sequential Logic
    always @(posedge aclk) begin
        if (!aresetn) begin

            awaddr_reg <= 0;
            wdata_reg  <= 0;
            wstrb_reg  <= 0;

            aw_done <= 1'b0;
            w_done  <= 1'b0;

            bvalid_reg <= 1'b0;
            bresp_reg  <= 2'b00;

            control_reg   <= 0;
            operand_a_reg <= 0;
            operand_b_reg <= 0;

        end
        else begin

            // Capture Write Address
            if (aw_handshake) begin
                awaddr_reg <= awaddr;
                aw_done    <= 1'b1;
            end

            // Capture Write Data and Strobes
            if (w_handshake) begin
                wdata_reg <= wdata;
                wstrb_reg <= wstrb;
                w_done    <= 1'b1;
            end

            // Execute when both address and data
            // have been accepted, including this cycle.
            if ((aw_done || aw_handshake) &&
                (w_done || w_handshake) &&
                !bvalid_reg) begin

                case (write_addr_now)

                    // CTRL: 0x00
                    32'h00000000: begin
                        if (write_strb_now[0])
                            control_reg[7:0] <= write_data_now[7:0];
                        if (write_strb_now[1])
                            control_reg[15:8] <= write_data_now[15:8];
                        if (write_strb_now[2])
                            control_reg[23:16] <= write_data_now[23:16];
                        if (write_strb_now[3])
                            control_reg[31:24] <= write_data_now[31:24];

                        bresp_reg <= 2'b00;
                    end

                    // STATUS: 0x04 is read-only
                    32'h00000004: begin
                        bresp_reg <= 2'b10;
                    end

                    // OPERAND A: 0x08
                    32'h00000008: begin
                        if (write_strb_now[0])
                            operand_a_reg[7:0] <= write_data_now[7:0];
                        if (write_strb_now[1])
                            operand_a_reg[15:8] <= write_data_now[15:8];
                        if (write_strb_now[2])
                            operand_a_reg[23:16] <= write_data_now[23:16];
                        if (write_strb_now[3])
                            operand_a_reg[31:24] <= write_data_now[31:24];

                        bresp_reg <= 2'b00;
                    end

                    // OPERAND B: 0x0C
                    32'h0000000C: begin
                        if (write_strb_now[0])
                            operand_b_reg[7:0] <= write_data_now[7:0];
                        if (write_strb_now[1])
                            operand_b_reg[15:8] <= write_data_now[15:8];
                        if (write_strb_now[2])
                            operand_b_reg[23:16] <= write_data_now[23:16];
                        if (write_strb_now[3])
                            operand_b_reg[31:24] <= write_data_now[31:24];

                        bresp_reg <= 2'b00;
                    end

                    // RESULT: 0x10 is read-only
                    32'h00000010: begin
                        bresp_reg <= 2'b10;
                    end

                    // Unsupported Address
                    default: begin
                        bresp_reg <= 2'b11;
                    end

                endcase

                // Clear captured transaction flags
                aw_done <= 1'b0;
                w_done  <= 1'b0;

                // Issue write response
                bvalid_reg <= 1'b1;
            end

            // Hold BVALID until response handshake
            if (bvalid_reg && bready) begin
                bvalid_reg <= 1'b0;
            end
        end
    end

  
    // Read Channel Sequential Logic
    always @(posedge aclk) begin
        if (!aresetn) begin
            rdata_reg  <= 0;
            rresp_reg  <= 2'b00;
            rvalid_reg <= 1'b0;
        end
        else begin

            // Accept address and prepare read response
            if (arvalid && arready) begin

                case (araddr)

                    // CTRL: 0x00
                    32'h00000000: begin
                        rdata_reg <= control_reg;
                        rresp_reg <= 2'b00;
                    end

                    // STATUS: 0x04
                    32'h00000004: begin
                        rdata_reg <= {31'b0, adder_overflow};
                        rresp_reg <= 2'b00;
                    end

                    // OPERAND A: 0x08
                    32'h00000008: begin
                        rdata_reg <= operand_a_reg;
                        rresp_reg <= 2'b00;
                    end

                    // OPERAND B: 0x0C
                    32'h0000000C: begin
                        rdata_reg <= operand_b_reg;
                        rresp_reg <= 2'b00;
                    end

                    // RESULT: 0x10
                    32'h00000010: begin
                        rdata_reg <= {{16{adder_result[15]}},
                                      adder_result};
                        rresp_reg <= 2'b00;
                    end

                    // Unsupported Address
                    default: begin
                        rdata_reg <= 32'b0;
                        rresp_reg <= 2'b11;
                    end

                endcase

                rvalid_reg <= 1'b1;
            end
            // Hold read response until accepted
            else if (rvalid_reg && rready) begin
                rvalid_reg <= 1'b0;
            end
        end
    end

endmodule

