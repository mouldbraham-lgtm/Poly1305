`default_nettype none

module poly1305_msg_unpack (
    input  wire [127:0] block,
    input  wire         is_final,
    output wire [4:0][25:0] m
);

    assign m[0] = block[25:0];
    assign m[1] = block[51:26];
    assign m[2] = block[77:52];
    assign m[3] = block[103:78];
    assign m[4] = {1'b0, ~is_final, block[127:104]};

endmodule

`default_nettype wire
