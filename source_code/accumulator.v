module Accumulator (
    input  wire        clk,
    input  wire        rst,
    input  wire        ld_ac,
    input  wire [31:0] data_in,

    output reg  [31:0] data_out
);

    always @(posedge clk) begin
        if (rst)
            data_out <= 32'd0;
        else if (ld_ac)
            data_out <= data_in;
    end

endmodule