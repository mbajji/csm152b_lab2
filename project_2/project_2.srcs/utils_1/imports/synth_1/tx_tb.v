`timescale 1ns / 1ps
// =============================================================================
// TX Testbench
//
// Tests:
//   1. Normal transmission - verify start bit, 8 data bits LSB first, stop bit
//   2. Reset mid-transmission - verify tx_line goes HIGH and TX returns to IDLE
//   3. Switch change during transmission - verify old value is sent, not new one
// =============================================================================
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

    // -------------------------------------------------------------------------
    // Task: wait one full baud tick (one rising edge)
    // -------------------------------------------------------------------------
    task baud_tick;
        begin
            @(posedge baud_rate);
            #1; // small settle delay
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: press btn for exactly one baud tick (edge-detected in TX)
    // -------------------------------------------------------------------------
    task press_btn;
        begin
            btn = 1;
            baud_tick;
            btn = 0;
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: check tx_line value and print PASS/FAIL
    // -------------------------------------------------------------------------
    task check_bit;
        input expected;
        input [63:0] bit_num;
        input [127:0] label;
        begin
            if (tx_line === expected)
                $display("[%0t] PASS  bit%0d (%s): tx_line=%b", $time, bit_num, label, tx_line);
            else
                $display("[%0t] FAIL  bit%0d (%s): tx_line=%b expected=%b", $time, bit_num, label, tx_line, expected);
        end
    endtask

    integer i =0;

    initial begin
        $display("=== TX Testbench ===");
        $dumpfile("tx_tb.vcd");
        $dumpvars(0, tx_tb);

        // Initial reset
        rst = 0;
        baud_tick;
        baud_tick;
        rst = 0;
        baud_tick;

        // Verify idle line is HIGH before anything starts
        if (tx_line === 1'b1)
            $display("[%0t] PASS  idle: tx_line=1 (correct)", $time);
        else
            $display("[%0t] FAIL  idle: tx_line=%b expected=1", $time, tx_line);

        // =====================================================================
        // TEST 1: Normal transmission of 0xA5 (10100101)
        // Expected on wire LSB first: 1,0,1,0,0,1,0,1
        // Full frame: START(0), D0(1), D1(0), D2(1), D3(0), D4(0), D5(1), D6(0), D7(1), STOP(1)
        // =====================================================================
        $display("--- Test 1: normal transmission of 0xA5 ---");
        data = 8'hA5;
        baud_tick;
        press_btn;

        // START bit
        baud_tick;
        check_bit(1'b0, 0, "START");

        // Data bits D0..D7 of 0xA5 = 8'b10100101, LSB first = 1,0,1,0,0,1,0,1
        begin : test1_data
            reg [7:0] expected_bits;
            expected_bits = 8'hA5;
            for (i = 0; i < 4; i = i + 1) begin
                baud_tick;
                check_bit(expected_bits[i], i+1, "DATA");
            end
        end

        // STOP bit
        baud_tick;
        check_bit(1'b1, 9, "STOP");

        // Back to idle
        baud_tick;
        check_bit(1'b1, 10, "IDLE after stop");
        
        
        data = 8'h0D;
        baud_tick;
        press_btn;

        // START bit
        baud_tick;
           baud_tick;
              baud_tick;
                 baud_tick;
                    baud_tick;
                       baud_tick;
                          baud_tick;
        // =====================================================================
        // TEST 2: Reset mid-transmission
        // Send 0xFF, assert reset after the start bit and 2 data bits
        // Expected: tx_line goes HIGH immediately, TX returns to IDLE
        // =====================================================================
        baud_tick;
        baud_tick;
        
        
        
        
        
        /*
        
        $display("--- Test 2: reset mid-transmission ---");
        data = 8'h55;
        baud_tick; //wiat some time before senfing 
        press_btn;

        // START bit
        baud_tick;
        check_bit(1'b0, 0, "START");

        // Let 2 data bits clock out
        baud_tick;
        baud_tick;
        baud_tick;
        baud_tick;

        // Assert reset mid-frame
        $display("[%0t] asserting reset mid-frame", $time);
        rst = 1;
        baud_tick;
        rst = 0;

        // tx_line must be HIGH immediately after reset (idle level)
        if (tx_line === 1'b1)
            $display("[%0t] PASS  post-reset: tx_line=1 (aborted correctly)", $time);
        else
            $display("[%0t] FAIL  post-reset: tx_line=%b expected=1", $time, tx_line);

        // busy must be LOW
        if (busy === 1'b0)
            $display("[%0t] PASS  post-reset: busy=0", $time);
        else
            $display("[%0t] FAIL  post-reset: busy=%b expected=0", $time, busy);

        // Confirm TX is back in IDLE - a new send should work cleanly
        baud_tick;
        baud_tick;
        data = 8'h3C;
        baud_tick;
        baud_tick;
        press_btn;
        baud_tick;
        check_bit(1'b0, 0, "START after recovery");
        // Clock out remaining bits silently
        repeat(9) baud_tick;

        // =====================================================================
        // TEST 3: Switch (data) change during transmission
        // Send 0xA5, change data to 0x3C after the start bit
        // Expected: tx_line continues sending 0xA5 (latched at btn press)
        //           NOT 0x3C
        // =====================================================================
        baud_tick;
        baud_tick;
        $display("--- Test 3: data change mid-transmission ---");
        data = 8'hA5;
        press_btn;

        // START bit
        baud_tick;
        check_bit(1'b0, 0, "START");

        // Change switches after start bit is out
        $display("[%0t] changing data to 0x3C mid-frame", $time);
        data = 8'h3C;

        // D0..D7 should still be 0xA5 bits (1,0,1,0,0,1,0,1)
        begin : test3_data
            reg [7:0] expected_bits;
            expected_bits = 8'hA5;   // latched value, NOT 0x3C
            for (i = 0; i < 8; i = i + 1) begin
                baud_tick;
                if (tx_line === expected_bits[i])
                    $display("[%0t] PASS  D%0d: tx_line=%b (old value preserved)", $time, i, tx_line);
                else
                    $display("[%0t] FAIL  D%0d: tx_line=%b expected=%b (should be old value 0xA5[%0d])",
                             $time, i, tx_line, expected_bits[i], i);
            end
        end

        // STOP bit
        baud_tick;
        check_bit(1'b1, 9, "STOP");

        $display("=== TX done ===");
        $finish;
    end

    initial begin
        $monitor("[%0t] baud=%b rst=%b btn=%b data=0x%02h tx_line=%b busy=%b",
                 $time, baud_rate, rst, btn, data, tx_line, busy);
                 */
    end

endmodule