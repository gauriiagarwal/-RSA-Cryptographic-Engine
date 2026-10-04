// -----------------------------------------------------------------------------
// rsa_top.v : Top-level RSA engine
//
// Usage: put a value on `plaintext`, pulse `start` for one clock.
//        The controller encrypts, then decrypts the ciphertext. When `done`
//        goes HIGH, `ciphertext` and `decrypted_text` are valid.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps
module rsa_top (
    input             clk,
    input             rst,
    input             start,
    input      [7:0]  plaintext,
    output     [15:0] ciphertext,
    output     [7:0]  decrypted_text,
    output reg        done
);
    wire [7:0]  e, d;
    wire [15:0] n;
    wire        key_valid;

    reg         enc_start, dec_start;
    wire        enc_done, dec_done;

    key_gen KG (
        .clk(clk), .rst(rst),
        .e(e), .d(d), .n(n), .key_valid(key_valid)
    );

    rsa_encrypt ENC (
        .clk(clk), .rst(rst), .start(enc_start),
        .M(plaintext), .e(e), .n(n), .C(ciphertext), .done(enc_done)
    );

    rsa_decrypt DEC (
        .clk(clk), .rst(rst), .start(dec_start),
        .C(ciphertext), .d(d), .n(n), .M(decrypted_text), .done(dec_done)
    );

    // Simple controller: IDLE -> ENCRYPT -> DECRYPT -> FINISH
    localparam IDLE = 2'd0, ENCRYPT = 2'd1, DECRYPT = 2'd2, FINISH = 2'd3;
    reg [1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            enc_start <= 1'b0;
            dec_start <= 1'b0;
            done      <= 1'b0;
        end else begin
            enc_start <= 1'b0;   // start signals are single-cycle pulses
            dec_start <= 1'b0;
            case (state)
                IDLE: if (start && key_valid) begin
                    done      <= 1'b0;
                    enc_start <= 1'b1;
                    state     <= ENCRYPT;
                end
                // "&& !enc_start" ignores the stale done from a previous run
                ENCRYPT: if (enc_done && !enc_start) begin
                    dec_start <= 1'b1;
                    state     <= DECRYPT;
                end
                DECRYPT: if (dec_done && !dec_start) begin
                    done  <= 1'b1;
                    state <= FINISH;
                end
                FINISH: if (start) begin   // accept the next request
                    done      <= 1'b0;
                    enc_start <= 1'b1;
                    state     <= ENCRYPT;
                end
            endcase
        end
    end
endmodule
