`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2026 15:17:29
// Design Name: 
// Module Name: tb_axi4_lite_slave
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_axi4lite_slave;

    reg aclk;
    reg aresetn;

    reg [31:0] awaddr;
    reg awvalid;
    wire awready;

    reg [31:0] wdata;
    reg [3:0] wstrb;
    reg wvalid;
    wire wready;

    wire [1:0] bresp;
    wire bvalid;
    reg bready;

    reg [31:0] araddr;
    reg arvalid;
    wire arready;

    wire [31:0] rdata;
    wire [1:0] rresp;
    wire rvalid;
    reg rready;

    // Instantiate the design
    axi4_lite_slave dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .awaddr(awaddr),
        .awvalid(awvalid),
        .awready(awready),
        .wdata(wdata),
        .wstrb(wstrb),
        .wvalid(wvalid),
        .wready(wready),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready),
        .araddr(araddr),
        .arvalid(arvalid),
        .arready(arready),
        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),
        .rready(rready)
    );

    // Generate a 100 MHz clock
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // Simple AXI write task
    task write_reg;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(negedge aclk);
            awaddr = addr;
            awvalid = 1;
            wdata = data;
            wstrb = 4'b1111;
            wvalid = 1;

            // Wait until both channels are accepted
            while (!(awready && wready))
                @(negedge aclk);

            @(negedge aclk);
            awvalid = 0;
            wvalid = 0;

            // Accept write response
            bready = 1;
            wait (bvalid == 1);
            @(negedge aclk);
            bready = 0;
        end
    endtask

    // Simple AXI read task
    task read_reg;
        input [31:0] addr;
        begin
            @(negedge aclk);
            araddr = addr;
            arvalid = 1;

            wait (arready == 1);
            @(negedge aclk);
            arvalid = 0;

            // Wait for returned data
            wait (rvalid == 1);
            $display("Address = %h, Read Data = %0d, Response = %b",
                     addr, rdata, rresp);

            rready = 1;
            @(negedge aclk);
            rready = 0;
        end
    endtask

    // Main test sequence
    initial begin
        aresetn = 0;

        awaddr = 0;
        awvalid = 0;
        wdata = 0;
        wstrb = 0;
        wvalid = 0;
        bready = 0;

        araddr = 0;
        arvalid = 0;
        rready = 0;

        repeat (3) @(negedge aclk);
        aresetn = 1;

        // Write operand A = 10000
        write_reg(32'h08, 32'd10000);

        // Write operand B = 10000
        write_reg(32'h0C, 32'd10000);

        // Read result: expected 20000
        read_reg(32'h10);

        // Read overflow status: expected 0
        read_reg(32'h04);

        // Test positive overflow: 25000 + 15000
        write_reg(32'h08, 32'd25000);
        write_reg(32'h0C, 32'd15000);

        // Expected result = 32767, overflow = 1
        read_reg(32'h10);
        read_reg(32'h04);

        #20;
        $finish;
    end

endmodule

