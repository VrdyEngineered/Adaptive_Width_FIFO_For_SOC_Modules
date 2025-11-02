-------------------------------------------------
--- Advanced FIFO 8->32 Self-Checking Test  ---
-------------------------------------------------

[0] Starting Reset
[55000] Reset Deasserted. FIFO is empty.

--- Test 1: Fill the FIFO ---

[65000] WRITE: Data 07
[85000] WRITE: Data 1a
[105000] WRITE: Data d1
[125000] WRITE: Data c3
[145000] WRITE: Data ea
[165000] WRITE: Data bd
[185000] WRITE: Data 59
[205000] WRITE: Data f2
[225000] WRITE: Data d8
[245000] WRITE: Data 2a
[265000] WRITE: Data b5
[285000] WRITE: Data c2
[305000] WRITE: Data e8
[325000] WRITE: Data 0f
[345000] WRITE: Data b4
[365000] WRITE: Data c0
[385000] Test 1 Complete. FIFO is full.

--- Test 2: Empty the FIFO ---

[395000] READ: Triggered read.
[405000] READ: Data c3d11a07 correct.
[415000] READ: Triggered read.
[425000] READ: Data f259bdea correct.
[435000] READ: Triggered read.
[445000] READ: Data c2b52ad8 correct.
[455000] READ: Triggered read.
[465000] READ: Data c0b40fe8 correct.
[475000] Test 2 Complete. FIFO is empty.

--- Test 3: Simultaneous Read/Write ---

[485000] WRITE: Data 68
[495000] WARNING: Read attempt while EMPTY. Waiting.
[525000] WRITE: Data 6c
[555000] WRITE: Data 26
[585000] WRITE: Data f9
[605000] READ: Triggered read.
[615000] WRITE: Data ed
[615000] READ: Data f9266c68 correct.
[645000] WARNING: Read attempt while EMPTY. Waiting.
[665000] WRITE: Data 14
[705000] WRITE: Data 18
[745000] WRITE: Data 6e
[765000] READ: Triggered read.
[775000] READ: Data 6e1814ed correct.
[785000] WRITE: Data 2d
[815000] WARNING: Read attempt while EMPTY. Waiting.
[825000] WRITE: Data 45
[865000] WRITE: Data 6e
[915000] WRITE: Data bd
[935000] READ: Triggered read.
[945000] WRITE: Data c3
[945000] READ: Data bd6e452d correct.
[965000] WARNING: Read attempt while EMPTY. Waiting.
[985000] WRITE: Data 31
relaunch_sim: Time (s): cpu = 00:00:02 ; elapsed = 00:00:11 . Memory (MB): peak = 3431.914 ; gain = 0.000
run 2000 ns
[1025000] WRITE: Data 3e
[1055000] WRITE: Data 8a
[1075000] READ: Triggered read.
[1085000] READ: Data 8a3e31c3 correct.
[1095000] WRITE: Data a3
[1105000] WARNING: Read attempt while EMPTY. Waiting.
[1145000] WRITE: Data e1
[1175000] WRITE: Data 93
[1205000] WRITE: Data 81
[1225000] READ: Triggered read.
[1235000] READ: Data 8193e1a3 correct.
[1235000] Test 3 Complete.

--- Test 4: Power Saving (Idle) Check ---

[1235000] Idling for 20 cycles...
Error: rd_ptr changed during idle!
Time: 1435 ns  Iteration: 0  Process: /tb_fifo_8_to_32_v2/Initial232_10  Scope: tb_fifo_8_to_32_v2  File: E:/Xilinx/fifo_data_width_converter/fifo_data_width_converter.srcs/sim_1/new/tb_fifo_8_to_32_v2.sv Line: 312
[1435000] Test 4 Complete. Pointers did not change.

-------------------------------------------------
---           SIMULATION REPORT           ---
-------------------------------------------------
  Total Bytes Written: 36
  Total Words Read:    9

[FAILURE] Found 1 errors. Review log.
-------------------------------------------------