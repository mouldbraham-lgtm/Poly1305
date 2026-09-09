
`default_nettype none
`timescale 1ns / 1ps

module tb_poly1305_block_core;

    localparam CLK_HALF = 5;
    reg clk = 0;
    always #CLK_HALF clk = ~clk;

    reg         rst_n   = 1'b0;
    reg  [4:0][25:0] i_h;
    reg  [4:0][25:0] i_m;
    reg  [4:0][25:0] i_r;
    reg  [4:0][28:0] i_s;
    reg              i_valid = 1'b0;
    wire             i_ready;
    wire [4:0][25:0] o_h;
    wire        o_valid;

    poly1305_block_core dut (
        .clk(clk), .rst_n(rst_n),
        .i_h(i_h), .i_m(i_m), .i_r(i_r), .i_s(i_s),
        .i_valid(i_valid), .i_ready(i_ready),
        .o_h(o_h), .o_valid(o_valid)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    localparam [25:0] R0=26'h0bed685; localparam [28:0] S0=29'h03ba3099;
    localparam [25:0] R1=26'h3555502; localparam [28:0] S1=29'h10aaa90a;
    localparam [25:0] R2=26'h047c036; localparam [28:0] S2=29'h0166c10e;
    localparam [25:0] R3=26'h1003949; localparam [28:0] S3=29'h05011e6d;
    localparam [25:0] R4=26'h00806d5; localparam [28:0] S4=29'h00282229;

    localparam [25:0] M1_0=26'h0797243,M1_1=26'h1dbdd1c,M1_2=26'h3061726,
                      M1_3=26'h18da5a1,M1_4=26'h16f4620;
    localparam [25:0] M2_0=26'h06d7572,M2_1=26'h0d95488,M2_2=26'h3261657,
                      M2_3=26'h081a18d,M2_4=26'h16f7247;

    localparam [25:0] EXP1_0=26'h29c83fc,EXP1_1=26'h37ae239,EXP1_2=26'h2e9147d,
                      EXP1_3=26'h2127592,EXP1_4=26'h2c88c77;
    localparam [25:0] EXP2_0=26'h04b30de,EXP2_1=26'h3ed3a8d,EXP2_2=26'h3fa7ccc,
                      EXP2_3=26'h08ec0cd,EXP2_4=26'h2d8adaf;

    task zero_inputs;
        integer k;
        begin
            for (k=0;k<5;k=k+1) begin
                i_h[k]=0;i_m[k]=0;i_r[k]=0;i_s[k]=0;
            end
            i_valid=0;
        end
    endtask

    task send_and_check;
        input [25:0] h0,h1,h2,h3,h4;
        input [25:0] m0,m1,m2,m3,m4;
        input [25:0] r0,r1,r2,r3,r4;
        input [28:0] s0,s1,s2,s3,s4;
        input [25:0] e0,e1,e2,e3,e4;
        input integer tc;
        input [255:0] name;
        begin
            @(negedge clk);
            i_h[0]=h0;i_h[1]=h1;i_h[2]=h2;i_h[3]=h3;i_h[4]=h4;
            i_m[0]=m0;i_m[1]=m1;i_m[2]=m2;i_m[3]=m3;i_m[4]=m4;
            i_r[0]=r0;i_r[1]=r1;i_r[2]=r2;i_r[3]=r3;i_r[4]=r4;
            i_s[0]=s0;i_s[1]=s1;i_s[2]=s2;i_s[3]=s3;i_s[4]=s4;
            i_valid=1;
            @(posedge clk); #1;
            i_valid=0;
            if (o_valid!==1'b1) begin
                $display("FAIL [TC%0d] %s -- o_valid not asserted",tc,name);
                fail_count=fail_count+1;
            end else if (o_h[0]===e0&&o_h[1]===e1&&o_h[2]===e2&&
                         o_h[3]===e3&&o_h[4]===e4) begin
                $display("PASS [TC%0d] %s",tc,name);
                pass_count=pass_count+1;
            end else begin
                $display("FAIL [TC%0d] %s -- wrong h output",tc,name);
                if(o_h[0]!==e0)$display("  h[0]: got %07x exp %07x",o_h[0],e0);
                if(o_h[1]!==e1)$display("  h[1]: got %07x exp %07x",o_h[1],e1);
                if(o_h[2]!==e2)$display("  h[2]: got %07x exp %07x",o_h[2],e2);
                if(o_h[3]!==e3)$display("  h[3]: got %07x exp %07x",o_h[3],e3);
                if(o_h[4]!==e4)$display("  h[4]: got %07x exp %07x",o_h[4],e4);
                fail_count=fail_count+1;
            end
        end
    endtask

    initial begin
        $dumpfile("waves/wave_block_core.vcd");
        $dumpvars(0, tb_poly1305_block_core);
    end

    initial begin
        $display("======================================================");
        $display("  poly1305_block_core testbench");
        $display("======================================================");

        zero_inputs;
        rst_n=0;
        @(posedge clk);#1;
        @(posedge clk);#1;

        if (o_valid===1'b0) begin
            $display("PASS [TC3] o_valid=0 during reset");
            pass_count=pass_count+1;
        end else begin
            $display("FAIL [TC3] o_valid should be 0, got %b",o_valid);
            fail_count=fail_count+1;
        end

        @(negedge clk); rst_n=1;
        @(posedge clk);#1;

        @(posedge clk);#1;
        @(posedge clk);#1;
        if (o_valid===1'b0) begin
            $display("PASS [TC4] o_valid stays 0 when i_valid=0");
            pass_count=pass_count+1;
        end else begin
            $display("FAIL [TC4] o_valid should stay 0, got %b",o_valid);
            fail_count=fail_count+1;
        end

        send_and_check(0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0, 0,0,0,0,0,
                       0,0,0,0,0, 5,"all-zero inputs");

        send_and_check(0,0,0,0,0,
                       M1_0,M1_1,M1_2,M1_3,M1_4,
                       R0,R1,R2,R3,R4, S0,S1,S2,S3,S4,
                       EXP1_0,EXP1_1,EXP1_2,EXP1_3,EXP1_4,
                       1,"RFC8439 block1 (h=0 + m1*r)");

        send_and_check(EXP1_0,EXP1_1,EXP1_2,EXP1_3,EXP1_4,
                       M2_0,M2_1,M2_2,M2_3,M2_4,
                       R0,R1,R2,R3,R4, S0,S1,S2,S3,S4,
                       EXP2_0,EXP2_1,EXP2_2,EXP2_3,EXP2_4,
                       2,"RFC8439 block2 (h1 + m2*r)");

        begin
            integer k; integer all_ok; all_ok=1;
            @(negedge clk);
            i_h[0]=0;i_h[1]=0;i_h[2]=0;i_h[3]=0;i_h[4]=0;
            i_m[0]=M1_0;i_m[1]=M1_1;i_m[2]=M1_2;i_m[3]=M1_3;i_m[4]=M1_4;
            i_r[0]=R0;i_r[1]=R1;i_r[2]=R2;i_r[3]=R3;i_r[4]=R4;
            i_s[0]=S0;i_s[1]=S1;i_s[2]=S2;i_s[3]=S3;i_s[4]=S4;
            i_valid=1;
            for (k=0;k<3;k=k+1) begin
                @(posedge clk);#1;
                if (o_valid!==1'b1||o_h[0]!==EXP1_0||o_h[1]!==EXP1_1||
                    o_h[2]!==EXP1_2||o_h[3]!==EXP1_3||o_h[4]!==EXP1_4)
                    all_ok=0;
            end
            @(negedge clk); i_valid=0;
            if (all_ok) begin
                $display("PASS [TC6] back-to-back valid -- consistent output");
                pass_count=pass_count+1;
            end else begin
                $display("FAIL [TC6] back-to-back -- wrong/missing output");
                fail_count=fail_count+1;
            end
        end

        if (i_ready===1'b1) begin
            $display("PASS [TC7] i_ready permanently asserted");
            pass_count=pass_count+1;
        end else begin
            $display("FAIL [TC7] i_ready should be 1");
            fail_count=fail_count+1;
        end

        $display("======================================================");
        $display("  Results: %0d passed, %0d failed",pass_count,fail_count);
        $display("======================================================");
        if (fail_count==0) $display("ALL TESTS PASSED");
        else               $display("SOME TESTS FAILED");
        $finish;
    end

endmodule

`default_nettype wire
