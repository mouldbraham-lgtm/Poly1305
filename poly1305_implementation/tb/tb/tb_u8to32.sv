`timescale 1ns/1ps

module tb_u8to32;

    reg  [31:0] bytes_in;
    wire [31:0] word_out;

    u8to32 dut (
        .bytes_in (bytes_in),
        .word_out (word_out)
    );

    integer pass_count;
    integer fail_count;

    task run_test;
        input integer    test_num;
        input [127:0]    desc;
        input [7:0]      b0, b1, b2, b3;
        input [31:0]     expected;
        begin

            bytes_in = {b3, b2, b1, b0};

            #1;

            if (word_out === expected) begin
                $display("[PASS] Test %0d : %s  got %08h  exp %08h",
                         test_num, desc, word_out, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d : %s  got %08h  exp %08h  <-- MISMATCH",
                         test_num, desc, word_out, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waves/wave_u8to32.vcd");
        $dumpvars(0, tb_u8to32);

        pass_count = 0;
        fail_count = 0;

        run_test(1, "RFC key bytes 0-3  ",
                 8'h85, 8'hd6, 8'hbe, 8'h78,
                 32'h78be_d685);

        run_test(2, "RFC pad[0] (b16-19)",
                 8'h01, 8'h03, 8'h80, 8'h8a,
                 32'h8a80_0301);

        run_test(3, "all-zero bytes     ",
                 8'h00, 8'h00, 8'h00, 8'h00,
                 32'h0000_0000);

        run_test(4, "all-ones bytes     ",
                 8'hff, 8'hff, 8'hff, 8'hff,
                 32'hffff_ffff);

        run_test(5, "LSB of byte0 only  ",
                 8'h01, 8'h00, 8'h00, 8'h00,
                 32'h0000_0001);

        run_test(6, "MSB of byte3 only  ",
                 8'h00, 8'h00, 8'h00, 8'h80,
                 32'h8000_0000);

        run_test(7, "byte order 01020304",
                 8'h01, 8'h02, 8'h03, 8'h04,
                 32'h0403_0201);

        run_test(8, "byte1 only = 0x02  ",
                 8'h00, 8'h02, 8'h00, 8'h00,
                 32'h0000_0200);

        run_test(9, "byte2 only = 0x03  ",
                 8'h00, 8'h00, 8'h03, 8'h00,
                 32'h0003_0000);

        run_test(10, "RFC key bytes 4-7  ",
                 8'h57, 8'h55, 8'h6d, 8'h33,
                 32'h336d_5557);

        $display("----------------------------------------");
        if (fail_count == 0)
            $display("All %0d tests passed.", pass_count);
        else
            $display("%0d/%0d tests FAILED.", fail_count, pass_count+fail_count);
        $display("----------------------------------------");

        $finish;
    end

endmodule
