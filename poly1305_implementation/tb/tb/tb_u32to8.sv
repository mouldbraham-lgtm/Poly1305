`timescale 1ns/1ps

module tb_u32to8;

    reg  [31:0] word_in;
    wire [31:0] bytes_out;

    u32to8 dut (
        .word_in   (word_in),
        .bytes_out (bytes_out)
    );

    integer pass_count;
    integer fail_count;

    task run_test;
        input integer    test_num;
        input [127:0]    desc;
        input [31:0]     word;
        input [7:0]      exp_b0, exp_b1, exp_b2, exp_b3;
        reg   [7:0]      got_b0, got_b1, got_b2, got_b3;
        begin
            word_in = word;
            #1;

            got_b0 = bytes_out[ 7: 0];
            got_b1 = bytes_out[15: 8];
            got_b2 = bytes_out[23:16];
            got_b3 = bytes_out[31:24];

            if (got_b0 === exp_b0 && got_b1 === exp_b1 &&
                got_b2 === exp_b2 && got_b3 === exp_b3) begin
                $display("[PASS] Test %0d : %s  word=%08h  bytes={%02h,%02h,%02h,%02h}",
                         test_num, desc, word,
                         got_b3, got_b2, got_b1, got_b0);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d : %s  word=%08h",
                         test_num, desc, word);
                $display("         got  bytes={%02h,%02h,%02h,%02h}",
                         got_b3, got_b2, got_b1, got_b0);
                $display("         exp  bytes={%02h,%02h,%02h,%02h}  <-- MISMATCH",
                         exp_b3, exp_b2, exp_b1, exp_b0);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waves/wave_u32to8.vcd");
        $dumpvars(0, tb_u32to8);

        pass_count = 0;
        fail_count = 0;

        run_test(1, "RFC key word 0     ",
                 32'h78be_d685,
                 8'h85, 8'hd6, 8'hbe, 8'h78);

        run_test(2, "RFC pad[0] word    ",
                 32'h8a80_0301,
                 8'h01, 8'h03, 8'h80, 8'h8a);

        run_test(3, "all-zero word      ",
                 32'h0000_0000,
                 8'h00, 8'h00, 8'h00, 8'h00);

        run_test(4, "all-ones word      ",
                 32'hffff_ffff,
                 8'hff, 8'hff, 8'hff, 8'hff);

        run_test(5, "LSB word bit only  ",
                 32'h0000_0001,
                 8'h01, 8'h00, 8'h00, 8'h00);

        run_test(6, "MSB word bit only  ",
                 32'h8000_0000,
                 8'h00, 8'h00, 8'h00, 8'h80);

        run_test(7, "word 04030201      ",
                 32'h0403_0201,
                 8'h01, 8'h02, 8'h03, 8'h04);

        run_test(8, "byte1 field = 0x02 ",
                 32'h0000_0200,
                 8'h00, 8'h02, 8'h00, 8'h00);

        run_test(9, "byte2 field = 0x03 ",
                 32'h0003_0000,
                 8'h00, 8'h00, 8'h03, 8'h00);

        run_test(10, "RFC key word 1     ",
                 32'h336d_5557,
                 8'h57, 8'h55, 8'h6d, 8'h33);

        $display("----------------------------------------");
        if (fail_count == 0)
            $display("All %0d tests passed.", pass_count);
        else
            $display("%0d/%0d tests FAILED.", fail_count, pass_count+fail_count);
        $display("----------------------------------------");

        $finish;
    end

endmodule
