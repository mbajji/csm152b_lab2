`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2026 10:33:18 AM
// Design Name: 
// Module Name: clkdiv
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


module clkdiv(
    input clk,
    output reg baud_rate
    );
    localparam div = 10417/2 - 1;
    reg [13:0] ctr;
    
    initial begin
        ctr = 0;
        baud_rate = 0;
    end
    
    always @(posedge clk) begin
        if (ctr >= div) begin
            baud_rate <= ~baud_rate;
            ctr <= 0;
        end else begin
            ctr <= ctr + 1;
        end
    end
endmodule
