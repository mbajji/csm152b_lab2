module top(
    input wire clk,      // Master Clock (100MHz) [cite: 83, 86]
    input wire btnL,      // Reset Button 
    input wire btnC,      // Send Button [cite: 86, 89]
    input wire [7:0] sw, // 8 Switches for data [cite: 86, 88]
    input wire rx_line,  // Physical GPIO Pin for receiving 
    output wire tx_line, // Physical GPIO Pin for transmitting [cite: 86, 89]
    output wire [7:0] led // 8 LEDs to show received data [cite: 86, 90]
    );

    wire baud_rate;
    wire [7:0] data;
    wire start_btn;
    wire reset_btn;
    wire busy_tx;
    reg  send_req = 1'b0;

    debouncer dR(.clk(clk),.btn(btnC),.valid(start_btn));
    debouncer dL(.clk(clk),.btn(btnL),.valid(reset_btn));

    // Latch the brief 1-cycle start_btn pulse (100 MHz domain) so it
    // survives until tx samples it on a baud_rate edge (~104 us later).
    // Cleared once tx asserts busy.
    always @(posedge clk) begin
        if (reset_btn)        send_req <= 1'b0;
        else if (start_btn)   send_req <= 1'b1;
        else if (busy_tx)     send_req <= 1'b0;
    end

    // 1. Clock Divider: Converts 100MHz to your Baud Rate [cite: 85]
    clkdiv c(
        .clk(clk),
        .baud_rate(baud_rate)
    );

    // 2. Transmitter: Sends data from switches [cite: 84, 89]
    tx t(
        .baud_rate(baud_rate),
        .rst(reset_btn),
        .btn(send_req),
        .data(sw),
        .tx_line(tx_line),
        .busy(busy_tx)
    );

    rx r(
        .baud_rate(baud_rate),
        .rst(reset_btn),
        .rx_line(tx_line),
        .data(data)
    );

    assign led = data;
endmodule