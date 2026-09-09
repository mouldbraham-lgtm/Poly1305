
`default_nettype none
`timescale 1ns / 1ps

module tb_poly1305_finish;

    reg  [4:0][25:0] h;
    reg  [3:0][31:0] pad;
    wire [127:0] mac;

    poly1305_finish dut (
        .h   (h),
        .pad (pad),
        .mac (mac)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    localparam [31:0] PAD0 = 32'h8a800301;
    localparam [31:0] PAD1 = 32'hfdb20dfb;
    localparam [31:0] PAD2 = 32'haff6bf4a;
    localparam [31:0] PAD3 = 32'h1bf54941;

    task check_mac;
        input [25:0] h0, h1, h2, h3, h4;
        input [31:0] p0, p1, p2, p3;
        input [127:0] expected;
        input integer tc;
        input [255:0] name;
        begin
            h[0]=h0; h[1]=h1; h[2]=h2; h[3]=h3; h[4]=h4;
            pad[0]=p0; pad[1]=p1; pad[2]=p2; pad[3]=p3;
            #1;

            if (mac === expected) begin
                $display("PASS [TC%0d] %s", tc, name);
                $display("       mac = %032x", mac);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL [TC%0d] %s", tc, name);
                $display("       got = %032x", mac);
                $display("       exp = %032x", expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waves/wave_finish.vcd");
        $dumpvars(0, tb_poly1305_finish);

        $display("======================================================");
        $display("  poly1305_finish testbench");
        $display("======================================================");

        check_mac(
            26'h29d03a7, 26'h110cd4d, 26'h2c77c88, 26'h32bfe51, 26'h28d31b7,
            PAD0, PAD1, PAD2, PAD3,
            128'ha927010caf8b2bc2c6365130c11d06a8,
            1, "RFC8439 full (3-block message)"
        );

        check_mac(
            26'h3fffffb, 26'h3ffffff, 26'h3ffffff, 26'h3ffffff, 26'h3ffffff,
            PAD0, PAD1, PAD2, PAD3,
            128'h1bf54941aff6bf4afdb20dfb8a800301,
            2, "h=2^130-5 (mod-p fires, h→0, MAC=pad)"
        );

        check_mac(
            26'b0, 26'b0, 26'b0, 26'b0, 26'b0,
            32'b0, 32'b0, 32'b0, 32'b0,
            128'h0,
            3, "h=0 pad=0 → MAC=0"
        );

        check_mac(
            26'h3fffffc, 26'h3ffffff, 26'h3ffffff, 26'h3ffffff, 26'h3ffffff,
            32'b0, 32'b0, 32'b0, 32'b0,
            128'h00000000000000000000000000000001,
            4, "h=2^130-4 (mod-p fires → h=1, pad=0)"
        );

        check_mac(
            26'h3ffffff, 26'h3ffffff, 26'h3ffffff, 26'h3ffffff, 26'h3ffffff,
            32'b0, 32'b0, 32'b0, 32'b0,
            128'h00000000000000000000000000000004,
            5, "h=all-max limbs (mod-p fires → h=4, pad=0)"
        );

        check_mac(
            26'h3ffffff, 26'h3ffffff, 26'h3ffffff, 26'h3ffffff, 26'h3ffffff,
            32'hffffffff, 32'hffffffff, 32'hffffffff, 32'hffffffff,
            128'h00000000000000000000000000000003,
            6, "h=all-max, pad=all-ones (pad carry chain)"
        );

        h[0]=26'b0; h[1]=26'b0; h[2]=26'b0; h[3]=26'b0; h[4]=26'b0;
        pad[0]=0; pad[1]=0; pad[2]=0; pad[3]=0;
        #1;
        begin
            reg ok;
            ok = (mac === 128'h0);
            h[0]=26'h3fffffc; h[1]=26'h3ffffff; h[2]=26'h3ffffff;
            h[3]=26'h3ffffff; h[4]=26'h3ffffff;
            #1;
            ok = ok && (mac === 128'h00000000000000000000000000000001);
            if (ok) begin
                $display("PASS [TC7] combinational update: output follows inputs instantly");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL [TC7] combinational update");
                $display("       mac after h=p+1: %032x  exp 00..01", mac);
                fail_count = fail_count + 1;
            end
        end

        $display("======================================================");
        $display("  Results: %0d passed, %0d failed", pass_count, fail_count);
        $display("======================================================");
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule

`default_nettype wire
