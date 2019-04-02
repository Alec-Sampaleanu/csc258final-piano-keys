module pianoKeys(
        // Inputs
        CLOCK_50,
        KEY,

        // Outputs
        HEX0, 
        HEX1,
        HEX2,
        HEX3

        // VGA ports
		VGA_CLK,   						
		VGA_HS,							
		VGA_VS,							
		VGA_BLANK_N,					
		VGA_SYNC_N,						
		VGA_R,   						
		VGA_G,	 						
		VGA_B,   						
	
        // Audio ports
		CLOCK_27,
		AUD_ADCDAT,
		AUD_BCLK,
		AUD_ADCLRCK,
		AUD_DACLRCK,
		I2C_SDAT,
		AUD_XCK,
		AUD_DACDAT,
		I2C_SCLK,
	);

    input   [9:0]   SW;
	input   [3:0]   KEY;
	input           CLOCK_50;

	output  [6:0]   HEX0;
	output  [6:0]   HEX1;

    // VGA 
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
    // Audio		
	input				CLOCK_27;	
	input				AUD_ADCDAT;

    inout				AUD_BCLK;
    inout				AUD_ADCLRCK;
    inout				AUD_DACLRCK;
    inout				I2C_SDAT;

    output				AUD_XCK;
    output				AUD_DACDAT;
    output				I2C_SCLK;




    fullController f0(
        .clk(CLOCK_50),
        .resetn(SW[0]),
        
    )
