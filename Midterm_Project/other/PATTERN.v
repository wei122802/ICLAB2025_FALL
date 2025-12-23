`ifdef RTL
	`define CYCLE_TIME 20.0 
	`define RTL_GATE
`elsif GATE
	`define CYCLE_TIME 20.0
	`define RTL_GATE
`elsif CHIP
    `define CYCLE_TIME 20.0
    `define CHIP_POST 
`elsif POST
    `define CYCLE_TIME 20.0
    `define CHIP_POST 
`endif

// `define CYCLE_TIME_DATA 31.7

`ifdef FUNC
`define PAT_NUM 1
`define MAX_WAIT_READY_CYCLE 2000
`endif
`ifdef PERF
`define PAT_NUM 1
`define MAX_WAIT_READY_CYCLE 100000
`endif

// show information
`define PRINT 1

`include "../00_TESTBED/MEM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM_data.v"
`include "../00_TESTBED/pseudo_DRAM_inst.v"

module PATTERN(
    			clk,
			  rst_n,
		   IO_stall,


         awid_s_inf,
       awaddr_s_inf,
       awsize_s_inf,
      awburst_s_inf,
        awlen_s_inf,
      awvalid_s_inf,
      awready_s_inf,
                    
        wdata_s_inf,
        wlast_s_inf,
       wvalid_s_inf,
       wready_s_inf,
                    
          bid_s_inf,
        bresp_s_inf,
       bvalid_s_inf,
       bready_s_inf,
                    
         arid_s_inf,
       araddr_s_inf,
        arlen_s_inf,
       arsize_s_inf,
      arburst_s_inf,
      arvalid_s_inf,
                    
      arready_s_inf, 
          rid_s_inf,
        rdata_s_inf,
        rresp_s_inf,
        rlast_s_inf,
       rvalid_s_inf,
       rready_s_inf 
    );

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
parameter ID_WIDTH=4, DATA_WIDTH=16, ADDR_WIDTH=32, DRAM_NUMBER=2, WRIT_NUMBER=1;

output reg			  clk,rst_n;
input				IO_stall;

// axi write address channel 
input wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_s_inf;
input wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_s_inf;
input wire [WRIT_NUMBER * 3 -1:0]            awsize_s_inf;
input wire [WRIT_NUMBER * 2 -1:0]           awburst_s_inf;
input wire [WRIT_NUMBER * 7 -1:0]             awlen_s_inf;
input wire [WRIT_NUMBER-1:0]                awvalid_s_inf;
output wire [WRIT_NUMBER-1:0]               awready_s_inf;
// axi write data channel 
input wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_s_inf;
input wire [WRIT_NUMBER-1:0]                  wlast_s_inf;
input wire [WRIT_NUMBER-1:0]                 wvalid_s_inf;
output wire [WRIT_NUMBER-1:0]                wready_s_inf;
// axi write response channel
output wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_s_inf;
output wire [WRIT_NUMBER * 2 -1:0]             bresp_s_inf;
output wire [WRIT_NUMBER-1:0]             	  bvalid_s_inf;
input wire [WRIT_NUMBER-1:0]                  bready_s_inf;
// -----------------------------
// axi read address channel 
input wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_s_inf;
input wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_s_inf;
input wire [DRAM_NUMBER * 7 -1:0]            arlen_s_inf;
input wire [DRAM_NUMBER * 3 -1:0]           arsize_s_inf;
input wire [DRAM_NUMBER * 2 -1:0]          arburst_s_inf;
input wire [DRAM_NUMBER-1:0]               arvalid_s_inf;
output wire [DRAM_NUMBER-1:0]              arready_s_inf;
// -----------------------------
// axi read data channel 
output wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_s_inf;
output wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_s_inf;
output wire [DRAM_NUMBER * 2 -1:0]             rresp_s_inf;
output wire [DRAM_NUMBER-1:0]                  rlast_s_inf;
output wire [DRAM_NUMBER-1:0]                 rvalid_s_inf;
input wire [DRAM_NUMBER-1:0]                  rready_s_inf;
// -----------------------------

//---------------------------------------------------------------------
//   Reg          
//---------------------------------------------------------------------
reg signed [15 : 0] gdata_DRAM [0 : 4095]; 
reg  [15 : 0] ginstr_DRAM [0 : 4095];

reg [31: 0] buffer_addr; // trash addr reader
reg signed [5 : 0] pimm_value;

reg signed [15 : 0] gregfile [0 : 15];
reg signed [15 : 0] old_rs, old_rt, old_rd, old_ddram;
reg [15 : 0] last_dram_addr, fut_dram_addr;

reg [15 : 0] pc;
reg [15 : 0] instruction;
reg [3 : 0] rs, rt, rd;
reg signed [4 : 0] immediate;
reg [12 : 0] address; 

reg[9*8:1]  reset_color  = "\033[1;0m";
reg[10*8:1] black_txtpf  = "\033[1;30m";
reg[10*8:1] red_txtpf    = "\033[1;31m";
reg[10*8:1] green_txtpf  = "\033[1;32m";
reg[10*8:1] yellow_txtpf = "\033[1;33m";
reg[10*8:1] blue_txtpf   = "\033[1;34m";
reg[10*8:1] purple_txtpf = "\033[1;35m";
reg[10*8:1] cyan_txtpf   = "\033[1;36m";
reg[10*8:1] gray_txtpf   = "\033[1;37m";
reg[10*8:1] white_txtpf  = "\033[1;38m";

//---------------------------------------------------------------------
//   PARAMETER & INT          
//---------------------------------------------------------------------
parameter CYCLE = `CYCLE_TIME;
parameter PRINT_MODE = `PRINT;

parameter INST_FILE = "../00_TESTBED/DRAM/DRAM_inst.dat";
parameter DATA_FILE = "../00_TESTBED/DRAM/DRAM_data.dat";

integer instruction_type;
integer ddram_error;
integer total_latency;
integer i;
integer pat_latency;
integer lat;
integer inst10_count;
integer inst_count;
integer ddx;
integer data_file_ptr;
integer instr_file_ptr;
integer re;
//---------------------------------------------------------------------
//   DRAM          
//---------------------------------------------------------------------

pseudo_DRAM_inst pINST_DRAM(
  	.clk(clk),
  	.rst_n(rst_n),
	/* slave interface */
    // axi write address channel 
    // src master
    .awid_s_inf(),
    .awaddr_s_inf(),
    .awsize_s_inf(),
    .awburst_s_inf(),
    .awlen_s_inf(),
    .awvalid_s_inf(),
    // src slave
    .awready_s_inf(),
    
    // axi write data channel 
    // src master
    .wdata_s_inf(),
    .wlast_s_inf(),
    .wvalid_s_inf(),
    // src slave
    .wready_s_inf(),
   
    // axi write response channel 
    // src slave
    .bid_s_inf(),
    .bresp_s_inf(),
    .bvalid_s_inf(),
    // src master 
    .bready_s_inf(),
    // -----------------------------
   
    // axi read address channel 
    // src master
    .arid_s_inf(arid_s_inf[DRAM_NUMBER*ID_WIDTH -1 : ID_WIDTH]),
    .araddr_s_inf(araddr_s_inf[DRAM_NUMBER*ADDR_WIDTH -1 : ADDR_WIDTH]),
    .arlen_s_inf(arlen_s_inf[DRAM_NUMBER*7 -1 : 7]),
    .arsize_s_inf(arsize_s_inf[DRAM_NUMBER*3 -1 : 3]),
    .arburst_s_inf(arburst_s_inf[DRAM_NUMBER*2 -1 : 2]),
    .arvalid_s_inf(arvalid_s_inf[1]),
    // src slave
    .arready_s_inf(arready_s_inf[1]),
    // -----------------------------
   
    // axi read data channel 
    // slave
    .rid_s_inf(rid_s_inf[DRAM_NUMBER * ID_WIDTH-1 : ID_WIDTH]),
    .rdata_s_inf(rdata_s_inf[DRAM_NUMBER * DATA_WIDTH-1 : DATA_WIDTH]),
    .rresp_s_inf(rresp_s_inf[DRAM_NUMBER * 2 -1 : 2]),
    .rlast_s_inf(rlast_s_inf[1]),
    .rvalid_s_inf(rvalid_s_inf[1]),
    // master
    .rready_s_inf(rready_s_inf[1])
);

pseudo_DRAM_data pDATA_DRAM(
  	.clk(clk),
  	.rst_n(rst_n),
	/* slave interface */
    // axi write address channel 
    // src master
    .awid_s_inf(awid_s_inf),
    .awaddr_s_inf(awaddr_s_inf),
    .awsize_s_inf(awsize_s_inf),
    .awburst_s_inf(awburst_s_inf),
    .awlen_s_inf(awlen_s_inf),
    .awvalid_s_inf(awvalid_s_inf),
    // src slave
    .awready_s_inf(awready_s_inf),
    
    // axi write data channel 
    // src master
    .wdata_s_inf(wdata_s_inf),
    .wlast_s_inf(wlast_s_inf),
    .wvalid_s_inf(wvalid_s_inf),
    // src slave
    .wready_s_inf(wready_s_inf),
   
    // axi write response channel 
    // src slave
    .bid_s_inf(bid_s_inf),
    .bresp_s_inf(bresp_s_inf),
    .bvalid_s_inf(bvalid_s_inf),
    // src master 
    .bready_s_inf(bready_s_inf),
    // -----------------------------
   
    // axi read address channel 
    // src master
    .arid_s_inf(arid_s_inf[ID_WIDTH-1 : 0]),
    .araddr_s_inf(araddr_s_inf[ADDR_WIDTH-1 : 0]),
    .arlen_s_inf(arlen_s_inf[7-1 : 0]),
    .arsize_s_inf(arsize_s_inf[3-1 : 0]),
    .arburst_s_inf(arburst_s_inf[2-1 : 0]),
    .arvalid_s_inf(arvalid_s_inf[0]),
    // src slave
    .arready_s_inf(arready_s_inf[0]),
    // -----------------------------
   
    // axi read data channel 
    // slave
    .rid_s_inf(rid_s_inf[ID_WIDTH-1 : 0]),
    .rdata_s_inf(rdata_s_inf[DATA_WIDTH-1 : 0]),
    .rresp_s_inf(rresp_s_inf[2-1 : 0]),
    .rlast_s_inf(rlast_s_inf[0]),
    .rvalid_s_inf(rvalid_s_inf[0]),
    // master
    .rready_s_inf(rready_s_inf[0])
);

//---------------------------------------------------------------------
//   CLOCK          
//---------------------------------------------------------------------

initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

////////////////////////////////////////////////
// Initial Block
////////////////////////////////////////////////

initial begin
  // read DRAM
  read_data_DRAM;
  read_instr_DRAM;
  
  check_reset;

  total_latency = 0;

  for(i = 0; i < 16; i = i+1)begin
		gregfile[i] = 0;
	end

  pc = 0;
  last_dram_addr = 0;
  inst_count = 0;

  while(1'b1) begin
    pat_latency = 0;

    for(inst10_count = 0; inst10_count < 10; inst10_count = inst10_count + 1) begin
      lat = 1;
      execute_inst;
      while(IO_stall !== 0) begin
        lat = lat + 1;
        if(lat == `MAX_WAIT_READY_CYCLE) begin
          $display("***************************************************************");
					$display("                       CPU_FAIL                              ");
					$display("         The execution latency are over %d cycles.        ", `MAX_WAIT_READY_CYCLE);
					$display("***************************************************************");	
          $finish;
        end
        @(negedge clk);
      end

      checkans_regfile;
      pat_latency = pat_latency + lat;
      if(inst10_count == 9) begin
        checkans_dram;
      end

      $display("\033[32mInstrucion count: %6d PASS [PC = 0x%4h] latency= %4d\033[1;0m", inst_count, (pc - 1) * 2 + 16'h1000, lat);
      inst_count = inst_count + 1;
	  if(pc == 4096) begin
		checkans_dram;
		break;
      end

      @(negedge clk);
    end

    total_latency = total_latency + pat_latency;
	if(pc === 4096) begin
		$display("Total latency: %d", total_latency);
		$finish;
	end
  end
  $finish;
end


////////////////////////////////////////////////
// Task
////////////////////////////////////////////////
task read_data_DRAM; begin
	data_file_ptr = $fopen("../00_TESTBED/DRAM/DRAM_data.dat","r");
	for(i = 0; i < 4096; i = i+1)begin
		re = $fscanf(data_file_ptr, " @%x\n", buffer_addr);
		re = $fscanf(data_file_ptr, " %x %x\n", gdata_DRAM[i][7 : 0], gdata_DRAM[i][15 : 8]);
	end
	$fclose(data_file_ptr);
end endtask

task read_instr_DRAM; begin
	instr_file_ptr = $fopen("../00_TESTBED/DRAM/DRAM_inst.dat","r");
	for(i = 0; i < 4096; i = i+1)begin
		re = $fscanf(instr_file_ptr, " @%x\n", buffer_addr);
		re = $fscanf(instr_file_ptr, " %x %x\n", ginstr_DRAM[i][7 : 0], ginstr_DRAM[i][15 : 8]);
	end
	$fclose(instr_file_ptr);
end endtask


task check_reset; begin
  rst_n = 1'b1;
  force clk = 0;
  #(5*CYCLE);
  rst_n = 1'b0;
  #(5*CYCLE);
  rst_n = 1'b1;
  #(5*CYCLE);

  if (My_CPU.core_r0 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 0, My_CPU.core_r0);
    $finish;
  end

  if (My_CPU.core_r1 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 1, My_CPU.core_r1);
    $finish;
  end

  if (My_CPU.core_r2 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 2, My_CPU.core_r2);
    $finish;
  end

  if (My_CPU.core_r3 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 3, My_CPU.core_r3);
    $finish;
  end

  if (My_CPU.core_r4 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 4, My_CPU.core_r4);
    $finish;
  end

  if (My_CPU.core_r5 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 5, My_CPU.core_r5);
    $finish;
  end

  if (My_CPU.core_r6 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 6, My_CPU.core_r6);
    $finish;
  end

  if (My_CPU.core_r7 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 7, My_CPU.core_r7);
    $finish;
  end

  if (My_CPU.core_r8 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 8, My_CPU.core_r8);
    $finish;
  end

  if (My_CPU.core_r9 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 9, My_CPU.core_r9);
    $finish;
  end

  if (My_CPU.core_r10 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 10, My_CPU.core_r10);
    $finish;
  end

  if (My_CPU.core_r11 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 11, My_CPU.core_r11);
    $finish;
  end

  if (My_CPU.core_r12 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 12, My_CPU.core_r12);
    $finish;
  end

  if (My_CPU.core_r13 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 13, My_CPU.core_r13);
    $finish;
  end

  if (My_CPU.core_r14 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 14, My_CPU.core_r14);
    $finish;
  end

  if (My_CPU.core_r15 !== 16'd0) begin
    $display("[FAIL] Register r%0d not cleared after reset! Value = %h", 15, My_CPU.core_r15);
    $finish;
  end

  if(IO_stall !== 1'b1) begin
    $display("[FAIL] IO_stall not be high after reset!");
    $finish;
  end

  release clk;
end endtask

task execute_inst;begin
	//decode
	instruction = ginstr_DRAM[pc];
	rs = instruction[12 : 9];
	rt = instruction[ 8 : 5];
	rd = instruction[ 4 : 1];
	immediate = instruction[4 : 0];
	address = instruction[12 : 0];
	
	old_rs = gregfile[rs];
	old_rt = gregfile[rt];
	old_rd = gregfile[rd];
	if(instruction[15:13] == 3'b000 || instruction[15:13] == 3'b001)begin
		instruction_type = 1;
		//R-type

		case({instruction[15:13], instruction[0]})
			4'b000_1:begin
				if((gregfile[rs]+gregfile[rt] > 32767) || (gregfile[rs]+gregfile[rt] < -32768))begin
					$display("Pattern overflowed!! PC: %d", pc);
					$display("Instruction: add r%d r%d r%d", rs, rt, rd);
					$display("r%d = %d", rs, gregfile[rs]);
					$display("r%d = %d", rt, gregfile[rt]);
					$display("Overflowed answer: (r%d) = %d", rd, gregfile[rs]+gregfile[rt]);
					# (2);
					$finish;
				end
				gregfile[rd] = gregfile[rs] + gregfile[rt];
				pc = pc + 1;
			end
			4'b000_0:begin
				if((gregfile[rs]+gregfile[rt] > 32767) || (gregfile[rs]+gregfile[rt] < -32768))begin
					$display("Pattern overflowed!! PC: %d", pc);
					$display("Instruction: sub r%d r%d r%d", rs, rt, rd);
					$display("r%d = %d", rs, gregfile[rs]);
					$display("r%d = %d", rt, gregfile[rt]);
					$display("Overflowed answer: (r%d) = %d", rd, gregfile[rs]-gregfile[rt]);
					# (2);
					$finish;
				end
				gregfile[rd] = gregfile[rs] - gregfile[rt];

				pc = pc + 1;
			end 
			4'b001_1:begin
				if(gregfile[rs] < gregfile[rt]) gregfile[rd] = 1;
				else gregfile[rd] = 0;
				

				pc = pc + 1;
			end
			4'b001_0:begin
				//check pattern would never overflow...
				if((gregfile[rs]*gregfile[rt] > 32767) || (gregfile[rs]*gregfile[rt] <-32768))begin
					$display("Pattern overflowed!! PC: %d", pc);
					$display("Instruction: mul r%d r%d r%d", rs, rt, rd);
					$display("r%d = %d", rs, gregfile[rs]);
					$display("r%d = %d", rt, gregfile[rt]);
					# (2);
					$finish;
				end
				gregfile[rd] = gregfile[rs]*gregfile[rt];
				pc = pc + 1;
			end 
		endcase

	end else if(instruction[15:13] == 3'b011 || instruction[15:13] == 3'b010 || instruction[15:13] == 3'b101)begin
		//I-type
		case(instruction[15:13])
			3'b011:begin
				instruction_type = 2;
				fut_dram_addr =  (gregfile[rs]+immediate)*2 + 4096;
				if((gregfile[rs]+immediate > 4095) || (gregfile[rs]+immediate < 0))begin
					$display("Pattern overflowed!! PC: %d", pc);
					$display("Instruction: lw r%d r%d %d", rs, rt, immediate);
					$display("Invalid fetching: %d(@%04x)",gregfile[rs]+immediate, fut_dram_addr);
					# (2);
					$finish;
				end
				if(fut_dram_addr > last_dram_addr && last_dram_addr !== 0)begin
					if(fut_dram_addr - last_dram_addr > 64)begin
						$display("Pattern violate data dependency prediction!");
						$display("[PC-%04x] lw r%d r%d %d",pc, rs, rt, immediate);
						$display("Last    fetching: (@%04x)",last_dram_addr);
						$display("Invalid fetching: %d(@%04x)",gregfile[rs]+immediate, fut_dram_addr);
						# (2);
						$finish;
					end
				end else if(fut_dram_addr < last_dram_addr && last_dram_addr !== 0)begin
					if(last_dram_addr - fut_dram_addr > 62)begin
						$display("Pattern violate data dependency prediction!");
						$display("[PC-%04x] lw r%d r%d %d",pc, rs, rt, immediate);
						$display("Last    fetching: (@%04x)",last_dram_addr);
						$display("Invalid fetching: %d(@%04x)",gregfile[rs]+immediate, fut_dram_addr);
						# (2);
						$finish;
					end
				end
				gregfile[rt] = gdata_DRAM[gregfile[rs]+immediate];
				last_dram_addr = fut_dram_addr;
				pc = pc + 1;
			end 
			3'b010:begin
				instruction_type = 2;
				fut_dram_addr =  (gregfile[rs]+immediate)*2 + 4096;
				if((gregfile[rs]+immediate > 4095) || (gregfile[rs]+immediate < 0))begin
					$display("Pattern overflowed!! PC: %d", pc);
					$display("Instruction: sw r%d r%d %d", rs, rt, immediate);
					$display("r%d = %d", rs, gregfile[rs]);
					$display("r%d = %d", rt, gregfile[rt]);
					$display("Invalid storing: %d(@%04x)",gregfile[rs]+immediate, fut_dram_addr);
					# (2);
					$finish;
				end
				if(fut_dram_addr > last_dram_addr)begin
					if(fut_dram_addr - last_dram_addr > 64 && last_dram_addr !== 0)begin
						$display("Pattern violate data dependency prediction!");
						$display("[PC-%04x] sw r%d r%d %d",pc, rs, rt, immediate);
						$display("Last    storing: (@%04x)",last_dram_addr);
						$display("Invalid storing: %d(@%04x)",gregfile[rs]+immediate, fut_dram_addr);
						# (2);
						$finish;
					end
				end else if(fut_dram_addr < last_dram_addr && last_dram_addr !== 0)begin
					if(last_dram_addr - fut_dram_addr > 62)begin
						$display("Pattern violate data dependency prediction!");
						$display("[PC-%04x] sw r%d r%d %d",pc, rs, rt, immediate);
						$display("Last    storing: (@%04x)",last_dram_addr);
						$display("Invalid storing: %d(@%04x)",gregfile[rs]+immediate, fut_dram_addr);
						# (2);
						$finish;
					end
				end
				old_ddram = gdata_DRAM[gregfile[rs]+immediate];
				gdata_DRAM[gregfile[rs]+immediate] = gregfile[rt];
				last_dram_addr = fut_dram_addr;
				pc = pc + 1;
			end 
			3'b101:begin
				instruction_type = 3;
				if(($signed(pc)+1+immediate) < 0 || ($signed(pc)+1+immediate) > 4096)begin
						$display("Branching to the outer-space!");
						$display("[PC-%04x] beq r%d r%d %d",pc, rs, rt, immediate);
						$display("Branching to: %d(@%04x)",($signed(pc)+1+immediate), ($signed(pc)+1+immediate)*2+16'h1000);
						# (2);
						$finish;
				end
				if(gregfile[rs] == gregfile[rt])begin
					pc = ($signed(pc)+1+immediate);
				end else begin
					pc = pc+1;
				end
				
			end
		endcase
	end else if(instruction[15:13] == 3'b100)begin
		instruction_type = 4;
		if(address > 16'h1FFF || address < 16'h1000 || (address[0]!==0))begin
			$display("Jump Instruction range invalid !");
			$display("%0s[PC-%04x]%0s j %d(@%04x)",purple_txtpf,pc,reset_color,(address-16'h1000)/2,address);
			# (2);
			$finish;
		end
		if(((address-16'h1000)/2) > pc)begin
			if((((address-16'h1000)/2) - pc) > 32)begin
				$display("Jump to the outer-space!");
				$display("[PC-%04x] j %x",pc, address);
				$display("Current PC: %d(@%04x)", pc, (pc*2 + 16'h1000));
				# (2);
				$finish;
			end
		end else if(((address-16'h1000)/2) < pc)begin
			if((pc - ((address-16'h1000)/2)) > 31)begin
				$display("Jump to the outer-space!");
				$display("[PC-%04x] j %x",pc, address);
				$display("Current PC: %d(@%04x)", pc, (pc*2 + 16'h1000));
				# (2);
				$finish;
			end
		end
		pc = (address-16'h1000)/2;

	end else begin // parsed incorrect istruction!
		$display("%0s[ERROR]%0s Incorrect instruction @ print_instr!!",red_txtpf, reset_color);
		# (2);
		$finish;
	end
end endtask



task checkans_regfile; begin
		if( My_CPU.core_r0  !== gregfile[ 0] ||
			My_CPU.core_r1  !== gregfile[ 1] ||
			My_CPU.core_r2  !== gregfile[ 2] ||
			My_CPU.core_r3  !== gregfile[ 3] ||
			My_CPU.core_r4  !== gregfile[ 4] ||
			My_CPU.core_r5  !== gregfile[ 5] ||
			My_CPU.core_r6  !== gregfile[ 6] ||
			My_CPU.core_r7  !== gregfile[ 7] ||
			My_CPU.core_r8  !== gregfile[ 8] ||
			My_CPU.core_r9  !== gregfile[ 9] ||
			My_CPU.core_r10 !== gregfile[10] ||
			My_CPU.core_r11 !== gregfile[11] ||
			My_CPU.core_r12 !== gregfile[12] ||
			My_CPU.core_r13 !== gregfile[13] ||
			My_CPU.core_r14 !== gregfile[14] ||
			My_CPU.core_r15 !== gregfile[15]	)begin
			$display("*********************************************************************************************");
			$display("*                                      %0sCPU_FAIL%0s                                             *", red_txtpf, reset_color);
			$display("*                                %0sREGISTER FILES ERROR%0s                                       *", white_txtpf, reset_color);
			$display("*********************************************************************************************");

			if(My_CPU.core_r0  !== gregfile[ 0])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,0,My_CPU.core_r0,My_CPU.core_r0,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",0,My_CPU.core_r0,My_CPU.core_r0);
			end
			$write("\t");
			if(My_CPU.core_r1  !== gregfile[ 1])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,1,My_CPU.core_r1,My_CPU.core_r1,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",1,My_CPU.core_r1,My_CPU.core_r1);
			end
			$write("\t");
			if(My_CPU.core_r2  !== gregfile[ 2])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,2,My_CPU.core_r2,My_CPU.core_r2,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",2,My_CPU.core_r2,My_CPU.core_r2);
			end
			$write("\t");
			if(My_CPU.core_r3  !== gregfile[ 3])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,3,My_CPU.core_r3,My_CPU.core_r3,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",3,My_CPU.core_r3,My_CPU.core_r3);
			end
			$display("");

			if(My_CPU.core_r4  !== gregfile[ 4])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,4,My_CPU.core_r4,My_CPU.core_r4,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",4,My_CPU.core_r4,My_CPU.core_r4);
			end
			$write("\t");
			if(My_CPU.core_r5  !== gregfile[ 5])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,5,My_CPU.core_r5,My_CPU.core_r5,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",5,My_CPU.core_r5,My_CPU.core_r5);
			end
			$write("\t");
			if(My_CPU.core_r6  !== gregfile[ 6])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,6,My_CPU.core_r6,My_CPU.core_r6,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",6,My_CPU.core_r6,My_CPU.core_r6);
			end
			$write("\t");
			if(My_CPU.core_r7  !== gregfile[ 7])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,7,My_CPU.core_r7,My_CPU.core_r7,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",7,My_CPU.core_r7,My_CPU.core_r7);
			end
			$display("");

			if(My_CPU.core_r8  !== gregfile[ 8])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,8,My_CPU.core_r8,My_CPU.core_r8,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",8,My_CPU.core_r8,My_CPU.core_r8);
			end
			$write("\t");
			if(My_CPU.core_r9  !== gregfile[ 9])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,9,My_CPU.core_r9,My_CPU.core_r9,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",9,My_CPU.core_r9,My_CPU.core_r9);
			end
			$write("\t");
			if(My_CPU.core_r10  !== gregfile[10])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,10,My_CPU.core_r10,My_CPU.core_r10,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",10,My_CPU.core_r10,My_CPU.core_r10);
			end
			$write("\t");
			if(My_CPU.core_r11  !== gregfile[11])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,11,My_CPU.core_r11,My_CPU.core_r11,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",11,My_CPU.core_r11,My_CPU.core_r11);
			end
			$display("");

			if(My_CPU.core_r12  !== gregfile[12])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,12,My_CPU.core_r12,My_CPU.core_r12,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",12,My_CPU.core_r12,My_CPU.core_r12);
			end
			$write("\t");
			if(My_CPU.core_r13  !== gregfile[13])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,13,My_CPU.core_r13,My_CPU.core_r13,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",13,My_CPU.core_r13,My_CPU.core_r13);
			end
			$write("\t");
			if(My_CPU.core_r14  !== gregfile[14])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,14,My_CPU.core_r14,My_CPU.core_r14,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",14,My_CPU.core_r14,My_CPU.core_r14);
			end
			$write("\t");
			if(My_CPU.core_r15  !== gregfile[15])begin
				$write("%0sReg %2d: %d(%04x)%0s",red_txtpf,15,My_CPU.core_r15,My_CPU.core_r15,reset_color);
			end else begin
				$write("Reg %2d: %d(%04x)",15,My_CPU.core_r15,My_CPU.core_r15);
			end
			$display("");

			$finish;
		end 
end endtask

task checkans_dram; begin
	ddram_error = 0;
	for(ddx = 0; ddx < 4096; ddx = ddx+1)begin
		if($signed({u_PATTERN.pDATA_DRAM.DRAM_r[ddx*2+1+4096], u_PATTERN.pDATA_DRAM.DRAM_r[ddx*2+4096]}) !== gdata_DRAM[ddx])begin
			ddram_error = ddram_error + 1;
			if(ddram_error == 1)begin
				$display("*********************************************************************************************");
				$display("*                                      %0sCPU_FAIL%0s                                             *", red_txtpf, reset_color);
				$display("*                                   %0sDATA DRAM ERROR%0s                                         *", white_txtpf, reset_color);
				$display("*********************************************************************************************");
			end
			$display("@%x(%04x)%0s %d(%04x) %0s\t %0s %d(%04x) %0s",(ddx*2 + 16'h1000), ddx,green_txtpf, gdata_DRAM[ddx], gdata_DRAM[ddx], reset_color
																	, red_txtpf, $signed({u_PATTERN.pDATA_DRAM.DRAM_r[ddx*2+1+4096], u_PATTERN.pDATA_DRAM.DRAM_r[ddx*2+4096]}),
																	$signed({u_PATTERN.pDATA_DRAM.DRAM_r[ddx*2+1+4096], u_PATTERN.pDATA_DRAM.DRAM_r[ddx*2+4096]}), reset_color);

		end
	end
	if(ddram_error != 0)begin
	#(2);
	$finish;
	end
end endtask



endmodule