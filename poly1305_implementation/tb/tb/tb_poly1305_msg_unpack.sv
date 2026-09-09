
`default_nettype none
`timescale 1ns/1ps

module tb_poly1305_msg_unpack;

    reg  [127:0] block;
    reg          is_final;
    wire [4:0][25:0] m;

    poly1305_msg_unpack dut (
        .block    (block),
        .is_final (is_final),
        .m        (m)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [127:0] blk;
        input         fin;
        input [25:0]  exp0, exp1, exp2, exp3, exp4;
        input [63:0]  tc_num;
        input [255:0] tc_name;
        begin
            block    = blk;
            is_final = fin;
            #1;

            if (m[0] === exp0 && m[1] === exp1 && m[2] === exp2 &&
                m[3] === exp3 && m[4] === exp4) begin
                $display("PASS [TC%0d] %s", tc_num, tc_name);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL [TC%0d] %s", tc_num, tc_name);
                if (m[0] !== exp0)
                    $display("       m[0]: got %06x  exp %06x", m[0], exp0);
                if (m[1] !== exp1)
                    $display("       m[1]: got %06x  exp %06x", m[1], exp1);
                if (m[2] !== exp2)
                    $display("       m[2]: got %06x  exp %06x", m[2], exp2);
                if (m[3] !== exp3)
                    $display("       m[3]: got %06x  exp %06x", m[3], exp3);
                if (m[4] !== exp4)
                    $display("       m[4]: got %06x  exp %06x  (hibit in bit 24)",
                             m[4], exp4);
                fail_count = fail_count + 1;
            end
        end
    endtask

    function [127:0] pack_le;
        input [7:0] b0,  b1,  b2,  b3,
                    b4,  b5,  b6,  b7,
                    b8,  b9,  b10, b11,
                    b12, b13, b14, b15;
        begin
            pack_le = {b15, b14, b13, b12,
                       b11, b10, b9,  b8,
                       b7,  b6,  b5,  b4,
                       b3,  b2,  b1,  b0};
        end
    endfunction

    initial begin
        $dumpfile("waves/wave_msg_unpack.vcd");
        $dumpvars(0, tb_poly1305_msg_unpack);

        $display("======================================================");
        $display("  poly1305_msg_unpack testbench");
        $display("======================================================");

        check(
            pack_le(8'h43, 8'h72, 8'h79, 8'h70,
                    8'h74, 8'h6f, 8'h67, 8'h72,
                    8'h61, 8'h70, 8'h68, 8'h69,
                    8'h63, 8'h20, 8'h46, 8'h6f),
            1'b0,
            26'h797243, 26'h1dbdd1c, 26'h3061726,
            26'h18da5a1, 26'h16f4620,
            1, "RFC8439 block1 is_final=0"
        );

        check(
            pack_le(8'h72, 8'h75, 8'h6d, 8'h20,
                    8'h52, 8'h65, 8'h73, 8'h65,
                    8'h61, 8'h72, 8'h63, 8'h68,
                    8'h20, 8'h47, 8'h72, 8'h6f),
            1'b0,
            26'h6d7572, 26'hd95488, 26'h3261657,
            26'h81a18d, 26'h16f7247,
            2, "RFC8439 block2 is_final=0"
        );

        check(
            pack_le(8'h75, 8'h70, 8'h01, 8'h00,
                    8'h00, 8'h00, 8'h00, 8'h00,
                    8'h00, 8'h00, 8'h00, 8'h00,
                    8'h00, 8'h00, 8'h00, 8'h00),
            1'b1,
            26'h17075, 26'h0, 26'h0,
            26'h0, 26'h0,
            3, "RFC8439 block3 is_final=1 (partial, padded)"
        );

        check(
            128'h0,
            1'b0,
            26'h0, 26'h0, 26'h0, 26'h0, 26'h1000000,
            4, "zero block is_final=0 (hibit only)"
        );

        check(
            128'h0,
            1'b1,
            26'h0, 26'h0, 26'h0, 26'h0, 26'h0,
            5, "zero block is_final=1 (all zero)"
        );

        check(
            {128{1'b1}},
            1'b0,
            26'h3ffffff, 26'h3ffffff, 26'h3ffffff,
            26'h3ffffff, 26'h1ffffff,
            6, "all-ones block is_final=0"
        );

        check(
            pack_le(8'h43, 8'h72, 8'h79, 8'h70,
                    8'h74, 8'h6f, 8'h67, 8'h72,
                    8'h61, 8'h70, 8'h68, 8'h69,
                    8'h63, 8'h20, 8'h46, 8'h6f),
            1'b1,

            26'h797243, 26'h1dbdd1c, 26'h3061726,
            26'h18da5a1, 26'h6f4620,
            7, "RFC8439 block1 is_final=1 (hibit cleared)"
        );

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
