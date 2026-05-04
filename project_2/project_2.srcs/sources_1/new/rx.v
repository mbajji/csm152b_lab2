`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/22/2026 10:25:04 AM
// Design Name: 
// Module Name: tx
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


//module rx(
//    input wire baud_rate,
//    input wire rst,
//    input wire rx_line,
    
//    output reg [7:0] led
//    );
//    integer i = 0;
//    reg [7:0] cache;
    
//    always @(posedge baud_rate) begin
//        if (i < 8) begin
//            cache[i] = rx_line;
//            i = i+1;
//        end else begin
//            led <= cache;
//            i = 0;
//        end
//    end
          
//endmodule


module rx(
    input wire baud_rate,       
    input wire rst,       
    //input wire btn,       
    input wire rx_line,
    output reg busy = 1'b0,       
    output reg [7:0] data = 8'b0
);

    // State Encoding
    localparam IDLE_STATE  = 2'b00;
    localparam START_STATE = 2'b01;
    localparam DATA_STATE  = 2'b10;
    localparam STOP_STATE  = 2'b11;

    reg [1:0] curr_state = IDLE_STATE;
    reg [3:0] i = 3'b0; 
    reg [7:0] cache = 8'b0;   

    always @(posedge baud_rate or posedge rst) begin
        if (rst) begin
            curr_state <= IDLE_STATE;
            data <= 8'b0;
            i <= 0;
            cache <= 8'b0;
            busy <= 1'b0;
        end
        else begin
            case (curr_state)
                IDLE_STATE: begin
                    busy <= 1'b0;
                    if (rx_line == 1'b0) begin
                        curr_state <= DATA_STATE;
                        i <= 0;
                        busy <= 1'b1;
                    end
                end

                DATA_STATE: begin
                   
                    cache[i] <= rx_line;
                    if (i == 7) begin
                        i <= 0;
                        curr_state <= STOP_STATE;
                    end else begin
                        i <= i + 1;
                    end
                end

                STOP_STATE: begin
                    data <= cache;   
                    curr_state <= IDLE_STATE;
                end

                default: curr_state <= IDLE_STATE;
            endcase
        end
    end
endmodule
