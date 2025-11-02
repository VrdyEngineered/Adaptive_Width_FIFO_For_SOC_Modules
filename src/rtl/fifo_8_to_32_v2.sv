`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.10.2025 10:54:02
// Design Name: 
// Module Name: fifo_8_to_32_v2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Corrected version of an 8-bit in, 32-bit out FIFO.
// 
// Dependencies: 
// 
// Revision:
// Revision 1.00 - Corrected functional and synthesis errors.
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------------------------
// This Updated Code deals with **Power saving** , **Status REG ** (which shows the internal fill levels or depth monitoring )
// also ** Parity checker **
//------------------------------------------------------------------------------------------------------
module fifo_8_to_32_v2 #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 2**ADDR_WIDTH,
    parameter READ_WIDTH = 4*DATA_WIDTH
) (
    // System signals
    input  logic clk,
    input  logic rst, // Assuming active-high reset based on usage `rst`

    // Write port (producer interface)
    input  logic [DATA_WIDTH-1:0] w_data,
    input  logic wr_en,
    output logic full,

    // Read port (consumer interface)
    output logic [READ_WIDTH-1:0] r_data,
    input  logic rd_en,
    output logic empty,
    
     // checks internal fill level
    output logic [DEPTH-1:0] status_reg,
    // NEW: Output to flag a data integrity error
    output logic parity_error
);

    //--------------------------------------------------------------------------
    // Sanity check for parameters
    //--------------------------------------------------------------------------
    initial begin
        if (DEPTH % 4 != 0) begin
            $display("Warning: FIFO DEPTH is not a multiple of 4. This may lead to inefficient memory usage.");
        end
    end
    
    // Internal signals and memory declaration
    logic [DATA_WIDTH:0] mem [0:DEPTH-1];
    
    localparam int PTR_WIDTH   = $clog2(DEPTH);
    localparam int COUNT_WIDTH = $clog2(DEPTH + 1);

    // Pointers for read and write operations.
    logic [PTR_WIDTH-1:0]   wr_ptr, rd_ptr;
    logic [COUNT_WIDTH-1:0] count; // Counter for number of items in FIFO

    // Internal signals to determine if a valid write or read will occur.
    logic wr_fire, rd_fire;

    assign wr_fire = wr_en && !full;
    assign rd_fire = rd_en && !empty;

    // ------------------------------------------------------------
    // Output data (combinational read)
    // This correctly concatenates 4 bytes based on the current read pointer.
    // This block was correct and is preserved.
    // ------------------------------------------------------------
   // NEW: Intermediate signals to hold the full words (data + parity) from memory.
    logic [DATA_WIDTH:0] word0, word1, word2, word3;

    assign word0 = mem[(rd_ptr + 0) % DEPTH];
    assign word1 = mem[(rd_ptr + 1) % DEPTH];
    assign word2 = mem[(rd_ptr + 2) % DEPTH];
    assign word3 = mem[(rd_ptr + 3) % DEPTH];

    // MODIFIED: r_data now slices the data portion from the intermediate words.
    assign r_data = {
        word3[DATA_WIDTH-1:0],
        word2[DATA_WIDTH-1:0],
        word1[DATA_WIDTH-1:0],
        word0[DATA_WIDTH-1:0]
    };
    // -----------------------------------------------------
    // Main Sequential Block for Pointers, Memory, and Count
    // -----------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin // Active-high reset
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
        end else begin
            
          // Power saving , no switching when states are idle 
            if (wr_fire && !rd_fire) begin
                // Write only
                // MODIFIED: Store data plus its calculated even parity bit
                mem[wr_ptr] <= {^w_data, w_data};
                wr_ptr      <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1;
                count       <= count + 1;
            end
            else if (!wr_fire && rd_fire) begin
                // Read only
                rd_ptr      <= (rd_ptr + 4 >= DEPTH) ? (rd_ptr + 4 - DEPTH) : (rd_ptr + 4); // Read pointer increments by 4
                count       <= count - 4;
            end
            else if (wr_fire && rd_fire) begin
                // Simultaneous read and write
                // MODIFIED: Store data plus its calculated even parity bit
                mem[wr_ptr] <={^w_data, w_data};
                wr_ptr      <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1;
                rd_ptr      <= (rd_ptr + 4 >= DEPTH) ? (rd_ptr + 4 - DEPTH) : (rd_ptr + 4);
                count       <= count - 3; // Net change: +1 write, -4 read
            end
            // NOTE: If neither wr_fire nor rd_fire is active, all registers hold their value.
            // No explicit 'else' case is needed, saving power by avoiding unnecessary updates.
        end
    end

    // -----------------------------------------------------
    // Status flags
    // -----------------------------------------------------
    assign full  = (count == DEPTH);
    assign empty = (count < 4); // Empty if we can't perform a full 32-bit read
    
    // NEW: Combinational parity check logic
    // An error occurs if the stored parity bit doesn't match a fresh calculation.
    assign parity_error = (word0[DATA_WIDTH] !== ^word0[DATA_WIDTH-1:0]) |
                          (word1[DATA_WIDTH] !== ^word1[DATA_WIDTH-1:0]) |
                          (word2[DATA_WIDTH] !== ^word2[DATA_WIDTH-1:0]) |
                          (word3[DATA_WIDTH] !== ^word3[DATA_WIDTH-1:0]);
                          
    //-----------------------------------------------------------------
    // Live depth monitoring
    //-------------------------------------------------------------------
    always_comb begin
        for (int i = 0; i < DEPTH; i++) begin
            status_reg[i] = (i < count);
        end
    end

endmodule