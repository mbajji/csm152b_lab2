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


//module tx(
//    input wire baud_rate,
//    input wire btn,
//    input wire rst,
//    input wire [7:0] data,

//    output wire tx_line,
//    output wire on
//);
//    integer i = 0; 
//    assign on = 1'b0;
    
//    always @(posedge btn) begin
//        if (on == 0) begin
//            assign on = 1;
//    end
        
//    always @(posedge baud_rate) begin
//        if (i < 8) begin
//            assign tx_line = data[i];
//            i = i+1;
//        end else begin
//            i = 0;
//            assign on = 0;
//        end
//    end
    
//endmodule

module tx(
    input wire baud_rate,       // This should be your baud rate clock
    input wire rst,       // Reset signal [cite: 66, 91]
    input wire btn,       // "Send" button [cite: 89]
    input wire [7:0] data, // Data from switches [cite: 88]
    output reg tx_line = 1'b1,   // UART idle level is HIGH
    output reg busy = 1'b0       // High when transmitting, low when IDLE
);

    // State Encoding
    localparam IDLE_STATE  = 2'b00;
    localparam START_STATE = 2'b01;
    localparam DATA_STATE  = 2'b10;
    localparam STOP_STATE  = 2'b11;

    reg [1:0] curr_state = IDLE_STATE;
    reg [3:0] i = 0; // Tracks which of the 8 bits we are sending
    reg [7:0] cache = 0;   // Buffer to hold data during transmission

    always @(posedge baud_rate or posedge rst) begin
        if (rst) begin
            curr_state <= IDLE_STATE;
            tx_line <= 1'b1; // Line high in IDLE [cite: 41]
            busy <= 1'b0;
            i <= 0;
        end else begin
            case (curr_state)
                IDLE_STATE: begin
                    tx_line <= 1'b1;
                    busy <= 1'b0;
                    if (btn) begin
                        cache <= data; // Capture switches into buffer [cite: 89]
                        curr_state <= START_STATE;
                    end
                end

                START_STATE: begin
                    busy <= 1'b1;
                    tx_line <= 1'b0; // Pull line LOW [cite: 26]
                    curr_state <= DATA_STATE;
                    i <= 0;
                end

                DATA_STATE: begin
                    tx_line <= cache[i]; // Send LSB first [cite: 27]
                    if (i == 7) begin
                        i <= 0;
                        curr_state <= STOP_STATE;
                    end else begin
                        i <= i + 1;
                    end
                end

                STOP_STATE: begin
                    tx_line <= 1'b1; // Pull line HIGH [cite: 27]
                    curr_state <= IDLE_STATE;
                end

                default: curr_state <= IDLE_STATE;
            endcase
        end
    end
endmodule
