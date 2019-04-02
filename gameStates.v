module gameStates(
   //Inputs
	clk, reset_n, key, done, timesup, restart,
	//Outputs
	x1, y1, x2, y2, x3, y3, x4, y4,
	enable, gamedone, timestart, note,
   HEX0, HEX1, HEX2, HEX3
	);	
   
	input clk, reset_n;
	input [3:0] key;   //user inputs -4 keyboards to hit the tile
	input done;
	input timesup;
	input restart;    //KEY[1]
	
	
	output [7:0] x1, x2, x3, x4;
	output reg [6:0] y1, y2, y3, y4;
	
	output reg enable, timestart, gamedone;
	output reg [3:0] note;   //controls the note of the tiles
	
	output [6:0] HEX0;
	output [6:0] HEX1;
   output [6:0] HEX2;
	output [6:0] HEX3;
	

   //assign a starting position for each x value
   assign x1 = 8'd0;
	assign x2 = 8'd40;
	assign x3 = 8'd80;
	assign x4 = 8'd120;
	
	wire start, update, draw, gameover;
	
	
	statesDatapath d0(key, clk, reset_n, start, draw, update, gameover,
					y1, y2, y3, y4,
					enable, gamedone, timestart, note,
					HEX0, HEX1, HEX2, HEX3);
	
	statesControl c0(clk, reset_n, done, timesup, restart,
	           start, update, draw, gameover);
				  
endmodule
	

//controller of different states of game
module statesControl(
   //Inputs
	clk,
	resetn,
	done,
	timesup,
	restart,
	
	//Outputs
	start,
	update,
	draw,
	gameover
	);
   
	input clk, resetn; 
   input done, timesup, restart;
	
	output reg start, update, draw, gameover;
	
	reg [2:0] current_state, next_state;
	
	localparam S_START = 3'd0,
	           S_DRAW  = 3'd1,
				  S_UPDATE = 3'd2,
				  S_GAMEOVER = 3'd3;
	

// state table
    always@(*)
    begin: state_table 
            case (current_state)
				    S_START: next_state = S_DRAW;
					 S_DRAW: next_state = done ? S_UPDATE : S_DRAW;
                S_UPDATE: next_state = timesup ? S_GAMEOVER : S_DRAW;          
                S_GAMEOVER: next_state = restart ? S_START : S_GAMEOVER;
            default:     next_state = S_START;
        endcase
    end
					 
	 // Control signals
    always @(*)
    begin: enable_signals
	     start = 0;
	     update = 0;
        draw = 0;
        gameover = 0;
		  
		  
        case (current_state)
			S_START: begin	
			  start = 1;
           end
			S_DRAW: begin
			  draw = 1;
			  end
			S_UPDATE: begin
			  update = 1;
			  end
			S_GAMEOVER: begin
			  gameover = 1;
			  end
        endcase
    end

	// current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_START;
        else
            current_state <= next_state;
    end
endmodule	
	


//datapath to generate y positions and calculate score
module statesDatapath(key, clk, reset_n, start, draw, update, gameover,
					 y1, y2, y3, y4,
					 enable, gamedone, timestart, note,
					 HEX0, HEX1, HEX2, HEX3);
		   
	input [3:0] key;
   input clk, reset_n;
	input start, draw, update, gameover;

	output reg [6:0] y1, y2, y3, y4;
   output reg enable, gamedone, timestart;
	output reg [3:0] note;
	
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	
	reg [7:0] score;
	reg [7:0] highscore;
	
	always @(posedge clk)
	begin
		if(! reset_n)
		begin
			y1 <= 7'b0;
			y2 <= 7'b0;
			y3 <= 7'b0;
			y4 <= 7'b0;
			score <= 8'b0;
			highscore <= 8'b0;
		end
		
		else
		begin
			if(start)
			begin
				if(score > highscore)
					highscore = score;
					
					//generate starting y positions
					y1 <= 7'b0000001;
					y2 <= 7'b0010000;
					y3 <= 7'b1000010;
					y4 <= 7'b1011000;
				
				enable <= 0;
				gamedone <= 0;
				timestart <= 1;
				score <= 8'b0;
				note <= 4'b0;
			end
			
			if(draw)
			begin
				enable <= 1;
				gamedone <= 0;
				timestart <= 0;
				note <= 5'b0;
			end
			
			//hit the tile in the collide zone `
			if(update)
			begin
				//hit the first tile
				if((y1 >= 7'd90) && (y1 <= 7'd120) && key[3])
				begin
					score <= score + 1'b1;
					y1 <= 7'd120;
					y2 <= y2 + 1'b1;
					y3 <= y3 + 1'b1;
					y4 <= y4 + 1'b1;
					note <= 4'b0001;
				end
				
				//hit the second tile
				else if((y2 >= 7'd90) && (y2 <= 7'd120) && key[2])
				begin
					score <= score + 1'b1;
					y2 <= 7'd120;
					y1 <= y1 + 1'b1;
					y3 <= y3 + 1'b1;
					y4 <= y4 + 1'b1;
					note <= 4'b0010;
				end
				
				//hit the third tile
				else if((y3 >= 7'd90) && (y3 <= 7'd120) && key[1])
				begin
					score <= score + 1'b1;
					y3 <= 7'd120;				
					y1 <= y1 + 1'b1;
					y2 <= y2 + 1'b1;
					y4 <= y4 + 1'b1;
					note <= 4'b0100;
				end			
				
				//hit the forth tile
				else if((y4 >= 7'd90) && (y4 <= 7'd120) && key[0])
				begin
					score <= score + 1'b1;
					y4 <= 7'd120;				
					y1 <= y1 + 1'b1;
					y2 <= y2 + 1'b1;
					y3 <= y3 + 1'b1;
					note <= 4'b1000;
				end
				
				//tile is not hit
				else
				begin
					y1 <= y1 + 1'b1;
					y2 <= y2 + 1'b1;
					y3 <= y3 + 1'b1;
					y4 <= y4 + 1'b1;
					note <= 4'b0;
				end
				
				//if tile was missed
				if(((y1 == 7'd120) && (!key[3])) ||
					((y2 == 7'd120) && (!key[2])) ||
					((y3 == 7'd120) && (!key[1])) ||
					((y4 == 7'd120) && (!key[0])))
				begin
					if(score > 8'b0)
						score <= score - 1'b1;
				end
				
				enable <= 0;
				gamedone <= 0;
				timestart <= 0;
			end
			
			if(gameover)
			begin
				enable <= 0;
				gamedone <= 1;
				timestart <= 0;
				note <= 4'd0;
			end
		end
	end
	
	//display score on HEX1,HEX0
	decoder d0(HEX1[6:0], score[7:4]);
	decoder d1(HEX0[6:0], score[3:0]);
	//display high socre on HEX3,HEX2
	decoder d2(HEX3[6:0], highscore[7:4]);
	decoder d3(HEX2[6:0], highscore[3:0]);
endmodule

	
module decoder(a, b);
	input [3:0] b;
	output [6:0] a;
	
	assign c0=b[0];
	assign c1=b[1];
	assign c2=b[2];
	assign c3=b[3];
	
	assign a[0]=(c0&~c1&~c2&~c3)+(~c0&~c1&c2&~c3)+(c0&c1&~c2&c3)+(c0&~c1&c2&c3);
	assign a[1]=(~c3&c2&~c1&c0)+(~c3&c2&c1&~c0)+(c3&~c2&c1&c0)+(c3&c2&~c1&~c0)+(c3&c2&c1&~c0)+(c3&c2&c1&c0);
	assign a[2]=(~c3&~c2&c1&~c0)+(c3&c2&~c1&~c0)+(c3&c2&c1&~c0)+(c3&c2&c1&c0);
	assign a[3]=(~c3&~c2&~c1&c0)+(~c3&c2&~c1&~c0)+(~c3&c2&c1&c0)+(c3&~c2&~c1&c0)+(c3&~c2&c1&~c0)+(c3&c2&c1&c0);
	assign a[4]=(~c3&~c2&~c1&c0)+(~c3&~c2&c1&c0)+(~c3&c2&~c1&~c0)+(~c3&c2&~c1&c0)+(~c3&c2&c1&c0)+(c3&~c2&~c1&c0);
	assign a[5]=(~c3&~c2&~c1&c0)+(~c3&~c2&c1&~c0)+(~c3&~c2&c1&c0)+(~c3&c2&c1&c0)+(c3&c2&~c1&c0);
	assign a[6]=(~c3&~c2&~c1&~c0)+(~c3&~c2&~c1&c0)+(~c3&c2&c1&c0)+(c3&c2&~c1&~c0);
endmodule 
		
