`timescale 1ns / 1ps

module tx_tb();

    reg        baud_rate = 0;
    reg        rst       = 0;
    reg        btn       = 0;
    reg  [7:0] data      = 8'h00;
    wire       tx_line;
    wire       busy;

    // One baud tick = 2 time units (period = 4 units for easy reading)
    always #2 baud_rate = ~baud_rate;

    tx dut(
        .baud_rate (baud_rate),
        .rst       (rst),
        .btn       (btn),
        .data      (data),
        .tx_line   (tx_line),
        .busy      (busy)
    );

    // wait one full baud tick (one rising edge)
    task baud_tick;
        begin
            @(posedge baud_rate);
            #1; // small settle delay
        end
    endtask

    // press btn for exactly one baud tick 
    task press_btn;
        begin
            btn = 1;
            baud_tick;
            btn = 0;
        end
    endtask

    // check tx_line value and print PASS/FAIL
    task check_bit;
        input expected;
        input [63:0] bit_num;
        input [127:0] label;
       
    endtask

    integer i =0;

    initial begin
       

        // Initial reset
        rst = 0;
        baud_tick;
        baud_tick;
        rst = 0;
        baud_tick;

       

        // Test 1: Normal transmission of 0xA5 (10100101)

        
        data = 8'hA5;
        baud_tick;
        press_btn;

        baud_tick;
       

        begin : test1_data
            reg [7:0] expected_bits;
            expected_bits = 8'hA5;
            for (i = 0; i < 8; i = i + 1) begin
                baud_tick;
               
            end
        end

        baud_tick;
       

        baud_tick;
      
        
        
        data = 8'h0D;
        baud_tick;
        press_btn;

        baud_tick;
           baud_tick;
              baud_tick;
                 baud_tick;
                    baud_tick;
                       baud_tick;
                          baud_tick;

        // testT 2: Reset mid-transmission
        baud_tick;
        baud_tick;
        
        
        
        
        
        
        
        data = 8'h55;
        baud_tick; //wiat some time before senfing 
        press_btn;

        baud_tick;
        
        baud_tick;
        baud_tick;
        baud_tick;
        baud_tick;

     
        rst = 1;
        baud_tick;
        rst = 0;

      
      
        baud_tick;
        baud_tick;
        data = 8'h3C;
        baud_tick;
        baud_tick;
        press_btn;
        baud_tick;
      
        repeat(9) baud_tick;

        // test 3: switch (data) change during transmission

        baud_tick;
        baud_tick;
        
        data = 8'hA5;
        press_btn;

        baud_tick;
       

       
        data = 8'h3C;

        begin : test3_data
            reg [7:0] expected_bits;
            expected_bits = 8'hA5;   
            for (i = 0; i < 8; i = i + 1) begin
                baud_tick;
              
            end
        end

        baud_tick;
        check_bit(1'b1, 9, "STOP");

      
    end

  

endmodule
