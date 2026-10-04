// -----------------------------------------------------------------------------
// rsa_encrypt.v : C = M^e mod n  (wraps one mod_exp unit)
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps
module rsa_encrypt (
    input             clk,
    input             rst,
    input             start,
    input      [7:0]  M,      // plaintext integer (must satisfy M < n)
    input      [7:0]  e,      // public exponent
    input      [15:0] n,      // modulus
    output     [15:0] C,      // ciphertext
    output            done
);
    mod_exp ME (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .base    ({8'b0, M}),
        .exp     ({8'b0, e}),
        .modulus (n),
        .result  (C),
        .done    (done)
    );
endmodule
