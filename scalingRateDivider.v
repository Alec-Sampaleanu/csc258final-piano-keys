// This rate divider outputs a 10ns pulse at a rate that begins at 60Hz,
// slowly speeding up depedning on SPEED_UP_FACTOR, up to a maximum 
// MAX_SPEED_FACTOR times faster
module scalingRateDivider(
    // Inputs
    clk,
    reset,

    // Outputs
    pulse
);

    // Localparams
    localparam MAX_COUNTER_VAL  = 20'd833333;
    localparam SCALING_FACTOR   = 5;
    localparam MAX_SPEED_FACTOR = 3;

    // Inputs
    input clk;
    input reset;

    // Outputs
    output reg pulse     = 0;

    // Registers
    reg [19:0] count_reg = 0;
    reg [19:0] max_count = MAX_COUNTER_VAL;

    // Sequential Logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count_reg <= 0;
            max_count <= MAX_COUNTER_VAL;
            pulse <= 0;
        end 
        
        else begin
            pulse <= 0;

            if (count_reg < max_count) begin
                count_reg <= count_reg + 1;
            end 
            
            else begin
                count_reg <= 0;
                pulse <= 1;

                if (max_count > MAX_COUNTER_VAL / MAX_SPEED_FACTOR) begin
                    max_count <= max_count - SCALING_FACTOR;
                end 
            end
        end
    end

endmodule