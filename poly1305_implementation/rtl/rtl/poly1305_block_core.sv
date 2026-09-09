`default_nettype none
`timescale 1ns / 1ps

module poly1305_block_core (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [4:0][25:0] i_h,
    input  wire [4:0][25:0] i_m,
    input  wire [4:0][25:0] i_r,
    input  wire [4:0][28:0] i_s,

    input  wire        i_valid,
    output wire        i_ready,

    output reg  [4:0][25:0] o_h,
    output reg         o_valid
);

    assign i_ready = 1'b1;

    wire [4:0][26:0] hs;
    assign hs[0] = {1'b0, i_h[0]} + {1'b0, i_m[0]};
    assign hs[1] = {1'b0, i_h[1]} + {1'b0, i_m[1]};
    assign hs[2] = {1'b0, i_h[2]} + {1'b0, i_m[2]};
    assign hs[3] = {1'b0, i_h[3]} + {1'b0, i_m[3]};
    assign hs[4] = {1'b0, i_h[4]} + {1'b0, i_m[4]};

    wire [52:0] p_h0r0 = hs[0] * {27'b0, i_r[0]};
    wire [52:0] p_h1r0 = hs[1] * {27'b0, i_r[0]};
    wire [52:0] p_h2r0 = hs[2] * {27'b0, i_r[0]};
    wire [52:0] p_h3r0 = hs[3] * {27'b0, i_r[0]};
    wire [52:0] p_h4r0 = hs[4] * {27'b0, i_r[0]};

    wire [52:0] p_h0r1 = hs[0] * {27'b0, i_r[1]};
    wire [52:0] p_h1r1 = hs[1] * {27'b0, i_r[1]};
    wire [52:0] p_h2r1 = hs[2] * {27'b0, i_r[1]};
    wire [52:0] p_h3r1 = hs[3] * {27'b0, i_r[1]};

    wire [52:0] p_h0r2 = hs[0] * {27'b0, i_r[2]};
    wire [52:0] p_h1r2 = hs[1] * {27'b0, i_r[2]};
    wire [52:0] p_h2r2 = hs[2] * {27'b0, i_r[2]};
    wire [52:0] p_h3r2 = hs[3] * {27'b0, i_r[2]};

    wire [52:0] p_h0r3 = hs[0] * {27'b0, i_r[3]};
    wire [52:0] p_h1r3 = hs[1] * {27'b0, i_r[3]};
    wire [52:0] p_h2r3 = hs[2] * {27'b0, i_r[3]};

    wire [52:0] p_h0r4 = hs[0] * {27'b0, i_r[4]};
    wire [52:0] p_h1r4 = hs[1] * {27'b0, i_r[4]};

    wire [55:0] p_h1s4 = hs[1] * {27'b0, i_s[4]};
    wire [55:0] p_h2s4 = hs[2] * {27'b0, i_s[4]};
    wire [55:0] p_h3s4 = hs[3] * {27'b0, i_s[4]};
    wire [55:0] p_h4s4 = hs[4] * {27'b0, i_s[4]};

    wire [55:0] p_h2s3 = hs[2] * {27'b0, i_s[3]};
    wire [55:0] p_h3s3 = hs[3] * {27'b0, i_s[3]};
    wire [55:0] p_h4s3 = hs[4] * {27'b0, i_s[3]};

    wire [55:0] p_h1s2 = hs[1] * {27'b0, i_s[2]};
    wire [55:0] p_h3s2 = hs[3] * {27'b0, i_s[2]};
    wire [55:0] p_h4s2 = hs[4] * {27'b0, i_s[2]};

    wire [55:0] p_h4s1 = hs[4] * {27'b0, i_s[1]};


    wire [4:0][57:0] d;

    assign d[0] = {5'b0, p_h0r0}
                + {2'b0, p_h1s4}
                + {2'b0, p_h2s3}
                + {2'b0, p_h3s2}
                + {2'b0, p_h4s1};

    assign d[1] = {5'b0, p_h0r1}
                + {5'b0, p_h1r0}
                + {2'b0, p_h2s4}
                + {2'b0, p_h3s3}
                + {2'b0, p_h4s2};

    assign d[2] = {5'b0, p_h0r2}
                + {5'b0, p_h1r1}
                + {5'b0, p_h2r0}
                + {2'b0, p_h3s4}
                + {2'b0, p_h4s3};

    assign d[3] = {5'b0, p_h0r3}
                + {5'b0, p_h1r2}
                + {5'b0, p_h2r1}
                + {5'b0, p_h3r0}
                + {2'b0, p_h4s4};

    assign d[4] = {5'b0, p_h0r4}
                + {5'b0, p_h1r3}
                + {5'b0, p_h2r2}
                + {5'b0, p_h3r1}
                + {5'b0, p_h4r0};

    wire [31:0] c0 = d[0][57:26];
    wire [25:0] r0_h = d[0][25:0];

    wire [57:0] d1c = d[1] + {26'b0, c0};
    wire [31:0] c1  = d1c[57:26];
    wire [25:0] r1_h = d1c[25:0];

    wire [57:0] d2c = d[2] + {26'b0, c1};
    wire [31:0] c2  = d2c[57:26];
    wire [25:0] r2_h = d2c[25:0];

    wire [57:0] d3c = d[3] + {26'b0, c2};
    wire [31:0] c3  = d3c[57:26];
    wire [25:0] r3_h = d3c[25:0];

    wire [57:0] d4c = d[4] + {26'b0, c3};
    wire [31:0] c4  = d4c[57:26];
    wire [25:0] r4_h = d4c[25:0];


    wire [32:0] h0_wrap = {7'b0, r0_h} + {c4, 2'b0} + {2'b0, c4};

    wire [6:0]  c5  = h0_wrap[32:26];
    wire [25:0] f0  = h0_wrap[25:0];
    wire [25:0] f1  = r1_h + {19'b0, c5};

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            o_h[0]  <= 26'b0;
            o_h[1]  <= 26'b0;
            o_h[2]  <= 26'b0;
            o_h[3]  <= 26'b0;
            o_h[4]  <= 26'b0;
            o_valid <= 1'b0;
        end else begin
            o_valid <= i_valid;

            if (i_valid) begin
                o_h[0] <= f0;
                o_h[1] <= f1;
                o_h[2] <= r2_h;
                o_h[3] <= r3_h;
                o_h[4] <= r4_h;
            end
        end
    end

endmodule

`default_nettype wire
