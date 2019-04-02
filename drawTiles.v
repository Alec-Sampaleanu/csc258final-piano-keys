module drawTiles(
    // Inputs
	 x1, y1, 
	 x2, y2, 
	 x3, y3, 
	 x4, y4,
    clk,						
    resetn,
	 enable,
    
    // Outputs
    col_out,
    x_out,
    y_out,
	 plot,
	 done						
);

	// Inputs
	input [7:0] x1, x2, x3, x4;
	input [6:0] y1, y2, y3, y4;
	
	input clk;				//	50 MHz
	input resetn;
	input enable;        // signal to start game from reset
	
	// Outputs
	output reg [2:0]  col_out;
	output reg [7:0]  x_out;
	output reg [6:0]  y_out;
	output reg plot;    
	output reg done;    //all 4 tiles habe been drawn
	
	wire [7:0] x;
	wire [6:0] y;       // Position of pixel to be drawn
	wire find, erase, draw, finish;
	wire found, doneerase, donedraw;

gameDatapath d0(x1, y1, x2, y2, x3, y3, x4, y4,
            clk, resetn,
				enable, find, draw, erase, finish,
				found, donedraw, doneerase, done,
				x_out, y_out, col_out);

gameControl c0(clk, reset_n, found, doneerase, donedraw, done,
           enable, draw, erase, find, finish, plot);
			  
endmodule
		
module gameControl(
    // Inputs
	 clk,
	 resetn,
    found,
	 doneerase,
	 donedraw,
	 done,
	
    // Outputs
	 enable,
    draw,
	 erase,
	 find,
	 finish,
	 plot
	 );

    // Inputs
	 input clk;				
	 input resetn;
    input found;
	 input doneerase;
	 input donedraw;
	 input done;

	 // Outputs
	 output reg enable;
    output reg find;
    output reg draw;
	 output reg erase;
	 output reg finish;
	 output reg plot;

	 // State registers
	 reg [2:0] current_state, next_state;


	 localparam S_RESET      =  3'd0,
	            S_RESET_WAIT =  3'd1,
					S_FIND       =  3'd2,
					S_ERASE      =  3'd3,
					S_DRAW       =  3'd4,
					S_FINISH     =  3'd5;
					
					
					
	 // state table
    always@(*)
    begin: state_table 
            case (current_state)
				    S_RESET: next_state = enable ? S_RESET_WAIT : S_RESET;
					 S_RESET_WAIT: next_state = enable ? S_RESET_WAIT : S_FIND;
                S_FIND: next_state = found ? S_ERASE : S_FIND;
                S_ERASE: next_state = doneerase ? S_DRAW : S_ERASE;
					 S_DRAW: next_state = donedraw ? S_FINISH : S_DRAW;
					 S_FINISH: next_state = done ? S_RESET : S_FIND;
            default:     next_state = S_RESET;
        endcase
    end
					 
	 // Control signals
    always @(*)
    begin: enable_signals
	     enable = 0;
	     find = 0;
        draw = 0;
        erase = 0;
		  finish = 0;
		  plot = 0;
		  
		  
        case (current_state)
			S_RESET: begin	
			  enable = 1;
           end
			S_FIND: begin
			  find = 1;
			  end
			S_ERASE: begin
			  erase = 1;
			  plot = 1;
			  end
			S_DRAW: begin
			  draw = 1;
			  plot = 1;
			  end
			S_FINISH: begin
			  finish = 1;
			  end
        endcase
    end

	// current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_RESET;
        else
            current_state <= next_state;
    end
endmodule
	

		
//Combine all the states of the game: reset, find, draw, erase, finish
module gameDatapath(x1, y1, x2, y2, x3, y3, x4, y4,
                clk, reset_n, enable,
					 find, draw, erase, finish, 
					 found, donedraw, doneerase, done,
					 X, Y, colour);

input [7:0] x1,x2,x3,x4;
input [6:0] y1,y2,y3,y4; 
input clk, reset_n, enable;
input find, draw, erase, finish;

output reg found, donedraw, doneerase, done;
output reg [7:0] X;
output reg [6:0] Y;
output reg [2:0] colour;

//current location of pixel to draw/erase
wire [7:0] x;
wire [6:0] y;
wire [2:0] count;  // Count number of tiles that have been drawn

//
//always (@posedge clk)
//begin
//   if(gamedone && find)
//	begin
//	   x <= 8'b0;
//		y <= 7'b0;
//	end
//end

reset m0(clk, reset_n ,enable, count, x, y, done);
find  m1(x1, y1, x2, y2, x3, y3, x4, y4,
		   clk, reset_n, find, count,
		   x, y, found, done);
draw  m2(x, y, clk, reset_n, draw, donedraw, X, Y, colour, done);
erase m3(x, y, clk, reset_n, erase, doneerase, X, Y, colour, done);
finish m4(clk, reset_n, count, finish, done);


endmodule

//Set x, y to 0
module reset(clk, reset_n, enable, count, x, y, done);

input clk, reset_n, enable;
output reg [7:0] x;
output reg [6:0] y;
output reg [2:0] count;
output reg done;

always @(posedge clk)
begin	
	if(! reset_n || enable)
	begin
      x <= 8'b0;
	   y <= 7'b0;
		count <= 3'b0;
		done <= 0;
	end
end
endmodule


//Loop throgh screen and find the tile to draw/erase (x-1,y) is the actual position
module find(x1, y1, x2, y2, x3, y3, x4, y4,
				clk, reset_n, find, count,
				x, y, found, done);

input [7:0] x1,x2,x3,x4;
input [6:0] y1,y2,y3,y4;
input clk, reset_n, find;

output reg [2:0] count;
output reg [7:0] x;
output reg [6:0] y;
output reg found;
output reg done;

always @(posedge clk)
begin
	done <= 0;
	if(!reset_n)
	begin
	  x <= 8'b0;
	  y <= 7'b0;
	end
	
	else  
	begin
		if(find)
		begin
			done <= 0;
			if(x > 8'd160)
			begin
				x <= 8'b0;
				y <= y + 1'b1;
			end
			
			else
			begin
				x <= x + 1'b1;
				if(((x == x1) && (y == y1)) || 
				   ((x == x2) && (y == y2)) || 
					((x == x3) && (y == y3)) || 
					((x == x4) && (y == y4)))
				begin
					  found <= 1;
					  count <= count + 1'b1;
				end
				else
					  found <= 0;
			end
	   end
	end
end
	
endmodule
			
	

//Draw a specific tile by looping through and drawing a black 40x30 tile
module draw(x_in, y_in, clk, reset_n, draw, donedraw, x_out, y_out, colour, done);

input [7:0] x_in;
input [6:0] y_in;
input clk, reset_n, draw;
output reg [7:0] x_out;
output reg [6:0] y_out;
output reg [2:0] colour;
output reg donedraw;
output reg done;

reg [5:0] x;
reg [3:0] y;

always @(posedge clk)
begin
   done <= 0;
   if(!reset_n)
	  x <= 6'b0;
	else
	begin
	   if(draw)
		colour = 3'b111;
		begin
		   if(x == 6'd40)
			begin
			   x <= 6'b0;
				if(y < 5'd29)
				  y <= y + 1'b1;
				else
				  y <= 5'b0;
			end
			
		   else
			begin
				x_out <= x_in - 1'b1 + x;
				y_out <= y_in + y;
			   x <= x + 1'b1;			
			end
			
			if((x == 6'd40) && (y == 5'd30))
				donedraw <= 1;
			else
			   donedraw <= 0;
		end
	end
end
endmodule

//Erase a specific tile by looping thtough and drawing a white 40x30 tile
module erase(x_in, y_in, clk, reset_n, erase, doneerase, x_out, y_out, colour, done);

input [7:0] x_in;
input [6:0] y_in;
input clk, reset_n, erase;

output reg [7:0] x_out;
output reg [6:0] y_out;
output reg [2:0] colour;
output reg doneerase;
output reg done;

reg [5:0] x;
reg [3:0] y;

always @(posedge clk)
begin
   done <= 0;
   if(!reset_n)
	  x <= 6'b0;
	else
	begin
	   if(erase)
		colour = 3'b000;
		begin
		   if(x == 6'd40)
			begin
			   x <= 6'b0;
				if(y < 5'd29)
				  y <= y + 1'b1;
				else
				  y <= 5'b0;
			end
			
		   else
			begin
				x_out = x_in - 1'b1 + x;
				
	         if(y_in > 7'b0)
				begin
				   y <= y - 1'b1;
				end
				
				y_out <= y_in + y;
			   x <= x + 1'b1;			
			end
			
			if((x == 6'd40) && (y == 5'd30))
				doneerase <= 1;
			else
			   doneerase <= 0;
		end
	end
end
endmodule


//finish done if all 4 tiles have been drawn
module finish(clk, reset_n, count, finish, done);

input clk, reset_n;
input count;
input finish;
output reg done;

always @(posedge clk)
begin
   if(reset_n && finish && (count == 3'b100))
	   done <= 1;
	else
	   done <= 0;
end
endmodule








	             			
		   
	 
	


