
`timescale 1ns/1ps
`default_nettype none

module tb_poly1305_key_init;

    reg  [255:0] key;
    wire [4:0][25:0] r;
    wire [3:0][28:0] s;
    wire [3:0][31:0] pad;

    poly1305_key_init dut (
        .key (key),
        .r   (r),
        .s   (s),
        .pad (pad)
    );

    integer pass_cnt, fail_cnt;

    task check_r;
        input [31:0]  idx;
        input [25:0]  got, exp;
        begin
            if (got === exp) begin
                $display("[PASS] r[%0d]      got %07h  exp %07h", idx, got, exp);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] r[%0d]      got %07h  exp %07h  *** MISMATCH", idx, got, exp);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task check_s;
        input [31:0]  idx;
        input [28:0]  got, exp;
        begin
            if (got === exp) begin
                $display("[PASS] s[%0d]      got %08h  exp %08h", idx, got, exp);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] s[%0d]      got %08h  exp %08h  *** MISMATCH", idx, got, exp);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task check_pad;
        input [31:0]  idx;
        input [31:0]  got, exp;
        begin
            if (got === exp) begin
                $display("[PASS] pad[%0d]    got %08h  exp %08h", idx, got, exp);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] pad[%0d]    got %08h  exp %08h  *** MISMATCH", idx, got, exp);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task check_clamp;
        input [31:0]  idx;
        input [25:0]  val, zero_mask;
        begin
            if ((val & zero_mask) === 26'd0) begin
                $display("[PASS] clamp r[%0d] bits %07h = 0", idx, zero_mask);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] clamp r[%0d] bits %07h != 0  got %07h  *** MISMATCH",
                         idx, zero_mask, val & zero_mask);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    initial begin
$dumpfile("waves/wave_key_init.vcd");
$dumpvars(0, tb_poly1305_key_init);

        pass_cnt = 0;
        fail_cnt = 0;

        $display("--- Group 1: RFC 8439 key ---");
        key = {
            8'h1b, 8'hf5, 8'h49, 8'h41,
            8'haf, 8'hf6, 8'hbf, 8'h4a,
            8'hfd, 8'hb2, 8'h0d, 8'hfb,
            8'h8a, 8'h80, 8'h03, 8'h01,
            8'ha8, 8'h06, 8'hd5, 8'h42,
            8'hfe, 8'h52, 8'h44, 8'h7f,
            8'h33, 8'h6d, 8'h55, 8'h57,
            8'h78, 8'hbe, 8'hd6, 8'h85
        };
        #1;

        check_r(0, r[0], 26'h0bed685);
        check_r(1, r[1], 26'h3555502);
        check_r(2, r[2], 26'h047c036);
        check_r(3, r[3], 26'h1003949);
        check_r(4, r[4], 26'h00806d5);

        check_clamp(1, r[1], 26'h00000fc);
        check_clamp(2, r[2], 26'h0000300);
        check_clamp(3, r[3], 26'h000c000);
        check_clamp(4, r[4], 26'h3f00000);

        check_s(0, s[0], 29'h10aaa90a);
        check_s(1, s[1], 29'h0166c10e);
        check_s(2, s[2], 29'h05011e6d);
        check_s(3, s[3], 29'h00282229);

        check_pad(0, pad[0], 32'h8a800301);
        check_pad(1, pad[1], 32'hfdb20dfb);
        check_pad(2, pad[2], 32'haff6bf4a);
        check_pad(3, pad[3], 32'h1bf54941);

        $display("--- Group 2: all-zero key ---");
        key = 256'h0;
        #1;

        check_r(0, r[0], 26'h0);
        check_r(1, r[1], 26'h0);
        check_r(2, r[2], 26'h0);
        check_r(3, r[3], 26'h0);
        check_r(4, r[4], 26'h0);
        check_s(0, s[0], 29'h0);
        check_s(1, s[1], 29'h0);
        check_s(2, s[2], 29'h0);
        check_s(3, s[3], 29'h0);
        check_pad(0, pad[0], 32'h0);
        check_pad(3, pad[3], 32'h0);

        $display("--- Group 3: all-0xFF key ---");
        key = {256{1'b1}};
        #1;

        check_r(0, r[0], 26'h3ffffff);
        check_r(1, r[1], 26'h3ffff03);
        check_r(2, r[2], 26'h3ffc0ff);
        check_r(3, r[3], 26'h3f03fff);
        check_r(4, r[4], 26'h00fffff);

        check_clamp(1, r[1], 26'h00000fc);
        check_clamp(2, r[2], 26'h0000300);
        check_clamp(3, r[3], 26'h000c000);
        check_clamp(4, r[4], 26'h3f00000);

        check_s(0, s[0], 29'h13fffb0f);
        check_s(1, s[1], 29'h13fec4fb);
        check_s(2, s[2], 29'h13b13ffb);
        check_s(3, s[3], 29'h004ffffb);

        check_pad(0, pad[0], 32'hffffffff);
        check_pad(3, pad[3], 32'hffffffff);

        $display("--- Group 4: byte0=0x01 isolation ---");
        key = 256'h0;
        key[7:0] = 8'h01;
        #1;

        check_r(0, r[0], 26'h0000001);
        check_r(1, r[1], 26'h0);
        check_r(2, r[2], 26'h0);
        check_r(3, r[3], 26'h0);
        check_r(4, r[4], 26'h0);
        check_s(0, s[0], 29'h0);
        check_s(1, s[1], 29'h0);
        check_s(2, s[2], 29'h0);
        check_s(3, s[3], 29'h0);

        $display("--- Group 5: byte0=0x04 isolation ---");
        key = 256'h0;
        key[7:0] = 8'h04;
        #1;

        check_r(0, r[0], 26'h0000004);
        check_r(1, r[1], 26'h0);
        check_r(4, r[4], 26'h0);

        $display("--- Group 6: pad isolation (byte16=0x42) ---");
        key = 256'h0;
        key[135:128] = 8'h42;
        #1;

        check_r(0, r[0], 26'h0);
        check_r(4, r[4], 26'h0);
        check_pad(0, pad[0], 32'h00000042);
        check_pad(1, pad[1], 32'h0);
        check_pad(3, pad[3], 32'h0);

        $display("--- Group 7: pad isolation (byte31=0xFF) ---");
        key = 256'h0;
        key[255:248] = 8'hff;
        #1;

        check_pad(3, pad[3], 32'hff000000);
        check_pad(0, pad[0], 32'h0);
        check_r(0, r[0], 26'h0);

        $display("----------------------------------------");
        if (fail_cnt == 0)
            $display("All %0d checks passed.", pass_cnt);
        else
            $display("%0d / %0d checks FAILED.",
                     fail_cnt, pass_cnt + fail_cnt);
        $display("----------------------------------------");
        $finish;
    end

endmodule

`default_nettype wire
