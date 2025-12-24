/**************************************************************************/
// MODULE: CONVEX
// FILE NAME: CONVEX.v
// DESCRIPTION: Dynamic Convex Hull Construction
/**************************************************************************/

module CONVEX (
    // Input
    rst_n,
    clk,
    in_valid,
    pt_num,
    in_x,
    in_y,
    // Output
    out_valid,
    out_x,
    out_y,
    drop_num
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input           rst_n;
input           clk;
input           in_valid;
input   [8:0]   pt_num;
input   [9:0]   in_x;
input   [9:0]   in_y;

output reg      out_valid;
output reg [9:0] out_x;
output reg [9:0] out_y;
output reg [6:0] drop_num;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
parameter IDLE = 3'b000;
parameter INPUT = 3'b001;
parameter CALC = 3'b010;
parameter OUTPUT = 3'b011;
parameter DONE = 3'b100;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [2:0] current_state, next_state;
reg [8:0] total_points;
reg [8:0] current_point_idx;
reg [9:0] new_x, new_y;
reg [6:0] hull_size;

// Hull storage
reg [9:0] hull_x [0:127];
reg [9:0] hull_y [0:127];

// Drop points storage
reg [9:0] drop_x [0:127];
reg [9:0] drop_y [0:127];
reg [6:0] drop_count;
reg [6:0] output_idx;

// Calculation registers
reg signed [23:0] cross_product;
reg [6:0] left_idx, right_idx;
reg [6:0] check_idx, next_idx;
reg found_negative;
reg [6:0] neg_start, neg_end;
reg [1:0] zero_count;
reg [6:0] zero_edge_start [0:1];
reg [6:0] zero_edge_end [0:1];
reg [1:0] zero_idx;
reg [6:0] intersection_1, intersection_2;

// State machine control
reg calc_done;
reg [3:0] calc_step;

//---------------------------------------------------------------------
//   CROSS PRODUCT FUNCTION
//---------------------------------------------------------------------
function signed [23:0] cross_product_func;
    input [9:0] ax, ay, bx, by, cx, cy;
    reg signed [11:0] ux, uy, vx, vy;
    reg signed [23:0] term1, term2;
begin
    ux = bx - ax;
    uy = by - ay;
    vx = cx - ax;
    vy = cy - ay;
    term1 = ux * vy;
    term2 = uy * vx;
    cross_product_func = term1 - term2;
end
endfunction

//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always @(*) begin
    case (current_state)
        IDLE: begin
            if (in_valid)
                next_state = INPUT;
            else
                next_state = IDLE;
        end
        INPUT: begin
            if (!in_valid)  // Wait until in_valid goes low
                next_state = CALC;
            else
                next_state = INPUT;
        end
        CALC: begin
            if (calc_done)
                next_state = OUTPUT;
            else
                next_state = CALC;
        end
        OUTPUT: begin
            if (output_idx >= drop_count)
                next_state = DONE;
            else
                next_state = OUTPUT;
        end
        DONE: begin
            if (current_point_idx >= total_points)
                next_state = IDLE;
            else if (!in_valid)  // Make sure in_valid is low before going to next input
                next_state = IDLE;  // Wait for next in_valid
            else
                next_state = DONE;
        end
        default: next_state = IDLE;
    endcase
end

//---------------------------------------------------------------------
//   INPUT LOGIC
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        total_points <= 0;
        current_point_idx <= 0;
        new_x <= 0;
        new_y <= 0;
    end
    else if (current_state == IDLE && in_valid) begin
        total_points <= pt_num;
        current_point_idx <= 1;
        new_x <= in_x;
        new_y <= in_y;
    end
    else if (current_state == IDLE && next_state == INPUT && in_valid) begin
        // Capture input when transitioning to INPUT state
        if (current_point_idx == 0) begin
            total_points <= pt_num;
        end
        current_point_idx <= current_point_idx + 1;
        new_x <= in_x;
        new_y <= in_y;
    end
end

//---------------------------------------------------------------------
//   HULL CALCULATION
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        hull_size <= 0;
        calc_done <= 0;
        calc_step <= 0;
        drop_count <= 0;
        check_idx <= 0;
        left_idx <= 127;
        right_idx <= 127;
        found_negative <= 0;
        zero_count <= 0;
        zero_idx <= 0;
        neg_start <= 0;
        neg_end <= 0;
        intersection_1 <= 127;
        intersection_2 <= 127;
        
        // Initialize arrays
        for (integer i = 0; i < 128; i = i + 1) begin
            hull_x[i] <= 0;
            hull_y[i] <= 0;
            drop_x[i] <= 0;
            drop_y[i] <= 0;
        end
    end
    else if (current_state == CALC) begin
        case (calc_step)
            0: begin // Initialize for new point
                calc_done <= 0;
                drop_count <= 0;
                check_idx <= 0;
                left_idx <= 127;
                right_idx <= 127;
                found_negative <= 0;
                zero_count <= 0;
                zero_idx <= 0;
                
                if (current_point_idx <= 3) begin
                    // First three points - just add to hull
                    hull_x[hull_size] <= new_x;
                    hull_y[hull_size] <= new_y;
                    hull_size <= hull_size + 1;
                    
                    if (current_point_idx == 3) begin
                        // Check orientation and fix if needed
                        cross_product <= cross_product_func(
                            hull_x[0], hull_y[0],
                            hull_x[1], hull_y[1],
                            hull_x[2], hull_y[2]
                        );
                        calc_step <= 10; // Special step for triangle orientation
                    end
                    else begin
                        calc_done <= 1;
                        calc_step <= 0;
                    end
                end
                else begin
                    calc_step <= 1;
                end
            end
            
            1: begin // Check all edges for cross products
                if (check_idx < hull_size) begin
                    next_idx <= (check_idx + 1) % hull_size;
                    cross_product <= cross_product_func(
                        hull_x[check_idx], hull_y[check_idx],
                        hull_x[(check_idx + 1) % hull_size], hull_y[(check_idx + 1) % hull_size],
                        new_x, new_y
                    );
                    calc_step <= 2;
                end
                else begin
                    calc_step <= 3; // Finished checking all edges
                end
            end
            
            2: begin // Process cross product result
                if (cross_product == 0) begin
                    // Collinear case
                    zero_edge_start[zero_idx] <= check_idx;
                    zero_edge_end[zero_idx] <= next_idx;
                    zero_count <= zero_count + 1;
                    if (zero_idx == 0)
                        zero_idx <= 1;
                end
                else if (cross_product < 0) begin
                    // Negative cross product - point is outside
                    if (!found_negative) begin
                        found_negative <= 1;
                        neg_start <= check_idx;
                        neg_end <= next_idx;
                        left_idx <= check_idx;
                        right_idx <= next_idx;
                    end
                    else begin
                        right_idx <= next_idx;
                    end
                end
                
                check_idx <= check_idx + 1;
                calc_step <= 1; // Continue checking
            end
            
            3: begin // Determine what to do based on analysis
                if (!found_negative) begin
                    // Point is inside - drop it
                    drop_x[0] <= new_x;
                    drop_y[0] <= new_y;
                    drop_count <= 1;
                    calc_done <= 1;
                    calc_step <= 0;
                end
                else begin
                    // Point is outside - need to update hull
                    if (zero_count == 1) begin
                        calc_step <= 4; // Handle single collinear edge
                    end
                    else if (zero_count == 2) begin
                        calc_step <= 5; // Handle two collinear edges
                    end
                    else begin
                        calc_step <= 6; // General case
                    end
                end
            end
            
            4: begin // Handle single collinear edge case
                // Find intersection point and replace
                if (zero_edge_start[0] == left_idx || zero_edge_start[0] == right_idx) begin
                    intersection_1 <= zero_edge_start[0];
                end
                else if (zero_edge_end[0] == left_idx || zero_edge_end[0] == right_idx) begin
                    intersection_1 <= zero_edge_end[0];
                end
                calc_step <= 7; // Update hull
            end
            
            5: begin // Handle two collinear edges case
                // Find both intersection points
                if (zero_edge_start[0] == left_idx || zero_edge_start[0] == right_idx) begin
                    intersection_1 <= zero_edge_start[0];
                end
                else if (zero_edge_end[0] == left_idx || zero_edge_end[0] == right_idx) begin
                    intersection_1 <= zero_edge_end[0];
                end
                
                if (zero_edge_start[1] == left_idx || zero_edge_start[1] == right_idx) begin
                    intersection_2 <= zero_edge_start[1];
                end
                else if (zero_edge_end[1] == left_idx || zero_edge_end[1] == right_idx) begin
                    intersection_2 <= zero_edge_end[1];
                end
                calc_step <= 8; // Update hull for two intersections
            end
            
            6: begin // General case - find range to drop
                calc_step <= 9; // Update hull general case
            end
            
            7: begin // Update hull - single intersection
                // Drop the intersection point and insert new point
                drop_x[0] <= hull_x[intersection_1];
                drop_y[0] <= hull_y[intersection_1];
                drop_count <= 1;
                hull_x[intersection_1] <= new_x;
                hull_y[intersection_1] <= new_y;
                calc_done <= 1;
                calc_step <= 0;
            end
            
            8: begin // Update hull - two intersections
                // Drop both intersection points and insert new point
                drop_x[0] <= hull_x[intersection_1];
                drop_y[0] <= hull_y[intersection_1];
                drop_x[1] <= hull_x[intersection_2];
                drop_y[1] <= hull_y[intersection_2];
                drop_count <= 2;
                
                // Replace first intersection with new point, remove second
                hull_x[intersection_1] <= new_x;
                hull_y[intersection_1] <= new_y;
                
                // Shift hull to remove second intersection
                for (integer i = intersection_2; i < 126; i = i + 1) begin
                    hull_x[i] <= hull_x[i + 1];
                    hull_y[i] <= hull_y[i + 1];
                end
                hull_size <= hull_size - 1;
                calc_done <= 1;
                calc_step <= 0;
            end
            
            9: begin // Update hull - general case
                // This is the most complex case - drop points between left_idx and right_idx
                drop_count <= 0;
                check_idx <= (left_idx + 1) % hull_size;
                calc_step <= 11; // Start dropping points
            end
            
            10: begin // Fix triangle orientation if needed
                if (cross_product < 0) begin
                    // Swap points 1 and 2
                    hull_x[1] <= hull_x[2];
                    hull_y[1] <= hull_y[2];
                    hull_x[2] <= hull_x[1];
                    hull_y[2] <= hull_y[1];
                end
                calc_done <= 1;
                calc_step <= 0;
            end
            
            11: begin // Drop points in range
                if (check_idx != right_idx && drop_count < 127) begin
                    drop_x[drop_count] <= hull_x[check_idx];
                    drop_y[drop_count] <= hull_y[check_idx];
                    drop_count <= drop_count + 1;
                    check_idx <= (check_idx + 1) % hull_size;
                end
                else begin
                    calc_step <= 12; // Rebuild hull
                end
            end
            
            12: begin // Rebuild hull after dropping points
                // Insert new point at left_idx + 1
                // Shift remaining points
                for (integer i = hull_size; i > left_idx + 1; i = i - 1) begin
                    hull_x[i] <= hull_x[i - 1];
                    hull_y[i] <= hull_y[i - 1];
                end
                hull_x[left_idx + 1] <= new_x;
                hull_y[left_idx + 1] <= new_y;
                hull_size <= hull_size - drop_count + 1;
                calc_done <= 1;
                calc_step <= 0;
            end
            
            default: begin
                calc_done <= 1;
                calc_step <= 0;
            end
        endcase
    end
    else if (current_state != CALC) begin
        calc_step <= 0;
    end
end

//---------------------------------------------------------------------
//   OUTPUT LOGIC
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 0;
        out_x <= 0;
        out_y <= 0;
        drop_num <= 0;
        output_idx <= 0;
    end
    else if (current_state == OUTPUT) begin
        if (output_idx == 0) begin
            // Only assert out_valid when in_valid is definitely low
            if (!in_valid) begin
                out_valid <= 1;
                drop_num <= drop_count;
                if (drop_count > 0) begin
                    out_x <= drop_x[0];
                    out_y <= drop_y[0];
                    output_idx <= 1;
                end
                else begin
                    out_x <= 0;
                    out_y <= 0;
                    output_idx <= drop_count; // Move to end if no drops
                end
            end
        end
        else if (output_idx < drop_count) begin
            if (!in_valid) begin  // Ensure in_valid stays low
                out_x <= drop_x[output_idx];
                out_y <= drop_y[output_idx];
                output_idx <= output_idx + 1;
            end
        end
    end
    else begin
        out_valid <= 0;
        out_x <= 0;
        out_y <= 0;
        drop_num <= 0;
        if (current_state == IDLE || current_state == DONE)
            output_idx <= 0;
    end
end

endmodule