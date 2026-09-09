`timescale 1ns/1ps

module u32to8 (
    input  wire [31:0] word_in,
    output wire [31:0] bytes_out
);

    assign bytes_out = { word_in[31:24],
                         word_in[23:16],
                         word_in[15: 8],
                         word_in[ 7: 0] };

endmodule
