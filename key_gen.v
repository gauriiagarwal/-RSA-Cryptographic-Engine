// -----------------------------------------------------------------------------
// key_gen.v : RSA key generation (simulation version)
// Primes are fixed design-time parameters (p = 5, q = 11) so the core RSA
// datapath stays easy to read in waveforms.
//   n = p*q = 55, phi(n) = 40, e = 3 (gcd(3,40)=1), d = 27 (3*27 = 81 = 1 mod 40)
// To use other keys, change the parameters and keep:
//   gcd(E_VAL, (P-1)*(Q-1)) = 1  and  E_VAL*D_VAL = 1 (mod (P-1)*(Q-1))
// `key_valid` goes HIGH once the key registers are loaded.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps
module key_gen (
    input             clk,
    input             rst,
    output reg [7:0]  e,
    output reg [7:0]  d,
    output reg [15:0] n,
    output reg        key_valid
);
    parameter [7:0] P     = 8'd5;
    parameter [7:0] Q     = 8'd11;
    parameter [7:0] E_VAL = 8'd3;    // public exponent
    parameter [7:0] D_VAL = 8'd27;   // private exponent

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            n         <= 16'd0;
            e         <= 8'd0;
            d         <= 8'd0;
            key_valid <= 1'b0;
        end else begin
            n         <= P * Q;      // 55
            e         <= E_VAL;      // 3
            d         <= D_VAL;      // 27
            key_valid <= 1'b1;
        end
    end
endmodule
