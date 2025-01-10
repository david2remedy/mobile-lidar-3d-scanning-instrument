//**************************************************************//
//*vga_top instantiates the vga, lidar datat, dtg and colorizer
//*
//*links wishbone vga register
//*Two frame buffers for the COE image or the LidarImage
//*Writes based on switch 16, on = COE, off = LidarImage
//*
//**************************************************************//

module vga_top(
	//input  wire [31:0] wb_vga_reg, //Lives in swervolf_core
	input  wire	        rst_n,
	input  wire [31:16]	switches,
	input  wire	        clk_31_5,
	input  wire [3:0]  vga_pixel_color,
	input  wire [18:0] vga_pix_num,
	output logic [3:0] 	VGA_R,
	output logic [3:0] 	VGA_G,
	output logic [3:0] 	VGA_B,
	output logic 		VGA_VS,
	output logic	    VGA_HS	
);

//logic   [11:0] Servo_Yaw_pixel;
//logic   [11:0] Servo_Pitch_pixel; 
//logic   [3:0]  Servo_Color;

//ASSIGN COLOR BASED ON SCAN
//always_comb begin: Comb_Logic_Color
    //Servo_Yaw_pixel   =   vga_pixel_color   [11:0];
    //Servo_Pitch_pixel =   vga_pixel_color   [23:12];
    //Servo_Color       =   vga_pixel_color   [27:24];
//end : Comb_Logic_Color



// Instantiate dtg.v
// Add the connections from the horiz_sync, vert_sync through any module
// ...levels up to the top of the design. 
logic	[18:0] pix_num;
logic	[11:0] pixel_row, pixel_column;
logic	 video_on;

dtg dtginstance(
.clock(clk_31_5),
.rst(rst_n),
.horiz_sync(VGA_HS),
.vert_sync(VGA_VS),  
.video_on(video_on),
.pixel_row(pixel_row), 			//Sent back of pixel row writing to
.pixel_column(pixel_column), 	//Sent back of pixel column writing to
.pix_num(pix_num)
);

//Instantiate Ram/ROM frame buffer 
//b.	Connect the clk port for both read/write ports, but tie off any other write ports to 1'b0 so no writes happen.  
//c.	The read address is the pix_num from dtg.  
//d.	The read output of the memory will get tied to identically to the VGA Red, Green, Blue outputs.
wire [3:0] dataout;

vga_rom VGA_ROM1(
  .clka(clk_31_5),    // input wire clka
  .wea(1'b1),      // input wire [0 : 0] wea
  .addra(vga_pix_num[18:0]),  // input wire [18 : 0] addra
  .dina(vga_pixel_color[3:0]),    // input wire [3 : 0] dina
  .clkb(clk_31_5),    // input wire clkb
  .addrb(pix_num[18:0]),  // input wire [18 : 0] addrb
  .doutb(dataout)  // output wire [3 : 0] doutb
);

//vga_pix_num[18:0]

logic Processtype;
//logic [3:0] DataoutProcessed;
always_comb begin : SwitchCheck
    if(switches[16] == 1) begin
        Processtype = 1; //Selector for the display
    end
    else begin
        Processtype = 0;
    end
end : SwitchCheck

//Choose to display if the video is on, 
//also check to write the cursor or background
always_comb begin
    if (~video_on) begin
      {VGA_R,VGA_G,VGA_B} = 12'h000;
    end
    else begin //The data image needs to be output or image processed version
      unique case(Processtype)
        0 : begin //VGA COE Image
            VGA_R = dataout;
            VGA_G = dataout;
            VGA_B = dataout;
            end
        1 : begin //LIDAR Image
            VGA_R = vga_pixel_color[3:0];
            VGA_G = vga_pixel_color[3:0];
            VGA_B = vga_pixel_color[3:0];
            end
        default: begin
            VGA_R = dataout;
            VGA_G = dataout;
            VGA_B = dataout;
        end
      endcase
    end//end else
end //always_comb

endmodule

//*********************************************************************************************************************


//Original Module and Attempt Failure files, kept for reference

/*
//Instantiate Ram/ROM frame buffer for LIDAR
//b.	Connect the clk port for both read/write ports, but write port to 1'b1 when Lidar Reg is filled.
//c.	The read address is the pixel_numb of yaw*pitch from vga_pixel_color.  
//d.	The read output of the memory will get tied to identically to the VGA Red, Green, Blue outputs
logic [3:0] lidar_dataout;
lidar_rom_0 your_instance_name (
  .clka(clk_31_5),    // input wire clka
  .wea(1'b1),      // input wire [0 : 0] wea, Testing always write enabled, may block read???
  .addra(lidar_pixnum),  // input wire [18 : 0] addra, this is the pixel number calculated from yaw*pitch
  .dina(Servo_Color),    // input wire [3 : 0] dina
  .clkb(clk_31_5),    // input wire clkb
  .addrb(pix_num),  // input wire [18 : 0] addrb
  .doutb(lidar_dataout)  // output wire [3 : 0] doutb
);
*/


/*
//Choose to display if the video is on, 
//also check to write the cursor or background
always_comb begin
    if (~video_on) begin
      {VGA_R,VGA_G,VGA_B} = 12'h000;
    end
    else begin
      if(cursorvisible) begin
      {VGA_R,VGA_G,VGA_B} = 12'hfff;
      end
      else begin //The data image needs to be output or image processed version
          unique case(Processtype)
            0 : begin 
                VGA_R = dataout;
                VGA_G = dataout;
                VGA_B = dataout;
                end
            1 : begin 
                VGA_R = DataoutProcessed;
                VGA_G = DataoutProcessed;
                VGA_B = DataoutProcessed;
                end
            2 : begin 
                VGA_R = DataoutProcessed;
                VGA_G = DataoutProcessed;
                VGA_B = DataoutProcessed;
                end
            3 : begin
                VGA_R = DataoutProcessed;
                VGA_G = DataoutProcessed;
                VGA_B = DataoutProcessed;
                end
            4 : begin
                VGA_R = DataoutProcessed;
                VGA_G = DataoutProcessed;
                VGA_B = DataoutProcessed;
                end
            default: begin
                VGA_R = dataout;
                VGA_G = dataout;
                VGA_B = dataout;
                end
          endcase
      end
    end
end //always_comb*/

/*
logic [2:0] Processtype;
logic [3:0] DataoutProcessed;
logic [4:0] G;
always_comb begin : IMAGEPROCESSING
if(pixel_row > 0) begin //Don't run the warmup row

    if (switches[19:16] == 4'b0000) begin
        Processtype = 0;//Normal Grayscale
    end
    
    if(switches[16] == 1) begin //GREYBARS using bit 4 of pixnum. Could improve with a function possibly.
        Processtype = 1; //Selector for the display
        if(pix_num[4] == 1) begin
            DataoutProcessed = {4'b1111};
        end
        else begin
            DataoutProcessed = {4'b0000};
        end
    end
    
    if(switches[17] == 1) begin //THRESHOLDING
    Processtype = 2;
        if (dataout < {1'b0,switches[22:20],1'b0}) begin
        DataoutProcessed = 4'b0000;
        end
        else begin
        DataoutProcessed = 4'b1111;
        end
    end
    
    if(switches[18] == 1) begin //ROBERTS CROSS ONLY,  G = |Gx|+|Gy|
        Processtype = 3;
        if(pix_row_save[0]>pix_row_save[640]) begin
            G = pix_row_save[0] - pix_row_save[640];
        end
        else begin
            G = pix_row_save[640] - pix_row_save[0];
        end
        if(pix_row_save[1]>pix_row_save[639]) begin
            G = G + pix_row_save[1] - pix_row_save[639];
        end
        else begin
            G = G + pix_row_save[639] - pix_row_save[1];
        end
        DataoutProcessed = G[4:1]; //Take upper 4 bits
    end
    
    if(switches[19] == 1) begin // ROBERTS CROSS WITH GRAYSCALE AGAINST 6:4
      Processtype = 4;
      if(switches[18] == 1) begin //ROBERTS CROSS, G = |Gx|+|Gy|
        if(pix_row_save[0]>pix_row_save[640]) begin
            G = pix_row_save[0] - pix_row_save[640];
        end
        else begin
            G = pix_row_save[640] - pix_row_save[0];
        end //GX Now known, use for adding to GY below
        if(pix_row_save[1]>pix_row_save[639]) begin
            G = G + pix_row_save[1] - pix_row_save[639];
        end
        else begin
            G = G + pix_row_save[639] - pix_row_save[1];
        end //G now fully known but extends to 5 bits, use 1:5 instead
        DataoutProcessed = G[4:1]; //Take upper 4 bits
        //Thresholding within Roberts cross below
        if (G[4:1] < {1'b0,switches[22:20],1'b0}) begin
            DataoutProcessed = 4'b0000;
        end 
        else begin
            DataoutProcessed = 4'b1111;
        end
       end // EO Roberts cross
      end // EO ROBERTS CROSS WITH GRAYSCALE AGAINST 6:4
end //EO First row run
end : IMAGEPROCESSING*/


/*
//The following function checks if the switches are on
//The function also checks if the cursor should be displayed
logic [1:0] cursorvisible;
always_comb begin
    if ( pixel_row > (spriterow - 2) && pixel_row < (spriterow + 2) && (spritecolumn - 2) < pixel_column && (pixel_column < spritecolumn + 2) ) begin
		cursorvisible = 1'b1;
		//TODO b modify dout if within these bounds, do additional bounds for 1st 2nd 3rd 4th row to be "transparent"
	end
	else begin
	cursorvisible = 1'b0;
	end
end

//l row value save currently implemented as a large shift register.  
//Could be implemented as a memory.
// Used for edge detection to be able to check a 2x2 pixel array
reg [3:0] pix_row_save[640:0];
integer i;
always_ff @(posedge clk_31_5) begin
    if ( video_on) begin
        // Blocking assignment use.  Do the shift register starting at high number and down to bottom.
        // So the shift does not roll through the full shift register in one clock cycle
        // blocking vs non-blocking is an important concept
        // https://www.nandland.com/articles/blocking-nonblocking-verilog.html
        for (i=640; i>0 ; i=i-1) begin
        pix_row_save[i] = pix_row_save[i-1];
        end
        pix_row_save[0] = dataout;
    end
end
*/


/*
logic   [15:0]  spriterow;
logic   [15:0]  spritecolumn;
logic   [3:0]   spritecolor;
*/
//Assigning position of the sprite based on vga_reg, 
//Moves to 3/3 from wb reset
/*always @(posedge clk_31_5) begin : sequentiallogic2
    spriterow      <= wb_vga_reg[15:0];
    spritecolumn   <= wb_vga_reg[31:16];
end : sequentiallogic2
*/
/*always_comb begin : combinationalblock1
    spriterow      = wb_vga_reg[15:0];
    spritecolumn   = wb_vga_reg[31:16];
end : combinationalblock1*/