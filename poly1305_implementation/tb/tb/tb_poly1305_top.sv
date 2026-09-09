
`default_nettype none
`timescale 1ns / 1ps

module tb_poly1305_top;

    localparam CLK_HALF = 5;
    reg clk = 0;
    always #CLK_HALF clk = ~clk;

    reg         rst_n      = 1'b0;
    reg [255:0] i_key      = 256'b0;
    reg         i_key_valid= 1'b0;
    reg [127:0] i_tdata    = 128'b0;
    reg [15:0]  i_tkeep    = 16'b0;
    reg         i_tvalid   = 1'b0;
    reg         i_tlast    = 1'b0;
    wire        i_tready;
    wire [127:0] o_mac;
    wire         o_mac_valid;

    poly1305_top dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .i_key       (i_key),
        .i_key_valid (i_key_valid),
        .i_tdata     (i_tdata),
        .i_tkeep     (i_tkeep),
        .i_tvalid    (i_tvalid),
        .i_tlast     (i_tlast),
        .i_tready    (i_tready),
        .o_mac       (o_mac),
        .o_mac_valid (o_mac_valid)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    localparam [255:0] RFC_KEY =
        256'h1bf54941aff6bf4afdb20dfb8a800301a806d542fe52447f336d555778bed685;

    localparam [127:0] RFC_TDATA1 =
        128'h6f4620636968706172676f7470797243;

    localparam [127:0] RFC_TDATA2 =
        128'h6f7247206863726165736552206d7572;

    localparam [127:0] RFC_TDATA3 =
        128'h00000000000000000000000000007075;
    localparam [15:0]  RFC_TKEEP3 = 16'h0003;

    localparam [127:0] RFC_MAC_EXP =
        128'ha927010caf8b2bc2c6365130c11d06a8;

    initial begin
        $dumpfile("waves/wave_top.vcd");
        $dumpvars(0, tb_poly1305_top);
    end

    task present_key;
        input [255:0] key;
        begin
            @(negedge clk);
            i_key       = key;
            i_key_valid = 1'b1;
            @(posedge clk); #1;
            @(negedge clk);
            i_key_valid = 1'b0;
        end
    endtask

    task send_beat;
        input [127:0] tdata;
        input [15:0]  tkeep;
        input         tlast;
        begin
            @(negedge clk);
            i_tdata  = tdata;
            i_tkeep  = tkeep;
            i_tlast  = tlast;
            i_tvalid = 1'b1;

            while (!i_tready) @(posedge clk);
            @(posedge clk); #1;
            @(negedge clk);
            i_tvalid = 1'b0;
            i_tlast  = 1'b0;
        end
    endtask

    task wait_and_check_mac;
        input [127:0] expected;
        input integer tc;
        input [255:0] name;
        integer timeout;
        begin
            timeout = 0;
            while (!o_mac_valid && timeout < 50) begin
                @(posedge clk); #1;
                timeout = timeout + 1;
            end
            if (timeout >= 50) begin
                $display("FAIL [TC%0d] %s — timeout waiting for o_mac_valid", tc, name);
                fail_count = fail_count + 1;
            end else if (o_mac === expected) begin
                $display("PASS [TC%0d] %s", tc, name);
                $display("       mac = %032x", o_mac);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL [TC%0d] %s — wrong MAC", tc, name);
                $display("       got = %032x", o_mac);
                $display("       exp = %032x", expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task wait_cycles;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $display("======================================================");
        $display("  poly1305_top testbench");
        $display("======================================================");

        rst_n = 1'b0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(negedge clk); rst_n = 1'b1;
        @(posedge clk); #1;

        $display("\n-- TC1: RFC 8439 full message (3 beats) --");

        present_key(RFC_KEY);
        wait_cycles(1);

        send_beat(RFC_TDATA1, 16'hffff, 1'b0);
        wait_cycles(1);

        send_beat(RFC_TDATA2, 16'hffff, 1'b0);
        wait_cycles(1);

        send_beat(RFC_TDATA3, RFC_TKEEP3, 1'b1);
        wait_cycles(2);

        wait_and_check_mac(RFC_MAC_EXP, 1, "RFC8439 full message");

        $display("\n-- TC2: Single-byte message 0x41 ('A') --");

        wait_cycles(2);
        present_key(RFC_KEY);
        wait_cycles(1);

        send_beat(128'h00000000000000000000000000000041,
                  16'h0001, 1'b1);
        wait_cycles(3);

        wait_and_check_mac(
            128'h2c86ae93a51e9ecb49ca0c5a81caffd0,
            2, "single-byte message 'A'"
        );

        $display("\n-- TC3: Exactly 16-byte message --");

        wait_cycles(2);
        present_key(RFC_KEY);
        wait_cycles(1);

        send_beat(128'h01010101010101010101010101010101,
                  16'hffff, 1'b1);
        wait_cycles(3);

        wait_and_check_mac(
            128'ha8825a0d4d6cb89ad5cf68a9efcb1b66,
            3, "16-byte message (one full block)"
        );

        $display("\n-- TC4: 32-byte message (two full blocks) --");

        wait_cycles(2);
        present_key(RFC_KEY);
        wait_cycles(1);

        send_beat(128'h01010101010101010101010101010101,
                  16'hffff, 1'b0);
        wait_cycles(1);
        send_beat(128'h02020202020202020202020202020202,
                  16'hffff, 1'b1);
        wait_cycles(3);

        wait_and_check_mac(
            128'h8f2241d839a2444a2c6d8e45402560cc,
            4, "32-byte message (two full blocks)"
        );

        $display("\n-- TC5: Re-key then compute same RFC message --");

        wait_cycles(2);
        present_key(RFC_KEY);
        wait_cycles(1);

        send_beat(RFC_TDATA1, 16'hffff, 1'b0);
        wait_cycles(1);
        send_beat(RFC_TDATA2, 16'hffff, 1'b0);
        wait_cycles(1);
        send_beat(RFC_TDATA3, RFC_TKEEP3, 1'b1);
        wait_cycles(2);

        wait_and_check_mac(RFC_MAC_EXP, 5, "RFC8439 after re-key (same result)");

        $display("\n-- TC6: Back-pressure: 3-cycle gap between beats --");

        wait_cycles(2);
        present_key(RFC_KEY);
        wait_cycles(1);

        send_beat(RFC_TDATA1, 16'hffff, 1'b0);
        wait_cycles(3);

        send_beat(RFC_TDATA2, 16'hffff, 1'b0);
        wait_cycles(3);

        send_beat(RFC_TDATA3, RFC_TKEEP3, 1'b1);
        wait_cycles(2);

        wait_and_check_mac(RFC_MAC_EXP, 6, "RFC8439 with back-pressure stalls");

        $display("\n-- TC7: o_mac_valid clears on re-key, 0 in PROCESS --");

        wait_cycles(1);
        begin
            reg ok;

            present_key(RFC_KEY);
            @(posedge clk); #1;
            ok = (o_mac_valid === 1'b0);
            @(posedge clk); #1;
            ok = ok & (o_mac_valid === 1'b0);
            if (ok) begin
                $display("PASS [TC7] o_mac_valid=0 after re-key and in PROCESS");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL [TC7] o_mac_valid should be 0, got %b", o_mac_valid);
                fail_count = fail_count + 1;
            end
        end

        @(negedge clk); i_tvalid=0; i_tkeep=0; i_tlast=0;

        $display("\n======================================================");
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
