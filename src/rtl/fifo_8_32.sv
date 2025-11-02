`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.10.2025 18:54:28
// Design Name: 
// Module Name: fifo_8_32
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


module fifo_8_32#(parameter ADDR_WIDTH=4 , DATA_WIDTH=8,DEPTH =2**ADDR_WIDTH , READ_WIDTH=4*DATA_WIDTH)(
    // system signals
    input logic clk,rst,
     //write port (producer interface)
     input logic [DATA_WIDTH-1:0] w_data,
     input logic wr_en,
     output logic full,
     
     //Read port (consumer interface)
     output logic [READ_WIDTH-1:0] r_data,
     input logic rd_en,
     output logic empty
);


 //--------------------------------------------------------------------------
    // Sanity check for parameters
    //--------------------------------------------------------------------------
    initial begin
        if (DEPTH % 4!= 0) begin
            $display("Warning: FIFO DEPTH s not a multiple of 4. This may lead to inefficient memory usage.");
        
        end
      end
      
     // Internal signals and memory declaration
     logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
     localparam int PTR_WIDTH   = $clog2(DEPTH);
    localparam int COUNT_WIDTH = $clog2(DEPTH + 1);
     
       // Pointers for read and write operations.
    // The width is calculated to address all locations from 0 to DEPTH-1.
    logic [PTR_WIDTH-1:0 ]wr_ptr,rd_ptr;
    
    logic [COUNT_WIDTH-1:0 ]count; // to check whether empty or not
    
    // Internal signals to determine if a valid write or read will occur.
    logic wr_fire, rd_fire;

    assign wr_fire = wr_en && !full;
    assign rd_fire = rd_en && !empty;
    
    // ------------------------------------------------------------
    // Output data (concatenate 4 bytes into 32-bit)
    // ------------------------------------------------------------
    always_comb begin
        // handle wrap-around using modular addressing
        r_data = {
            mem[(rd_ptr + 3) % DEPTH],
            mem[(rd_ptr + 2) % DEPTH],
            mem[(rd_ptr + 1) % DEPTH],
            mem[(rd_ptr + 0) % DEPTH]
        };
    end

  // ------------------------------------------------------------
    // Sequential logic
    // ------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
        end
        else begin
          // --- Write logic ---
            if (wr_fire) begin
                    mem[wr_ptr] <= w_data;
                wr_ptr <= (wr_ptr == DEPTH-1) ? '0 : wr_ptr + 1;
            end
            // --- Read logic ---
            if (rd_fire) begin
                rd_ptr <= (rd_ptr + 4 >= DEPTH) ? (rd_ptr + 4 - DEPTH) : (rd_ptr + 4);
            end
            
            // --- Counter logic ---
            unique case ({wr_fire, rd_fire})
                2'b10: count <= count + 1;   // write only
                2'b01: count <= count - 4;   // read only (consume 4 bytes)
                2'b11: count <= count - 3;   // write+read in same cycle
                default: count <= count;     // idle
            endcase
        
        end
   end
   // ------------------------------------------------------------
    // Status flags
    // ------------------------------------------------------------
    assign full  = (count == DEPTH);
    assign empty = (count < 4);
endmodule
