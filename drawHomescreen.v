module drawHomescreen(
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
	input clk;
	input resetn, enable;

	// Outputs
    output reg [2:0]    col_out;
    output reg [7:0]    x_out;
    output reg [6:0]    y_out;
    output reg          completed;

	// Counter register
	reg [14:0] counter;

    // Wires
    wire [2:0] col;

	// Registers x, y, and col
    always @ (posedge clk) begin
        if (!resetn || !enable) begin
            x_out 	<= 8'd0;
            y_out 	<= 7'd0;
			col_out <= 3'd0;
        end
        else begin
            x_out 	<= x_out + counter[7:0];
			y_out 	<= y_out + counter[14:8];
			col_out <= col;
        end
    end

	// Counter to increment pixel position
	always @ (posedge clk) begin
        if (!resetn || !enable) begin
            completed <= 0;
            counter <= 15'd0;
        end
        else begin
            if (counter < 15'd32767) begin
                counter <= counter + 1;
            end
            else begin
                counter <= 15'd0;
                completed <= 1;
            end
        end
    end

    // Image Memory
    homescreen h0(
        .address(counter),
        .clock(clk),
        .q(col)
    );

endmodule