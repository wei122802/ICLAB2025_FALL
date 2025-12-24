module Packet_allocator_opt (
    input  [2:0] packet_in,
    input  [2:0] ch0_used, ch1_used, ch2_used,
    input  [2:0] ch0_capacity, ch1_capacity, ch2_capacity,
    input  [2:0] capacity_full,
    input  [1:0] current_pivot,
    input        pivot_initialized,

    output reg  [1:0] allocation,
    output reg  [2:0] capacity_full_next,
    output reg  [2:0] ch0_used_next,
    output reg  [2:0] ch1_used_next,
    output reg  [2:0] ch2_used_next,
    output reg  [1:0] next_pivot,
    output reg        pivot_init_next
);

    wire req_valid = packet_in[2];
    wire [1:0] prefer_ch = packet_in[1:0];

    wire ch0_not_full = (ch0_used < ch0_capacity);
    wire ch1_not_full = (ch1_used < ch1_capacity);
    wire ch2_not_full = (ch2_used < ch2_capacity);

    wire [2:0] avail = {ch2_not_full, ch1_not_full, ch0_not_full};

    // base pivot
    wire [1:0] start = pivot_initialized ? current_pivot : prefer_ch;

    // small rotate-priority encoder combinational:
    function [1:0] pick_alloc;
        input [1:0] s;
        input [2:0] a; // [2]=ch2, [1]=ch1, [0]=ch0
        begin
            pick_alloc = 2'b11;
            if (a[(s)%3]) pick_alloc = s;
            else if (a[(s+1)%3]) pick_alloc = (s==2) ? 2'b00 : s + 1'b1;
            else if (a[(s+2)%3]) begin
                case (s)
                    2'b00: pick_alloc = 2'b10;
                    2'b01: pick_alloc = 2'b00;
                    2'b10: pick_alloc = 2'b01;
                endcase
            end
        end
    endfunction

    wire [1:0] fallback_alloc = pick_alloc(start, avail);

    always @(*) begin
        // defaults
        allocation = 2'b11;
        ch0_used_next = ch0_used;
        ch1_used_next = ch1_used;
        ch2_used_next = ch2_used;
        capacity_full_next = capacity_full;
        next_pivot = current_pivot;
        pivot_init_next = pivot_initialized;

        if (!req_valid || prefer_ch > 2'b10) begin
            allocation = 2'b11;
        end else begin
            // prefer first
            case (prefer_ch)
                2'b00: if (ch0_not_full) allocation = 2'b00; else allocation = fallback_alloc;
                2'b01: if (ch1_not_full) allocation = 2'b01; else allocation = fallback_alloc;
                2'b10: if (ch2_not_full) allocation = 2'b10; else allocation = fallback_alloc;
                default: allocation = 2'b11;
            endcase

            // update counts
            case (allocation)
                2'b00: ch0_used_next = ch0_used + 1;
                2'b01: ch1_used_next = ch1_used + 1;
                2'b10: ch2_used_next = ch2_used + 1;
                default: ;
            endcase

            // update capacity full bits only for allocated channel
            case (allocation)
                2'b00: capacity_full_next[0] = ((ch0_used + 1) >= ch0_capacity);
                2'b01: capacity_full_next[1] = ((ch1_used + 1) >= ch1_capacity);
                2'b10: capacity_full_next[2] = ((ch2_used + 1) >= ch2_capacity);
                default: ;
            endcase

            // pivot updates (combinational)
            pivot_init_next = pivot_initialized | (allocation != 2'b11);
            if (allocation != 2'b11) begin
                if (!pivot_initialized) begin
                    next_pivot = (start == 2) ? 2'b00 : start + 1'b1;
                end else begin
                    next_pivot = (current_pivot == 2) ? 2'b00 : current_pivot + 1'b1;
                end
            end else begin
                // failed allocation
                if (!pivot_initialized) begin
                    case (start)
                        2'b00: next_pivot = 2'b10;
                        2'b01: next_pivot = 2'b00;
                        2'b10: next_pivot = 2'b01;
                        default: next_pivot = 2'b00;
                    endcase
                end else begin
                    case (current_pivot)
                        2'b00: next_pivot = 2'b10;
                        2'b01: next_pivot = 2'b00;
                        2'b10: next_pivot = 2'b01;
                        default: next_pivot = 2'b00;
                    endcase
                end
            end
        end
    end
endmodule
