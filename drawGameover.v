module drawGameover(
    // Inputs
    clk,						
    resetn,
    enable,
    
    // Outputs
    col_out,
    x_out,
    y_out,
    completed						
);

    // Inputs
	input clk;				//	50 MHz
	input resetn, enable;

	// Outputs
    output [2:0]    col_out;
    output [7:0]    x_out;
    output [6:0]    y_out;
    output          completed;

    wire done_drawing;
    wire draw_enable;

    assign completed = done_drawing;
    
    // Instansiate datapath
	datapath d0(
		.clk(clk),
        .resetn(resetn),
        .draw_enable(draw_enable),
        .x_out(x_out),
        .y_out(y_out),
        .col_out(col_out),
        .done_drawing(done_drawing)
	);

    // Instansiate FSM control
    control c0(
		.clk(clk),
		.resetn(resetn),
		.enable(enable),
        .done_drawing(done_drawing)
		.draw_enable(draw_enable)
	);
    
endmodule


module control(
    // Inputs
	clk,
	resetn,
    enable,
    done_drawing,
	
    // Outputs
    draw_enable
);

    // Inputs
	input clk;				
	input resetn, enable;
    input done_drawing;

	// Outputs
    output reg begin_drawing;
    output reg draw_enable;

	// State registers
	reg [1:0] current_state, next_state;


	localparam  S_HOLD_ENABLE   = 2'd0,
                S_ENABLE_WAIT   = 2'd1,
                S_DRAW  		= 2'd2,
				
	// Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_HOLD_ENABLE: next_state = enable ? S_ENABLE_WAIT : S_HOLD_ENABLE; // Loop in current state until enable is high
                S_ENABLE_WAIT: next_state = enable ? S_ENABLE_WAIT : S_DRAW; // Loop in current state until enable goes low
                S_DRAW: next_state = done_drawing ? S_HOLD_ENABLE : S_DRAW;
            default:     next_state = S_HOLD_ENABLE;
        endcase
    end // state_table

	// Control signals
    always @(*)
    begin: enable_signals
        draw_enable = 1'b0;

        case (current_state)
			S_DRAW: begin 
				draw_enable = 1'b1;
            end
        endcase
    end

	// current_state registers
    always@(posedge clock)
    begin: state_FFs
        if(!resetn)
            current_state <= S_HOLD_ENABLE;
        else
            current_state <= next_state;
    end

endmodule


module datapath(
	clk,
	resetn,
	draw_enable;
	x_out,
	y_out,
	col_out,
    done_drawing
);

    // Inputs
	input clk;
	input resetn, enable;

	// Outputs
    output reg [2:0]    col_out;
    output reg [7:0]    x_out;
    output reg [6:0]    y_out;
    output reg          done_drawing;

	// Counter register
	reg [14:0] counter;

	// Registers x, y, and col
    always @ (posedge clock) begin
        if (!resetn || done_drawing) begin
            x_out 	<= 8'd0;
            y_out 	<= 7'd0;
			col_out <= 3'd0;
        end
        else begin
            x_out 	<= x_out + counter[7:0];
			y_out 	<= y_out + counter[14:8];
			col_out <= 3'b111;
        end
    end

	// Counter to increment pixel position
	always @ (posedge clock) begin
        if (!resetn) begin
            done_drawing <= 0;
            counter <= 15'd0;
        end
        if (counter == 15'd20480) begin
            counter <= 15'd0;
            done_drawing <= 1;
        end
        else begin
            done_drawing <= 0;
			counter <= counter + 1;
        end
    end
endmodule