`timescale 1ns/1ps

module u8to32 (
    input  wire [31:0] bytes_in,
    output wire [31:0] word_out
);

    assign word_out = { bytes_in[31:24],
                        bytes_in[23:16],
                        bytes_in[15: 8],
                        bytes_in[ 7: 0] };

endmodule
