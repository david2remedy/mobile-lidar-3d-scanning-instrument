`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2021 11:32:37 PM
// Design Name: 
// Module Name: lcd
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lcd(
  clk,
  rs,
  e,
  d
);

parameter STATE00 = 2'b00;
parameter STATE01 = 2'b01;
parameter STATE02 = 2'b10;
parameter DONE    = 2'b11;

input clk;
output rs;
output e;
output [7:0] d;

reg rs = 1'b0;
reg e = 1'b0;
reg d = 8'b00000000;

reg [1:0] state = 2'b00;
reg [23:0] count = 24'h000000;

always @(posedge clk) begin
  case (state)
    STATE00: begin                        
      if (count == 24'h000000) begin      // if this is the first cycle of STATE00
        rs <= 1'b1;                       // pull RS high to indicate data
        d  <= 8'h48;                      // load the databus with ASCII "H"
        count <= count + 24'h000001;      // increment the counter
      end  
      else if (count == 24'h000005) begin // if 50ns have passed
        count <= 24'h000000;              // clear the counter
        state <= STATE01;                 // advance to the next state
      end
      else begin                          // if it's not the first or last
        count <= count + 24'h000001;      // increment the counter
      end
    end
    STATE01: begin                        
      if (count == 24'h000000) begin      // if this is the first cycle of STATE01
        e <= 1'b1;                        // bring E high to initiate data read
        count <= count + 24'h000001;      // increment the counter
      end
      else if (count == 24'h000019) begin // if 250ns have passed
        count <= 24'h000000;              // clear the counter  
        state <= STATE02;                 // advance to the next state
      end
      else begin                          // if it's not the first or last
        count <= count + 24'h000001;      // increment the counter
      end
      end
    STATE02: begin
      if (count == 24'h000000) begin      // if this is the first cycle of STATE02
        e <= 1'b0;                        // bring E low
        count <= count + 24'h000001;      // increment the counter
      end
      else if (count == 24'h000FA0) begin // if 40us have passed
        count <= 24'h000000;              // clear the counter    
        state <= DONE;                    // advance to the next state
      end
      else begin                          // if it's not the first or last
        count <= count + 24'h000001;      // increment the counter
      end
    end
    DONE: ;
    default: ;
  endcase 
end
endmodule