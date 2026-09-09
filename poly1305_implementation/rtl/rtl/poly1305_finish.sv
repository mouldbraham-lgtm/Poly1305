`default_nettype none
`timescale 1ns / 1ps

module poly1305_finish (
    input  wire [4:0][25:0] h,
    input  wire [3:0][31:0] pad,
    output wire [127:0] mac
);

    localparam [25:0] MASK26 = 26'h3ffffff;

    wire [26:0] a1_h1  = {1'b0, h[1]};
    wire        a1_c1  = a1_h1[26];
    wire [25:0] a1_r1  = a1_h1[25:0];

    wire [26:0] a1_h2  = {1'b0, h[2]} + {26'b0, a1_c1};
    wire [25:0] a1_c2  = {25'b0, a1_h2[26]};
    wire [25:0] a1_r2  = a1_h2[25:0];

    wire [26:0] a1_h3  = {1'b0, h[3]} + {26'b0, a1_c2};
    wire [25:0] a1_c3  = {25'b0, a1_h3[26]};
    wire [25:0] a1_r3  = a1_h3[25:0];

    wire [26:0] a1_h4  = {1'b0, h[4]} + {26'b0, a1_c3};
    wire [25:0] a1_c4  = {25'b0, a1_h4[26]};
    wire [25:0] a1_r4  = a1_h4[25:0];

    wire [26:0] a1_h0w = {1'b0, h[0]} + {24'b0, a1_c4, a1_c4, 1'b0} + {26'b0, a1_c4};
    wire [25:0] a1_c0  = {25'b0, a1_h0w[26]};
    wire [25:0] a1_r0  = a1_h0w[25:0];

    wire [26:0] a1_h1b = {1'b0, a1_r1} + {26'b0, a1_c0};
    wire [25:0] p1_r0  = a1_r0;
    wire [25:0] p1_r1  = a1_h1b[25:0];
    wire [25:0] p1_r2  = a1_r2;
    wire [25:0] p1_r3  = a1_r3;
    wire [25:0] p1_r4  = a1_r4;

    wire [26:0] a2_h1  = {1'b0, p1_r1};
    wire [25:0] a2_c1  = {25'b0, a2_h1[26]};
    wire [25:0] a2_r1  = a2_h1[25:0];

    wire [26:0] a2_h2  = {1'b0, p1_r2} + {26'b0, a2_c1};
    wire [25:0] a2_c2  = {25'b0, a2_h2[26]};
    wire [25:0] a2_r2  = a2_h2[25:0];

    wire [26:0] a2_h3  = {1'b0, p1_r3} + {26'b0, a2_c2};
    wire [25:0] a2_c3  = {25'b0, a2_h3[26]};
    wire [25:0] a2_r3  = a2_h3[25:0];

    wire [26:0] a2_h4  = {1'b0, p1_r4} + {26'b0, a2_c3};
    wire [25:0] a2_c4  = {25'b0, a2_h4[26]};
    wire [25:0] a2_r4  = a2_h4[25:0];

    wire [26:0] a2_h0w = {1'b0, p1_r0} + {24'b0, a2_c4, a2_c4, 1'b0} + {26'b0, a2_c4};
    wire [25:0] a2_c0  = {25'b0, a2_h0w[26]};
    wire [25:0] a2_r0  = a2_h0w[25:0];

    wire [26:0] a2_h1b = {1'b0, a2_r1} + {26'b0, a2_c0};
    wire [25:0] p2_r0  = a2_r0;
    wire [25:0] p2_r1  = a2_h1b[25:0];
    wire [25:0] p2_r2  = a2_r2;
    wire [25:0] p2_r3  = a2_r3;
    wire [25:0] p2_r4  = a2_r4;

    wire [26:0] g0_raw = {1'b0, p2_r0} + 27'd5;
    wire        g0_c   = g0_raw[26];
    wire [25:0] g0     = g0_raw[25:0];

    wire [26:0] g1_raw = {1'b0, p2_r1} + {26'b0, g0_c};
    wire        g1_c   = g1_raw[26];
    wire [25:0] g1     = g1_raw[25:0];

    wire [26:0] g2_raw = {1'b0, p2_r2} + {26'b0, g1_c};
    wire        g2_c   = g2_raw[26];
    wire [25:0] g2     = g2_raw[25:0];

    wire [26:0] g3_raw = {1'b0, p2_r3} + {26'b0, g2_c};
    wire        g3_c   = g3_raw[26];
    wire [25:0] g3     = g3_raw[25:0];

    wire [26:0] g4_raw = {1'b0, p2_r4} + {26'b0, g3_c};
    wire        overflow = g4_raw[26];
    wire [25:0] g4       = g4_raw[25:0];

    wire [25:0] sel_mask = {26{overflow}};

    wire [25:0] fh0 = (p2_r0 & ~sel_mask) | (g0 & sel_mask);
    wire [25:0] fh1 = (p2_r1 & ~sel_mask) | (g1 & sel_mask);
    wire [25:0] fh2 = (p2_r2 & ~sel_mask) | (g2 & sel_mask);
    wire [25:0] fh3 = (p2_r3 & ~sel_mask) | (g3 & sel_mask);
    wire [25:0] fh4 = (p2_r4 & ~sel_mask) | (g4 & sel_mask);

    wire [31:0] w0 = {fh1[5:0],  fh0[25:0]};
    wire [31:0] w1 = {fh2[11:0], fh1[25:6]};
    wire [31:0] w2 = {fh3[17:0], fh2[25:12]};
    wire [31:0] w3 = {fh4[23:0], fh3[25:18]};

    wire [32:0] sum0 = {1'b0, w0} + {1'b0, pad[0]};
    wire [32:0] sum1 = {1'b0, w1} + {1'b0, pad[1]} + {32'b0, sum0[32]};
    wire [32:0] sum2 = {1'b0, w2} + {1'b0, pad[2]} + {32'b0, sum1[32]};
    wire [32:0] sum3 = {1'b0, w3} + {1'b0, pad[3]} + {32'b0, sum2[32]};

    assign mac = {sum3[31:0], sum2[31:0], sum1[31:0], sum0[31:0]};

endmodule

`default_nettype wire
