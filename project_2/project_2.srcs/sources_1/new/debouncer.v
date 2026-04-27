module debouncer(
    input  wire btn,    // raw, asynchronous push-button
    input  wire clk,    // your main FPGA clock (e.g. 100 MHz)
    output reg  valid = 1'b0   // one-cycle pulse when btn goes from 0->1
);

  // ------------------------------------------------------------
  // 1) Divide the clock by 2^17 to create a slow 'tick'
  // ------------------------------------------------------------
  reg [16:0] clk_div = 17'd0;
  always @(posedge clk) begin
    clk_div <= clk_div + 1;
  end
  // tick once, one cycle long, when clk_div rolls over from 2^17-1 -> 0
  wire clk_tick = (clk_div == 17'd0);

  // ------------------------------------------------------------
  // 2) Two-flop synchronizer for the button
  // ------------------------------------------------------------
  reg [1:0] btn_sync = 2'b00;
  always @(posedge clk) begin
    btn_sync <= { btn_sync[0], btn };
  end

  // ------------------------------------------------------------
  // 3) Edge-detect at the slow tick
  // ------------------------------------------------------------
  reg last_level = 1'b0;
  always @(posedge clk) begin
    valid <= 1'b0;
    if (clk_tick) begin
      // when this slow tick happens, compare the newly-sampled button
      // to the last tick's sample.  If we went 0->1, fire a pulse.
      valid     <=  btn_sync[1] & ~last_level;
      last_level <= btn_sync[1];
    end
  end

endmodule
