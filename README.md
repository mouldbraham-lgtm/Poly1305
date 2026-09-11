# Poly1305 Hardware Implementation

SystemVerilog implementation of the Poly1305 message authentication code (RFC 8439), developed as part of a master's thesis on hardware implementation of ChaCha20-Poly1305. This module was designed and verified independently before integration with the ChaCha20 core.

A Python reference model (`poly1305.py`) is included and was used to generate golden outputs for verifying the RTL.

## Repo structure

```
poly1305_implementation/
├── poly1305.py              # Python reference model (RFC 8439 algorithm)
├── rtl/rtl/
│   ├── u8to32.sv             # 4 bytes -> 32-bit word (little endian)
│   ├── u32to8.sv             # 32-bit word -> 4 bytes (little endian)
│   ├── poly1305_key_init.sv  # 256-bit key -> clamped r limbs + pad
│   ├── poly1305_msg_unpack.sv# 128-bit block -> five 26-bit limbs
│   ├── poly1305_block_core.sv# multiply-accumulate + carry reduction (critical path)
│   ├── poly1305_finish.sv    # final carry, mod p selection, pad addition
│   └── poly1305_top.sv       # top-level FSM + streaming interface, wires everything together
└── tb/tb/
    └── tb_*.sv               # one testbench per module above
```

Each RTL module has a matching testbench with the same name prefixed `tb_`.

## Module overview

The design follows the standard Poly1305 five-limb (26-bit) representation:

- **u8to32 / u32to8** – byte <-> word conversion helpers.
- **poly1305_key_init** – takes the 256-bit one-time key, clamps `r` per RFC 8439, and splits out `r[4:0]` and `pad[3:0]`.
- **poly1305_msg_unpack** – splits a 128-bit message block into the five 26-bit limbs (plus the "high bit" for full blocks).
- **poly1305_block_core** – the actual `h = (h + m) * r mod p` step. Fully combinational (5x5 multiply + carry chain), which is the bottleneck for max frequency.
- **poly1305_finish** – performs the final full carry propagation, does the `h >= p` check/subtract, and adds the pad to produce the 128-bit tag.
- **poly1305_top** – 6-state FSM (`IDLE -> KEY_LOAD -> PROCESS -> WAIT_CORE -> FINISH -> DONE`) that streams in data over an AXI-S-like interface (`i_tdata`, `i_tvalid`, `i_tlast`, `i_tready`) and outputs the 128-bit MAC (`o_mac`, `o_mac_valid`).

## Running the testbenches

Simulated with Icarus Verilog. From inside `rtl/rtl` and `tb/tb` (adjust paths as needed):

```bash
iverilog -g2012 -o sim.vvp rtl/rtl/poly1305_top.sv tb/tb/tb_poly1305_top.sv
vvp sim.vvp
```

Swap in the module/testbench pair you want to run (e.g. `poly1305_block_core.sv` + `tb_poly1305_block_core.sv` to test just the core in isolation).

Waveforms can be dumped with `$dumpfile` / `$dumpvars` in the testbenches and viewed with GTKWave.

## Python reference model

`poly1305.py` is a straight port of the RFC 8439 reference algorithm, used to cross-check RTL outputs bit-for-bit.

```bash
python3 poly1305.py
```

Runs against the RFC 8439 test vector:
- Key: `85:d6:be:78:57:55:6d:33:7f:44:52:fe:42:d5:06:a8:01:03:80:8a:fb:0d:b2:fd:4a:bf:f6:af:41:49:f5:1b`
- Message: `"Cryptographic Forum Research Group"`
- Expected tag: `a8:06:1d:c1:30:51:36:c6:c2:2b:8b:af:0c:01:27:a9`

Use this same vector when checking the RTL waveform output.

## Known limitations

- `poly1305_block_core` has no pipeline register between the multiply outputs and the carry-accumulate chain, which limits achievable clock frequency. Adding one pipeline stage there is the straightforward next step to improve Fmax, at the cost of one extra cycle per block processed.
- This module has not yet been integrated with the ChaCha20 core into the full AEAD top level — it's verified standalone against the RFC vector only.

## Status

All modules (`u8to32` through `poly1305_top`) are implemented and have passing testbenches against RFC 8439 vectors.
