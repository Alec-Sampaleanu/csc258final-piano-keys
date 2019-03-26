module fullController(
    // Inputs
    clk,
    resetn,
    start,

    // Outputs
    draw_enable,
    col_out,
    x_out,
    y_out
);

    // Inputs
    input			clk;				//	50 MHz
	input 			resetn, start;

	// Outputs
	output              draw_enable;
	output reg [2:0]    col_out;
	output reg [7:0]	x_out;
	output reg [6:0]	y_out;

    // gameControllerWires
    wire enable_gc;
    wire draw_homescreen;
    wire draw_gameover;
    
    wire [1:0]  select_data;

    wire [2:0]  col_gc, col_hs, col_go;
    wire [7:0]  x_gc, x_hs, x_go;
    wire [6:0]  y_gc, y_hs, y_go;
    

    // Instantiate gameController
    gameController gc0(
        
    );

    // Instantiate drawHomescreen
    drawHomescreen dhs0(

    );

    // Instantiate drawGameover
    drawGameover dgo(

    );

    // Instantiate control path
    fullControllerControl fcc0(
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .game_over(game_over),
        .homescreen_drawn(homescreen_drawn),
        .gameover_drawn(gameover_drawn),
        .draw_enable(draw_enable),
        .select_data(select_data),
        .draw_homescreen(draw_homescreen),
        .draw_gameover(draw_gameover),
        .enable_gc(enable_gc)
    );

    // Combinatorial logic
    always @(*)
    begin: drawable_multiplexer
        case (select_data)
            2'b0: begin
                x_out   = x_hs;
                y_out   = y_hs;
                col_out = col_hs;
            end
            2'b1: begin
                x_out   = x_gc;
                y_out   = y_gc;
                col_out = col_gc;
            end
            2'b10: begin
                x_out   = x_go;
                y_out   = y_go;
                col_out = col_go;
            end
        endcase
    end

endmodule


module fullControllerControl(
    // Inputs
    clk,
    resetn,
    start,
    game_over,
    homescreen_drawn,
    gameover_drawn,
    
    // Outputs
    draw_enable,
    select_data,
    draw_homescreen, 
    draw_gameover, 
    enable_gc
);
    
    // Inputs
    input			clk;				//	50 MHz
	input 			resetn, start, game_over;
    input           homescreen_drawn, gameover_drawn;

	// Outputs
	output reg       draw_enable;
    output reg [1:0] select_data;
    output reg       draw_homescreen, draw_gameover, enable_gc;

    // State registers
	reg [2:0] current_state, next_state;

    localparam  S_DRAW_HOME_SCREEN  = 3'd0,
                S_HOME_SCREEN       = 3'd1,
                S_HOME_SCREEN_WAIT  = 3'd2,
                S_GAME_PLAYING      = 3'd3,
                S_GAME_PLAYING_WAIT = 3'd4,
                S_DRAW_GAME_OVER    = 3'd5,
                S_GAME_OVER         = 3'd6,
                S_GAME_OVER_WAIT    = 3'd7;

    // Next state logic
    always @(*)
    begin: state_table
        case (current_state)
            S_DRAW_HOME_SCREEN: next_state = homescreen_drawn ? S_HOME_SCREEN : S_DRAW_HOME_SCREEN;
            S_HOME_SCREEN: next_state = start ? S_HOME_SCREEN_WAIT : S_HOME_SCREEN;     
            S_HOME_SCREEN_WAIT: next_state = start ? S_HOME_SCREEN_WAIT : S_GAME_PLAYING;
            S_GAME_PLAYING: next_state = game_over ? S_GAME_PLAYING_WAIT : S_GAME_PLAYING;
            S_GAME_PLAYING_WAIT: next_state = game_over ? S_GAME_PLAYING_WAIT : S_DRAW_GAME_OVER;
            S_DRAW_GAME_OVER: next_state = gameover_drawn ? S_GAME_OVER : S_DRAW_GAME_OVER;
            S_GAME_OVER: next_state = start ? S_GAME_OVER_WAIT : S_GAME_OVER;
            S_GAME_OVER_WAIT: next_state = start ? S_GAME_OVER_WAIT : S_GAME_PLAYING;
            default: next_state = S_DRAW_HOME_SCREEN;
        endcase
    end

    // Datapath control signals
    always @(*)
    begin: enable_signals
    // By default make all our signals 0
        draw_enable = 1'b0;
		select_data = 2'b0;
        draw_homescreen = 1'b0;
        draw_gameover = 1'b0;
        enable_gc = 1'b0;

        case (current_state)
            S_DRAW_HOME_SCREEN: begin
                select_data = 2'b0;
                draw_homescreen = 1'b1;
                draw_enable = 1'b1;
            end
            S_GAME_PLAYING: begin
                select_data = 2'b1;
                enable_gc = 1'b1;
                draw_enable = 1'b1;
            end
            S_DRAW_GAME_OVER: begin
                select_data = 2'b10;
                draw_gameover = 1'b1;
                draw_enable = 1'b1;
            end
        endcase
    end

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_DRAW_HOME_SCREEN;
        else
            current_state <= next_state;
    end

endmodule
                


