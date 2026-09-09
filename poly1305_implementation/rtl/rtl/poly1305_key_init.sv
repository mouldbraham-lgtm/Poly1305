`timescale 1ns/1ps
`default_nettype none

module poly1305_key_init (
    input  wire [255:0] key,
    output wire [4:0][25:0] r,
    output wire [3:0][28:0] s,
    output wire [3:0][31:0] pad
);

    wire [31:0] w0 = key[ 31:  0];
    wire [31:0] w1 = key[ 55: 24];
    wire [31:0] w2 = key[ 79: 48];
    wire [31:0] w3 = key[103: 72];
    wire [31:0] w4 = key[127: 96];

    assign r[0] = w0[25:0]  & 26'h3ffffff;
    assign r[1] = w1[27:2]  & 26'h3ffff03;
    assign r[2] = w2[29:4]  & 26'h3ffc0ff;
    assign r[3] = w3[31:6]  & 26'h3f03fff;
    assign r[4] = {6'b0, w4[27:8]} & 26'h00fffff;

    assign s[0] = {r[1], 2'b00} + {3'b000, r[1]};
    assign s[1] = {r[2], 2'b00} + {3'b000, r[2]};
    assign s[2] = {r[3], 2'b00} + {3'b000, r[3]};
    assign s[3] = {r[4], 2'b00} + {3'b000, r[4]};

    assign pad[0] = key[159:128];
    assign pad[1] = key[191:160];
    assign pad[2] = key[223:192];
    assign pad[3] = key[255:224];

endmodule

`default_nettype wire
