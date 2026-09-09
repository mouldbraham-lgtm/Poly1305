`default_nettype none
`timescale 1ns / 1ps

module poly1305_top (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [255:0] i_key,
    input  wire         i_key_valid,

    input  wire [127:0] i_tdata,
    input  wire [15:0]  i_tkeep,
    input  wire         i_tvalid,
    input  wire         i_tlast,
    output wire         i_tready,

    output reg  [127:0] o_mac,
    output reg          o_mac_valid
);

    localparam [2:0]
        S_IDLE      = 3'd0,
        S_KEY_LOAD  = 3'd1,
        S_PROCESS   = 3'd2,
        S_WAIT_CORE = 3'd3,
        S_FINISH    = 3'd4,
        S_DONE      = 3'd5;

    reg [2:0] state, next_state;

    reg [255:0] key_reg;

    wire [4:0][25:0] r;
    wire [4:0][28:0] s;
    wire [3:0][31:0] pad_w;

    assign r[0] = key_reg[25:0]    & 26'h3ffffff;
    assign r[1] = key_reg[51:26]   & 26'h3ffff03;
    assign r[2] = key_reg[77:52]   & 26'h3ffc0ff;
    assign r[3] = key_reg[103:78]  & 26'h3f03fff;
    assign r[4] = key_reg[127:104] & 26'h00fffff;

    assign s[0] = {3'b0, r[0]} + {3'b0, r[0], 2'b0};
    assign s[1] = {3'b0, r[1]} + {3'b0, r[1], 2'b0};
    assign s[2] = {3'b0, r[2]} + {3'b0, r[2], 2'b0};
    assign s[3] = {3'b0, r[3]} + {3'b0, r[3], 2'b0};
    assign s[4] = {3'b0, r[4]} + {3'b0, r[4], 2'b0};

    assign pad_w[0] = key_reg[159:128];
    assign pad_w[1] = key_reg[191:160];
    assign pad_w[2] = key_reg[223:192];
    assign pad_w[3] = key_reg[255:224];

    reg [4:0][25:0] h;

    reg [127:0] block_buf;
    reg         is_final_buf;

    wire [15:0] pad_here;
    assign pad_here[0]  = ~i_tkeep[0];
    assign pad_here[1]  = ~i_tkeep[1]  & i_tkeep[0];
    assign pad_here[2]  = ~i_tkeep[2]  & i_tkeep[1];
    assign pad_here[3]  = ~i_tkeep[3]  & i_tkeep[2];
    assign pad_here[4]  = ~i_tkeep[4]  & i_tkeep[3];
    assign pad_here[5]  = ~i_tkeep[5]  & i_tkeep[4];
    assign pad_here[6]  = ~i_tkeep[6]  & i_tkeep[5];
    assign pad_here[7]  = ~i_tkeep[7]  & i_tkeep[6];
    assign pad_here[8]  = ~i_tkeep[8]  & i_tkeep[7];
    assign pad_here[9]  = ~i_tkeep[9]  & i_tkeep[8];
    assign pad_here[10] = ~i_tkeep[10] & i_tkeep[9];
    assign pad_here[11] = ~i_tkeep[11] & i_tkeep[10];
    assign pad_here[12] = ~i_tkeep[12] & i_tkeep[11];
    assign pad_here[13] = ~i_tkeep[13] & i_tkeep[12];
    assign pad_here[14] = ~i_tkeep[14] & i_tkeep[13];
    assign pad_here[15] = ~i_tkeep[15] & i_tkeep[14];

    wire [127:0] padded_block;
    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : g_pad
            assign padded_block[gi*8+7 : gi*8] =
                i_tkeep[gi]   ? i_tdata[gi*8+7 : gi*8] :
                pad_here[gi]  ? 8'h01 :
                                8'h00;
        end
    endgenerate

    wire is_final = i_tlast & (i_tkeep != 16'hffff);

    wire [4:0][25:0] m;

    poly1305_msg_unpack u_unpack (
        .block    (block_buf),
        .is_final (is_final_buf),
        .m        (m)
    );

    reg         core_valid_in;
    wire        core_ready;
    wire [4:0][25:0] core_h_out;
    wire        core_valid_out;

    poly1305_block_core u_core (
        .clk     (clk),
        .rst_n   (rst_n),
        .i_h     (h),
        .i_m     (m),
        .i_r     (r),
        .i_s     (s),
        .i_valid (core_valid_in),
        .i_ready (core_ready),
        .o_h     (core_h_out),
        .o_valid (core_valid_out)
    );

    wire [127:0] mac_comb;

    poly1305_finish u_finish (
        .h   (h),
        .pad (pad_w),
        .mac (mac_comb)
    );

    assign i_tready = (state == S_PROCESS) & core_ready;

    reg tlast_seen;

    always_comb begin
        next_state = state;
        case (state)
            S_IDLE:
                if (i_key_valid)        next_state = S_KEY_LOAD;
            S_KEY_LOAD:                 next_state = S_PROCESS;
            S_PROCESS:
                if (i_tvalid & i_tready) next_state = S_WAIT_CORE;
            S_WAIT_CORE:
                if (core_valid_out)
                    next_state = tlast_seen ? S_FINISH : S_PROCESS;
            S_FINISH:                   next_state = S_DONE;
            S_DONE:
                if (i_key_valid)        next_state = S_KEY_LOAD;
            default:                    next_state = S_IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            tlast_seen    <= 1'b0;
            key_reg       <= 256'b0;
            h[0]          <= 26'b0;
            h[1]          <= 26'b0;
            h[2]          <= 26'b0;
            h[3]          <= 26'b0;
            h[4]          <= 26'b0;
            block_buf     <= 128'b0;
            is_final_buf  <= 1'b0;
            core_valid_in <= 1'b0;
            o_mac         <= 128'b0;
            o_mac_valid   <= 1'b0;
        end else begin
            state         <= next_state;
            core_valid_in <= 1'b0;

            case (state)
                S_IDLE: begin
                    o_mac_valid <= 1'b0;
                    if (i_key_valid) begin
                        key_reg <= i_key;
                    end
                end

                S_KEY_LOAD: begin
                    h[0] <= 26'b0;
                    h[1] <= 26'b0;
                    h[2] <= 26'b0;
                    h[3] <= 26'b0;
                    h[4] <= 26'b0;
                    tlast_seen <= 1'b0;
                end

                S_PROCESS: begin
                    if (i_tvalid & i_tready) begin
                        block_buf     <= padded_block;
                        is_final_buf  <= is_final;
                        core_valid_in <= 1'b1;
                        if (i_tlast)
                            tlast_seen <= 1'b1;
                    end
                end

                S_WAIT_CORE: begin
                    if (core_valid_out) begin
                        h[0] <= core_h_out[0];
                        h[1] <= core_h_out[1];
                        h[2] <= core_h_out[2];
                        h[3] <= core_h_out[3];
                        h[4] <= core_h_out[4];
                    end
                end

                S_FINISH: begin
                    o_mac       <= mac_comb;
                    o_mac_valid <= 1'b1;
                end

                S_DONE: begin
                    if (i_key_valid) begin
                        key_reg     <= i_key;
                        o_mac_valid <= 1'b0;
                    end
                end

                default: ;
            endcase
        end
    end

endmodule

`default_nettype wire
