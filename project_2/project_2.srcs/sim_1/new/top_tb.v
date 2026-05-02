`timescale 1ns / 1ps
//INCORRECT was told need 2 diff tb's
module top_tb();

    reg         clk  = 1'b0;
    reg         btnC = 1'b0;   // reset
    reg         btnR = 1'b0;   // send
    reg  [7:0]  sw   = 8'h00;

    wire        tx_line;
    wire [7:0]  led;

    // Model the physical J1 -> L2 jumper wire on the Pmod header.
    wire        rx_line = tx_line;

    top dut(
        .clk     (clk),
        .btnL    (btnC),
        .btnR    (btnR),
        .sw      (sw),
        .rx_line (rx_line),
        .tx_line (tx_line),
        .led     (led)
    );

    // 100 MHz clock
    always #5 clk = ~clk;

    // Press btnR like a human would: hold for ~5 ms so the debouncer's
    // 2^17-cycle tick is guaranteed to see a 0 -> 1 edge.
    task press_send;
        begin
            $display("[%0t ns] pressing btnR", $time);
            btnR = 1'b1;
            #5_000_000;          // 5 ms hold
            btnR = 1'b0;
            $display("[%0t ns] released btnR", $time);
        end
    endtask

    // Same idea for the reset button - debouncer needs >1.31 ms to detect.
    task press_reset;
        begin
            $display("[%0t ns] pressing btnL (reset)", $time);
            btnL = 1'b1;
            #5_000_000;          // 5 ms hold
            btnL = 1'b0;
            $display("[%0t ns] released btnL", $time);
        end
    endtask

    // Wait for one full UART frame to complete plus a small margin.
    task wait_for_frame;
        begin
            #2_000_000;          // 2 ms (frame is ~1.04 ms)
        end
    endtask

    task check_leds;
        input [7:0] expected;
        begin
            if (led === expected)
                $display("[%0t ns] PASS  led=0x%02h matches sw=0x%02h",
                         $time, led, expected);
            else
                $display("[%0t ns] FAIL  led=0x%02h expected=0x%02h",
                         $time, led, expected);
        end
    endtask

    initial begin
        $display("=== UART loopback testbench ===");

        // Reset pulse - must be held long enough for the debouncer to fire.
        press_reset;
        #200_000;                // let things settle

        // ---- Test 1: send 0xA5 (10100101) ----
        sw = 8'hA5;
        #100_000;                // let switch value settle
        press_send;
        wait_for_frame;
        check_leds(8'hA5);

        // ---- Test 2: send 0x3C (00111100) ----
        sw = 8'h3C;
        #100_000;
        press_send;
        wait_for_frame;
        check_leds(8'h3C);

        // ---- Test 3: send 0xFF (all ones) ----
        sw = 8'hFF;
        #100_000;
        press_send;
        wait_for_frame;
        check_leds(8'hFF);

        $display("=== done ===");
        $finish;
    end

    // Print every transition on the wire and on the LEDs so you can scrub
    // the waveform / console and see what's happening.
    initial begin
        $monitor("[%0t ns] btnR=%b tx_line=%b rx_line=%b led=0x%02h",
                 $time, btnR, tx_line, rx_line, led);
    end

endmodule
