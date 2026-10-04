// -----------------------------------------------------------------------------
// rsa_tb.v : Self-checking testbench for rsa_top  (simulation only)
// Keys: p=5, q=11 -> n=55, e=3, d=27.
// Tests every valid plaintext 0..54 (M < n), checking:
//   1) ciphertext     == M^3 mod 55   (independent expected value)
//   2) decrypted_text == M            (lossless round trip)
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps
module rsa_tb;
    reg         clk, rst, start;
    reg  [7:0]  plaintext;
    wire [15:0] ciphertext;
    wire [7:0]  decrypted_text;
    wire        done;

    integer i, errors, timeout, expected_c;

    rsa_top DUT (
        .clk(clk), .rst(rst), .start(start),
        .plaintext(plaintext),
        .ciphertext(ciphertext),
        .decrypted_text(decrypted_text),
        .done(done)
    );

    // 100 MHz clock (period = 10 ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // Waveform dump (open rsa_wave.vcd in any VCD viewer, e.g. GTKWave)
    initial begin
        $dumpfile("rsa_wave.vcd");
        $dumpvars(0, rsa_tb);
    end

    // Encrypt + decrypt one value and check the result
    task run_test;
        input [7:0] m;
        begin
            plaintext = m;
            @(negedge clk); start = 1'b1;     // one-cycle start pulse
            @(negedge clk); start = 1'b0;

            timeout = 0;
            while (!done && timeout < 200) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            expected_c = (m * m * m) % 55;

            if (timeout >= 200) begin
                $display("M=%0d : TIMEOUT (done never asserted)", m);
                errors = errors + 1;
            end else if (ciphertext !== expected_c[15:0] || decrypted_text !== m) begin
                $display("M=%0d : FAIL  C=%0d (expected %0d)  Decrypted=%0d",
                         m, ciphertext, expected_c, decrypted_text);
                errors = errors + 1;
            end else begin
                $display("M=%0d : PASS  C=%0d  Decrypted=%0d", m, ciphertext, decrypted_text);
            end
        end
    endtask

    initial begin
        errors = 0;
        start = 0; plaintext = 8'd0; rst = 1'b1;
        #25 rst = 1'b0;                 // release reset
        repeat (3) @(negedge clk);      // let key_gen load the keys

        for (i = 0; i < 55; i = i + 1)
            run_test(i[7:0]);

        $display("-------------------------------------------");
        if (errors == 0) $display("ALL 55 TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $display("-------------------------------------------");
        #50 $finish;
    end
endmodule
