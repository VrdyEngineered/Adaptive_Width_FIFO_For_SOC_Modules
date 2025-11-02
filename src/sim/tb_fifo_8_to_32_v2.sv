`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.10.2025 10:55:26
// Design Name: 
// Module Name: tb_fifo_8_to_32_v2
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


module tb_fifo_8_to_32_v2;
    // ------------------------------------------------------------
    // Parameters
    // ------------------------------------------------------------
    localparam ADDR_WIDTH = 4;
    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 2**ADDR_WIDTH;
    localparam READ_WIDTH = 4 * DATA_WIDTH;
    localparam CLK_PERIOD = 10ns; // 100MHz clock

    // ------------------------------------------------------------
    // DUT Signal Declarations
    // ------------------------------------------------------------
    logic clk, rst;
    logic [DATA_WIDTH-1:0] w_data;
    logic wr_en;
    logic full;
    logic [READ_WIDTH-1:0] r_data;
    logic rd_en;
    logic empty;

    // New ports for the advanced DUT
    logic [DEPTH-1:0] status_reg;
    logic parity_error;
    
     localparam PTR_WIDTH   = $clog2(DEPTH);
     logic [PTR_WIDTH-1:0] rd_ptr_before , wr_ptr_before;
    

    // ------------------------------------------------------------
    // Testbench Internal Variables
    // ------------------------------------------------------------
    
    // The "Scoreboard": A queue that mirrors the FIFO's data.
    logic [DATA_WIDTH-1:0] scoreboard_q[$]; 
    
    // Shadow counter to check against status_reg
    logic [$clog2(DEPTH + 1)-1:0] local_count;
    
    integer error_count = 0;
    integer write_count = 0;
    integer read_count  = 0;

    // ------------------------------------------------------------
    // Instantiate FIFO (Use the new module name)
    // ------------------------------------------------------------
    fifo_8_to_32_v2 #(
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
        .empty(empty),
        // Connect the new ports
        .status_reg(status_reg),
        .parity_error(parity_error)
    );

    // ------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // ------------------------------------------------------------
    // Reusable Tasks for Clean Stimulus
    // ------------------------------------------------------------

    // Task to reset the DUT
    task reset_dut;
        $display("[%0t] Starting Reset", $time);
        rst   = 1;
        wr_en = 0;
        rd_en = 0;
        w_data = '0;
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);
        $display("[%0t] Reset Deasserted. FIFO is empty.", $time);
        
        // Check initial state
        assert (empty == 1) else begin
            $error("FIFO not empty after reset!");
            error_count++;
        end
        assert (full == 0);
        assert (status_reg == 0);
        local_count = 0;
    endtask

    // Task to write one byte
    task write_byte(input logic [DATA_WIDTH-1:0] data);
        @(posedge clk);
        if (full) begin
            $display("[%0t] WARNING: Write attempt while FULL. Waiting.", $time);
            wait(!full);
            @(posedge clk);
        end
        
        wr_en  = 1;
        w_data = data;
        $display("[%0t] WRITE: Data %h", $time, data);
        
        // Push to our scoreboard for checking later
        scoreboard_q.push_back(data);
        local_count++;
        write_count++;
        
        @(posedge clk);
        wr_en = 0;
    endtask

    // Task to read one 32-bit word (and check it)
    task read_word;
        logic [READ_WIDTH-1:0] expected_data;
        
        @(posedge clk);
        if (empty) begin
            $display("[%0t] WARNING: Read attempt while EMPTY. Waiting.", $time);
            wait(!empty);
            @(posedge clk);
        end
        
        rd_en = 1;
        $display("[%0t] READ: Triggered read.", $time);
        @(posedge clk);
        rd_en = 0;

        // --- This is the CHECK ---
        // Assemble the expected data from our scoreboard
        expected_data = {scoreboard_q[3], scoreboard_q[2], scoreboard_q[1], scoreboard_q[0]};

        if (r_data !== expected_data) begin
            $error("[%0t] *** DATA MISMATCH! ***", $time);
            $error("  Expected: %h", expected_data);
            $error("  Got:      %h", r_data);
            error_count++;
        end else begin
            $display("[%0t] READ: Data %h correct.", $time, r_data);
        end
        
        // Data was correct, so parity error should be LOW
        if (parity_error) begin
            $error("[%0t] *** PARITY ERROR! *** Flag is high when data is correct.", $time);
            error_count++;
        end

        // Pop the 4 read items from our scoreboard
        for (int i = 0; i < 4; i++) scoreboard_q.pop_front();
        local_count -= 4;
        read_count++;
    endtask

    // ------------------------------------------------------------
    // Concurrent Assertions (Running always)
    // ------------------------------------------------------------
    
    // This assertion checks your status_reg every single cycle!
    always @(negedge clk) begin
        if (!rst) begin
            // Check that status_reg matches our shadow counter
            // $countones is a built-in function
            assert ($countones(status_reg) == local_count) else begin
                $error("[%0t] STATUS_REG mismatch! Expected %0d ones, got %0d", 
                       $time, local_count, $countones(status_reg));
                error_count++;
            end
        end
    end
    
    // Check that 'empty' flag is correct
    always @(negedge clk) begin
        if(!rst) begin
            assert(empty == (local_count < 4)) else
                $error("Empty flag logic is incorrect!");
        end
    end

    // ------------------------------------------------------------
    // Main stimulus
    // ------------------------------------------------------------
    initial begin
        $display("\n-------------------------------------------------");
        $display("--- Advanced FIFO 8->32 Self-Checking Test  ---");
        $display("-------------------------------------------------\n");

        reset_dut();

        // ---------------------------------
        // Test 1: Fill the FIFO completely
        // ---------------------------------
        $display("\n--- Test 1: Fill the FIFO ---\n");
        for (int i = 0; i < DEPTH; i++) begin
            write_byte($urandom_range(0, 255)); // Use random data
        end
        
        @(posedge clk);
        assert (full == 1) else begin
            $error("FIFO not full after writing %0d bytes!", DEPTH);
            error_count++;
        end
        $display("[%0t] Test 1 Complete. FIFO is full.", $time);

        // ---------------------------------
        // Test 2: Empty the FIFO completely
        // ---------------------------------
        $display("\n--- Test 2: Empty the FIFO ---\n");
        for (int i = 0; i < (DEPTH / 4); i++) begin
            read_word();
        end
        
        @(posedge clk);
        assert (empty == 1) else begin
            $error("FIFO not empty after reading all words!");
            error_count++;
        end
        $display("[%0t] Test 2 Complete. FIFO is empty.", $time);
        
        // ---------------------------------
        // Test 3: Simultaneous Read/Write
        // ---------------------------------
        $display("\n--- Test 3: Simultaneous Read/Write ---\n");
        fork
            // Writer process
            begin
                for (int i = 0; i < 20; i++) begin
                    write_byte($urandom_range(0, 255));
                    repeat($urandom_range(1, 3)) @(posedge clk); // Random delay
                end
            end
            
            // Reader process
            begin
                for (int i = 0; i < 5; i++) begin // 5 reads * 4 bytes/read = 20 writes
                    repeat($urandom_range(1, 3)) @(posedge clk); // Random delay
                    read_word();
                end
            end
        join
        $display("[%0t] Test 3 Complete.", $time);

        // ---------------------------------
        // Test 4: Power Saving (Idle) Check
        // ---------------------------------
        $display("\n--- Test 4: Power Saving (Idle) Check ---\n");
        wr_en = 0;
        rd_en = 0;
        // We can't *see* power, but we can check that internal pointers
        // (which you made power-gated) are not changing.
        // We use the dot-notation to peek inside the DUT.
      wr_ptr_before = uut.wr_ptr ;
       rd_ptr_before = uut.rd_ptr ;
        
        $display("[%0t] Idling for 20 cycles...", $time);
        repeat(20) @(posedge clk);
        
        assert(uut.wr_ptr == wr_ptr_before) else 
            $error("wr_ptr changed during idle!");
        assert(uut.rd_ptr == rd_ptr_before) else 
            $error("rd_ptr changed during idle!");
            
        $display("[%0t] Test 4 Complete. Pointers did not change.", $time);

        // ---------------------------------
        // Final Report
        // ---------------------------------
        $display("\n-------------------------------------------------");
        $display("---           SIMULATION REPORT           ---");
        $display("-------------------------------------------------");
        $display("  Total Bytes Written: %0d", write_count);
        $display("  Total Words Read:    %0d", read_count);
        
        if (error_count == 0) begin
            $display("\n[SUCCESS] All tests passed! No errors found.");
        end else begin
            $display("\n[FAILURE] Found %0d errors. Review log.", error_count);
        end
        $display("-------------------------------------------------\n");
        
        $finish;
    end

   
endmodule
