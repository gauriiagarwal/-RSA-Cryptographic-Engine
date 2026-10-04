# 🔐 RSA Cryptographic Engine

> A modular **Verilog HDL** implementation of the RSA public-key cryptosystem (key generation → encryption → decryption), designed and simulated with **Xilinx ISE 14.7 (ISim)**.

**B.Tech Project · Electronics Engineering (VLSI Design and Technology) · Banasthali Vidyapith, Rajasthan · 2026**

---

## 📌 Table of Contents

1. [Overview](#-overview)
2. [Why RSA in Hardware?](#-why-rsa-in-hardware)
3. [Features](#-features)
4. [RSA in 60 Seconds](#-rsa-in-60-seconds)
5. [System Architecture](#-system-architecture)
6. [Module Descriptions](#-module-descriptions)
7. [Repository Structure](#-repository-structure)
8. [How to Run the Simulation](#-how-to-run-the-simulation)
9. [Simulation Results](#-simulation-results)
10. [Design Flow](#-design-flow)
11. [Scope & Limitations](#-scope--limitations)
12. [Applications](#-applications)
13. [Future Scope](#-future-scope)
14. [References](#-references)
15. [Team](#-team)

---

## 🔍 Overview

This project designs and verifies a hardware model of the **RSA** algorithm in Verilog. Every stage of the RSA process is implemented as an independent RTL module: key setup, modular exponentiation, encryption, and decryption. A top-level controller connects them so that a plaintext value goes in and both the **ciphertext** and the **recovered plaintext** come out.

The whole design is validated in simulation (Xilinx **ISim**, running inside an Oracle VM VirtualBox environment), so no physical FPGA board is required. A self-checking testbench verifies that decryption recovers the original message exactly.

## 💡 Why RSA in Hardware?

- RSA is a widely used **asymmetric** algorithm: a public key encrypts, a private key decrypts, and no secret has to be shared in advance.
- Its security rests on the difficulty of **factoring large integers**.
- Its step-by-step structure (modular exponentiation repeated bit by bit) maps naturally to a **modular, clocked hardware design**.
- Dedicated hardware is far faster and safer for key handling than a pure software implementation, which is why smart cards, HSMs, and IoT devices embed RSA engines.

## ✨ Features

- ✅ Modular RTL hierarchy with clean port interfaces (`key_gen`, `rsa_encrypt`, `rsa_decrypt`, `mod_exp`, `rsa_top`)
- ✅ **Right-to-left binary (square-and-multiply)** modular exponentiation, one exponent bit per clock cycle
- ✅ A single `mod_exp` design reused for both encryption and decryption
- ✅ Proper **start / done handshake** and a small controller FSM in the top module
- ✅ 32-bit intermediate products, so `(a × b) mod n` does not overflow for 16-bit moduli
- ✅ **Self-checking testbench** that tests every valid plaintext (0 to 54) against an independently computed ciphertext
- ✅ Waveform dump (`.vcd`) for debugging

## 🧮 RSA in 60 Seconds

**Key generation**

1. Choose two primes `p` and `q`
2. `n = p × q`
3. `φ(n) = (p − 1)(q − 1)`
4. Choose `e` with `1 < e < φ(n)` and `gcd(e, φ(n)) = 1`
5. Compute `d` such that `d · e ≡ 1 (mod φ(n))`

**Encrypt:** `C = M^e mod n` **Decrypt:** `M = C^d mod n` (the message must satisfy `M < n`)

**Modular exponentiation (hardware friendly)**

```
r = 1,  b = M mod n
for each bit of e, from LSB to MSB:
    if bit == 1:  r = (r × b) mod n
    b = (b × b) mod n
return r
```

This turns a huge exponentiation into at most `2 × (number of exponent bits)` modular multiplications.

## 🏗️ System Architecture

```
rsa_top  (top-level controller: IDLE → ENCRYPT → DECRYPT → FINISH)
├── key_gen       Key generation (n, e, d)
├── rsa_encrypt   C = M^e mod n
│   └── mod_exp   Modular exponentiation unit
└── rsa_decrypt   M = C^d mod n
    └── mod_exp   Modular exponentiation unit
```

**Data flow**

```
plaintext ──► rsa_encrypt ──► ciphertext ──► rsa_decrypt ──► decrypted_text
                  ▲                              ▲
             (e, n) public                  (d, n) private
                  └──────────── key_gen ─────────┘
```

## 📦 Module Descriptions

| Module | File | Purpose |
|---|---|---|
| `rsa_top` | `src/rsa_top.v` | Connects all modules; FSM sequences encrypt then decrypt; exposes `start` / `done` |
| `key_gen` | `src/key_gen.v` | Produces `n`, `e`, `d` (simulation keys: p = 5, q = 11) and a `key_valid` flag |
| `rsa_encrypt` | `src/rsa_encrypt.v` | Wraps `mod_exp` with the public key to compute `C = M^e mod n` |
| `rsa_decrypt` | `src/rsa_decrypt.v` | Wraps `mod_exp` with the private key to compute `M = C^d mod n` |
| `mod_exp` | `src/mod_exp.v` | Core square-and-multiply unit; one exponent bit per clock; `start` / `done` handshake |
| `rsa_tb` | `tb/rsa_tb.v` | Self-checking testbench (simulation only, not synthesizable) |

**Top-level interface**

| Port | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | Clock (testbench uses 100 MHz) |
| `rst` | in | 1 | Asynchronous reset, active high |
| `start` | in | 1 | One-cycle pulse to begin encrypt + decrypt |
| `plaintext` | in | 8 | Message value (must be `< n`) |
| `ciphertext` | out | 16 | `C = M^e mod n` |
| `decrypted_text` | out | 8 | Recovered message |
| `done` | out | 1 | HIGH when both outputs are valid |

## 📁 Repository Structure

```
.
├── src/
│   ├── rsa_top.v
│   ├── key_gen.v
│   ├── rsa_encrypt.v
│   ├── rsa_decrypt.v
│   └── mod_exp.v
├── tb/
│   └── rsa_tb.v
├── .gitignore
└── README.md
```

## ▶️ How to Run the Simulation

### Option A: Xilinx ISE 14.7 (ISim)

1. Create a new ISE project (any Spartan-6 / Artix-class device is fine for simulation).
2. Add all files from `src/` as **Design Sources** and `tb/rsa_tb.v` as a **Simulation Source**.
3. Set `rsa_tb` as the top module in the **Simulation** view.
4. Run **Simulate Behavioral Model** and look at the console for the PASS lines.
5. In the waveform window, watch `plaintext`, `ciphertext`, `decrypted_text`, and `done`.

### Option B: Icarus Verilog + GTKWave (free, any OS)

```bash
iverilog -o rsa_sim src/*.v tb/rsa_tb.v
vvp rsa_sim
gtkwave rsa_wave.vcd      # optional: view waveforms
```

**Expected output (end of log)**

```
M=0 : PASS  C=0  Decrypted=0
M=1 : PASS  C=1  Decrypted=1
M=2 : PASS  C=8  Decrypted=2
...
-------------------------------------------
ALL 55 TESTS PASSED
-------------------------------------------
```

## 📊 Simulation Results

**Key parameters**

| Parameter | Formula | Value |
|---|---|---|
| Prime `p` | n/a | 5 |
| Prime `q` | n/a | 11 |
| Modulus `n` | `p × q` | 55 |
| Euler's totient `φ(n)` | `(p−1)(q−1)` | 40 |
| Public exponent `e` | `gcd(e, 40) = 1` | 3 |
| Private exponent `d` | `3d ≡ 1 (mod 40)` | 27 |
| Check | `27 × 3 = 81 = 2·40 + 1` | ✓ |

**Sample runs**

| Plaintext `M` | Ciphertext `C = M³ mod 55` | Decrypted `C²⁷ mod 55` | Result |
|:---:|:---:|:---:|:---:|
| 2 | 8 | 2 | ✓ |
| 7 | 13 | 7 | ✓ |
| 20 | 25 | 20 | ✓ |
| 10 | 10 | 10 | ✓ |

> **Note:** for `M = 10` the ciphertext happens to equal the plaintext (10³ mod 55 = 10, a fixed point of this small key). It still decrypts correctly, but values like `M = 2` show the encryption effect more clearly.

**Waveform behaviour (ISim)**

- `rst = 1` at the start: all outputs are zero
- After reset is released, `key_gen` settles to `e = 3`, `d = 27`, `n = 55` and `key_valid` goes HIGH
- After `start`, `mod_exp` iterates once per clock; `done` goes HIGH when the result is ready
- `decrypted_text` matches `plaintext` exactly, confirming lossless end-to-end operation

## 🛠️ Design Flow

1. **Specification:** 8-bit characters, 16-bit modulus for simulation; define key constraints and I/O ports
2. **RTL coding:** each module in synthesizable Verilog with synchronous behaviour and asynchronous reset
3. **Testbench:** self-checking, exhaustive over all valid plaintexts
4. **Functional simulation:** ISim behavioral simulation, module by module and then end to end
5. **Waveform verification:** confirm `decrypted_text == plaintext`
6. **Synthesis (XST):** gate-level netlist and resource report
7. **Timing analysis:** critical path and maximum frequency review

## ⚠️ Scope & Limitations

This is an **educational, simulation-based** design:

- **Tiny keys.** `n = 55` (8/16-bit datapath) is for clear waveforms, not security. Real RSA needs 2048-bit or larger keys.
- **Fixed primes.** `key_gen` uses design-time parameters `p = 5, q = 11`. The LFSR prime generator, deterministic Miller-Rabin tester, and Extended Euclidean module described in the report's theory are the intended full key-generation pipeline and are **not** part of this RTL yet (see [Future Scope](#-future-scope)).
- **Textbook RSA.** No OAEP / PKCS#1 padding, so it is not safe against chosen-plaintext attacks.
- **Message size.** Each value must satisfy `M < n = 55`. ASCII characters such as `'A'` (65) do not fit with this key; they would with a realistic modulus.
- **Not pipelined.** One exponent bit is processed per clock cycle.
- **Simulation only.** Area, power, and latency on real silicon have not been measured.

## 🌐 Applications

- **Secure communication:** HTTPS, e-commerce, online banking
- **Digital signatures:** certificates, signed documents, software code-signing, secure email
- **Embedded security:** smart cards, ATMs, IoT devices, Hardware Security Modules (HSMs)

## 🔭 Future Scope

- [ ] Larger keys (512 / 1024 / 2048-bit) with a wider datapath
- [ ] Hardware prime generation: **LFSR** candidates + deterministic **Miller-Rabin** (witnesses `{2,3,5,7,11,13,17,19,23,29,31,37}`)
- [ ] **Extended Euclidean** module so `d` is computed in hardware
- [ ] **Montgomery modular multiplication** and a pipelined datapath for higher clock frequency
- [ ] Replace the LFSR with a **TRNG** (thermal noise / ring oscillators)
- [ ] Add **OAEP** padding
- [ ] Hybrid **RSA + AES** cryptosystem
- [ ] Deploy on a real FPGA board (Spartan-6 / Artix-7) for IoT / embedded security
- [ ] Explore post-quantum primitives (e.g., lattice-based schemes)

## 📚 References

1. R. L. Rivest, A. Shamir, L. Adleman, "A Method for Obtaining Digital Signatures and Public-Key Cryptosystems," *Communications of the ACM*, vol. 21, no. 2, pp. 120–126, 1978.
2. A. Menezes, P. van Oorschot, S. Vanstone, *Handbook of Applied Cryptography*, CRC Press, 1996.
3. S. Sharma et al., "Cryptosystem: An Implementation of RSA Using Verilog," Xilinx ISE, 2014.
4. M. Agrawal et al., "Implementation of RSA Encryption Algorithm on FPGA," *American Journal of Engineering Research*, vol. 4, no. 6, pp. 144–151, 2015.
5. P. L. Montgomery, "Modular Multiplication Without Trial Division," *Mathematics of Computation*, vol. 44, no. 170, pp. 519–521, 1985.
6. Cornell ECE 5760, "Prime Number Generator and RSA Encrypter/Decrypter," Final Project Report, 2011.
7. Xilinx Inc., *ISE Design Suite 14: Release Notes, Installation, and Licensing Guide*, 2012.

## 👥 Team

**Group No. 7**: B.Tech, Electronics Engineering (VLSI Design and Technology), VI Semester, 2023–27

- Gauri Agarwal
- Kritika Singh
- Raman
- Shivani Yadav
- Srashti Tyagi

**Under the guidance of:** Dr. Shalini Jharia, Assistant Professor, Department of Physical Sciences, Banasthali Vidyapith, Rajasthan

---

*Developed for academic purposes. The keys used here are intentionally tiny and must not be used to protect real data.*
