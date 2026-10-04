// -----------------------------------------------------------------------------
// rsa_decrypt.v : M = C^d mod n  (wraps one mod_exp unit)
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps
module rsa_decrypt (
    input             clk,
    input             rst,
    input             start,
    input      [15:0] C,      // ciphertext
    input      [7:0]  d,      // private exponent
    input      [15:0] n,      // modulus
    output     [7:0]  M,      // recovered plaintext
    output            done
);
    wire [15:0] result_w;

    mod_exp MD (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .base    (C),
        .exp     ({8'b0, d}),
        .modulus (n),
        .result  (result_w),
        .done    (done)
    );

    assign M = result_w[7:0];   // plaintext < n fits in 8 bits for n = 55
endmodule
