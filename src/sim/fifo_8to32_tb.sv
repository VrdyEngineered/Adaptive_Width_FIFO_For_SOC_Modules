`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.10.2025
// Design Name: FIFO 8→32 Testbench
// Module Name: fifo_8to32_tb
// Description: Testbench for 8-bit write to 32-bit read FIFO buffer
//////////////////////////////////////////////////////////////////////////////////

module fifo_8to32_tb;

    // ------------------------------------------------------------
    // Parameters
    // ------------------------------------------------------------
    localparam ADDR_WIDTH = 4;
    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 2**ADDR_WIDTH;
    localparam READ_WIDTH = 4 * DATA_WIDTH;

    // ------------------------------------------------------------
    // DUT Signal Declarations
    // ------------------------------------------------------------
    logic clk, rst;
    logic [DATA_WIDTH-1:0]  w_data;
    logic                   wr_en;
    logic                   full;
    logic [READ_WIDTH-1:0]  r_data;
    logic                   rd_en;
    logic                   empty;

    // ------------------------------------------------------------
    // Instantiate FIFO
    // ------------------------------------------------------------
    fifo_8_32 #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .READ_WIDTH(READ_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .w_data(w_data),
        .wr_en(wr_en),
        .full(full),
        .r_data(r_data),
        .rd_en(rd_en),
        .empty(empty)
    );

    // ------------------------------------------------------------
    // Clock generation (20ns period)
    // ------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Main stimulus
    // ------------------------------------------------------------
    initial begin
        $display("\n---------------- FIFO 8→32 Data Width Converter Test ----------------\n");

        // Initialize signals
        rst    = 1;
        wr_en  = 0;
        rd_en  = 0;
        w_data = 8'h00;

        // Hold reset for few cycles
        repeat(3) @(posedge clk);
        rst = 0;
        $display("[%0t] Reset Deasserted", $time);

        // --------------------------------------------------------
        // WRITE 16 BYTES INTO FIFO
        // --------------------------------------------------------
        for (int i = 0; i < 16; i++) begin
            @(negedge clk);
            if (!full) begin
                wr_en  = 1;
                w_data = i + 8'h11; // Example pattern: 0x11, 0x12, 0x13, ...
                $display("[%0t] WRITE: w_data = %h (count=%0d)", $time, w_data, i);
            end
        end
        @(negedge clk);
        wr_en = 0;

        // --------------------------------------------------------
        // READ FROM FIFO (every 4 bytes = 1 read)
        // --------------------------------------------------------
        repeat(2) @(posedge clk); // Small gap

        for (int j = 0; j < 4; j++) begin
            @(negedge clk);
            if (!empty) begin
                rd_en = 1;
                $display("[%0t] READ TRIGGERED", $time);
            end
            @(posedge clk); // wait for data to update
            if (rd_en && !empty)
                $display("[%0t] READ OUTPUT: r_data = %h", $time, r_data);
        end

        @(negedge clk);
        rd_en = 0;

        // --------------------------------------------------------
        // Simulate simultaneous read/write
        // --------------------------------------------------------
        repeat(3) @(posedge clk);
        $display("\n[Simultaneous Read/Write test]");
        for (int k = 0; k < 8; k++) begin
            @(negedge clk);
            wr_en  = 1;
            rd_en  = (k % 2 == 0);  // every alternate cycle read
            w_data = 8'hA0 + k;
            $display("[%0t] Simul: Write=%h  Read_en=%b  r_data=%h", $time, w_data, rd_en, r_data);
        end

        @(negedge clk);
        wr_en = 0;
        rd_en = 0;

        // --------------------------------------------------------
        // End simulation
        // --------------------------------------------------------
        repeat(5) @(posedge clk);
        $display("\n[Simulation Completed Successfully]");
        $finish;
    end

endmodule
