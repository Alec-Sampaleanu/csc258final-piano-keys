module fullController(
    // Inputs
    clk,
    resetn,
    start,             //KEY[0]     go - enable_gc
	 key,
	 note,
    	 

    // Outputs
    draw_enable,       //writeEn
    col_out,
    x_out,
    y_out,
	HEX0, HEX1, HEX2, HEX3
);

	// Inputs
    input			clk;				//	50 MHz
	input 		resetn, start;
	input [3:0] key;
	input [3:0] note;
	
   // Outputs
	output              draw_enable;
	output reg [2:0]    col_out;
	output reg [7:0]	x_out;
	output reg [6:0]	y_out;
	
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	
	wire [7:0] x1, x2, x3, x4;
	wire [6:0] y1, y2, y3, y4;
	

    
    wire [1:0]  select_data;

    wire [2:0]  col_gc, col_bg, col_hs, col_go;
    wire [7:0]  x_gc, x_bg, x_hs, x_go;
    wire [6:0]  y_gc, y_bg, y_hs, y_go;
	
	
	
	
	// gameControllerWires
    wire done_gc;
	wire game_over;
	
	
	
	// gameStatesWires
	wire timesup;
	wire timestart;
	
    wire plot_gc, plot_bg, plot_hs, plot_go;
	
    wire enable_gc, draw_background, draw_homescreen, draw_gameover;
    wire background_drawn, homescreen_drawn, gameover_drawn;
	

    // Background Images

    drawBackground bg0(
        .clk(clk),
        .resetn(resetn),
        .enable(draw_background),
        .col_out(col_bg),
        .x_out(x_bg),
        .y_out(y_bg),
        .plot_bg(plot_bg),
        .completed(background_drawn)
    );

    drawHomescreen hs0(
        .clk(clk),
        .resetn(resetn),
        .enable(draw_background),
        .col_out(col_hs),
        .x_out(x_hs),
        .y_out(y_hs),
        .plot_bg(plot_hs),
        .completed(homescreen_drawn)
    );

    drawGameover go0(
        .clk(clk),
        .resetn(resetn),
        .enable(draw_background),
        .col_out(col_go),
        .x_out(x_go),
        .y_out(y_go),
        .plot_bg(plot_go),
        .completed(gameover_drawn)
    );


    // Game timer
	gameover g0(clk, timesup, timestart);
	
	
	//Instantiate drawTiles
	drawTiles dt(x1, y1, x2, y2, x3, y3, x4, y4,
	                clk, resetn, enable_gc, game_over,
                    //outputs
                    col_gc, x_gc, y_gc, plot_gc, done);
	
	
	//Instantiate gameStates
	gameStates gs0(clk, resetn, key, done, timesup, start,
	                //Outputs
	                x1, y1, x2, y2, x3, y3, x4, y4,
	                enable_gc, game_over, timestart, note,
                    HEX0, HEX1, HEX2, HEX3);					
					


    // Instantiate control path
    fullControllerControl fcc0(
        .clk(clk),
        .resetn(resetn),
        .start(start),
        .game_over(game_over),
        .homescreen_drawn(homescreen_drawn),
        .gameover_drawn(gameover_drawn),
		.plot_gc(plot_gc),
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
                x_out   = x_bg;
                y_out   = y_bg;
                col_out = col_bg;
            end
            2'b10: begin
                x_out   = x_hs;
                y_out   = y_hs;
                col_out = col_hs;
            end
            2'b11: begin
                x_out   = x_go;
                y_out   = y_go;
                col_out = col_go;
            end
        endcase
    end

    assign draw_enable = plot_gc || plot_hs || plot_bg || plot_go;

endmodule


module fullControllerControl(
    // Inputs
    clk,
    resetn,
    start,
    game_over,
    homescreen_drawn,
    gameover_drawn,
    background_drawn,
	plot_gc,
    
    // Outputs
    draw_enable,
    select_data,
    draw_background,
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
    output reg       draw_background, draw_homescreen, draw_gameover, enable_gc;

    // State registers
	reg [3:0] current_state, next_state;

    localparam  S_DRAW_HOME_SCREEN  = 3'd0,
                S_HOME_SCREEN       = 3'd1,
                S_HOME_SCREEN_WAIT  = 3'd2,
                S_DRAW_BACKGROUND   = 3'd3,
                S_GAME_PLAYING      = 3'd4,
                S_GAME_PLAYING_WAIT = 3'd5,
                S_DRAW_GAME_OVER    = 3'd6,
                S_GAME_OVER         = 3'd7,
                S_GAME_OVER_WAIT    = 3'd8;

    // Next state logic
    always @(*)
    begin: state_table
        case (current_state)
            S_DRAW_HOME_SCREEN: next_state = homescreen_drawn ? S_HOME_SCREEN : S_DRAW_HOME_SCREEN;
            S_HOME_SCREEN: next_state = start ? S_HOME_SCREEN_WAIT : S_HOME_SCREEN;     
            S_HOME_SCREEN_WAIT: next_state = start ? S_HOME_SCREEN_WAIT : S_DRAW_BACKGROUND;
            S_DRAW_BACKGROUND: next_state = background_drawn ? S_GAME_PLAYING : S_DRAW_BACKGROUND;
            S_GAME_PLAYING: next_state = game_over ? S_GAME_PLAYING_WAIT : S_GAME_PLAYING;
            S_GAME_PLAYING_WAIT: next_state = game_over ? S_GAME_PLAYING_WAIT : S_DRAW_GAME_OVER;
            S_DRAW_GAME_OVER: next_state = gameover_drawn ? S_GAME_OVER : S_DRAW_GAME_OVER;
            S_GAME_OVER: next_state = start ? S_GAME_OVER_WAIT : S_GAME_OVER;
            S_GAME_OVER_WAIT: next_state = start ? S_GAME_OVER_WAIT : S_DRAW_BACKGROUND;
            default: next_state = S_DRAW_HOME_SCREEN;
        endcase
    end

    // Datapath control signals
    always @(*)
    begin: enable_signals
    // By default make all our signals 0
        draw_enable = 1'b0;
		select_data = 2'b0;
        draw_background = 1'b0
        draw_homescreen = 1'b0;
        draw_gameover = 1'b0;
        enable_gc = 1'b0;

        case (current_state)
            S_DRAW_HOME_SCREEN: begin
                select_data = 2'b0;
                draw_homescreen = 1'b1;
            end
            S_DRAW_BACKGROUND: begin
                select_data = 2'b1;
                draw_background = 1'b1;
            S_GAME_PLAYING: begin
                select_data = 2'b10;
                enable_gc = 1'b1;
            end
            S_DRAW_GAME_OVER: begin
                select_data = 2'b11;
                draw_gameover = 1'b1;
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

//counts to 1 minutes and sets over to 1 when counter is 1 minute
module gameover(clock, over, restart);
	
	input clock;
	input restart;
	output reg over;
	
	reg [32:0]count;
	
	always @(posedge clock)
	begin
		if (restart)
			count<=32'd0;
		else if(!restart)	
			count<=count+1'b1;
		
		if (count>=32'd3000000000)
			over<=1;
		else
			over<=0;
	end
endmodule



