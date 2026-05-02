`timescale 1ns / 1ps

module rx_tb;

  reg baud_rate;
  reg rst;
  reg rx_line;
  wire [7:0] data;

  rx uut (
    .baud_rate(baud_rate),
    .rst(rst),
    .rx_line(rx_line),
    .data(data)
  );

  always #5 baud_rate = ~baud_rate;

  //  valid 8N1 frame
  task send_uart_frame;
    input [7:0] byte_val;
    integer i;
    begin
      rx_line = 1'b0;            // start bit
      @(negedge baud_rate);

      for (i = 0; i < 8; i = i + 1) begin
        rx_line = byte_val[i];   // LSB first
        @(negedge baud_rate);
      end

      rx_line = 1'b1;            // stop bit
      @(negedge baud_rate);

      rx_line = 1'b1;            // idle
      @(posedge baud_rate);
    end
  endtask

  // frame with invalid stop bit (LOW instead of HIGH)
  task send_bad_stop_frame;
    input [7:0] byte_val;
    integer i;
    begin
      rx_line = 1'b0;            // start bit
      @(negedge baud_rate);

      for (i = 0; i < 8; i = i + 1) begin
        rx_line = byte_val[i];
        @(negedge baud_rate);
      end

      rx_line = 1'b0;            // invalid stop bit - should be HIGH
      @(negedge baud_rate);

      rx_line = 1'b1;            // return to idle
      @(posedge baud_rate);
    end
  endtask

  // frame with invalid start bit (line stays HIGH, never pulled LOW)
  task send_bad_start_frame;
    input [7:0] byte_val;
    integer i;
    begin
      rx_line = 1'b1;            // invalid start - line stays HIGH
      @(negedge baud_rate);

      for (i = 0; i < 8; i = i + 1) begin
        rx_line = byte_val[i];
        @(negedge baud_rate);
      end

      rx_line = 1'b1;
      @(posedge baud_rate);
    end
  endtask

  // short frame - only 4 bits then line goes idle
  task send_short_frame;
    input [3:0] nibble;
    integer i;
    begin
      rx_line = 1'b0;            // start bit
      @(negedge baud_rate);

      for (i = 0; i < 4; i = i + 1) begin
        rx_line = nibble[i];
        @(negedge baud_rate);
      end

      rx_line = 1'b1;            // premature stop - only 4 bits sent
      repeat(5) @(posedge baud_rate);
    end
  endtask




  initial begin
   

    baud_rate = 0;
    rst       = 0;
    rx_line   = 1'b1;    // UART idle is HIGH

    // reset
    rst = 1;
    repeat(2) @(posedge baud_rate);
    rst = 0;
    #10;

  

    // Test 1: normal frame 0xA5
    send_uart_frame(8'hA5);
    #10;

  

    // Test 2: normal frame 0x3C
    send_uart_frame(8'h3C);
    #10;

   
    // Test 3: invalid stop bit
   
    send_bad_stop_frame(8'h7E);
    #10;

   

    // Test 4: invalid start bit
    send_bad_start_frame(8'hFF);
    #1;

 

    // Test 5: reset during receive
    rx_line = 1'b0;         
    @(posedge baud_rate);
    rx_line = 1'b1;          
    @(posedge baud_rate);

    rst = 1;               
    @(posedge baud_rate);
    rst = 0;
    #10;


end

endmodule