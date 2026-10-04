// -----------------------------------------------------------------------------
// mod_exp.v : Modular exponentiation unit  result = base^exp mod modulus
// Right-to-left binary (square-and-multiply), one exponent bit per clock cycle.
//
// Handshake:
//   - Pulse `start` for one clock while idle. Inputs are latched.
//   - `done` goes HIGH when `result` is valid and stays HIGH until next start.
// Requirement: modulus > 0 and base < modulus (for RSA: M < n).
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps
module mod_exp (
    input             clk,
    input             rst,
    input             start,
    input      [15:0] base,
    input      [15:0] exp,
    input      [15:0] modulus,
    output reg [15:0] result,
    output reg        done
);
    reg [15:0] b;      // current base (squared every iteration)
    reg [15:0] e;      // remaining exponent bits
    reg [15:0] r;      // running result
    reg        busy;

    // 32-bit products so that (r*b) never overflows for 16-bit moduli
    wire [31:0] rb = r * b;
    wire [31:0] bb = b * b;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 16'd0;
            done   <= 1'b0;
            b      <= 16'd0;
            e      <= 16'd0;
            r      <= 16'd0;
            busy   <= 1'b0;
        end else if (start && !busy) begin
            // latch inputs
            b    <= base % modulus;
            e    <= exp;
            r    <= 16'd1 % modulus;
            done <= 1'b0;
            busy <= 1'b1;
        end else if (busy) begin
            if (e != 16'd0) begin
                if (e[0])
                    r <= rb % modulus;   // multiply when current bit is 1
                b <= bb % modulus;       // always square the base
                e <= e >> 1;             // next exponent bit
            end else begin
                result <= r;             // all bits processed
                done   <= 1'b1;
                busy   <= 1'b0;
            end
        end
    end
endmodule
