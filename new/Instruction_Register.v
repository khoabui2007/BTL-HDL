module Instruction_Register (
    input  wire        clk,
    input  wire        rst,
    input  wire        ld_ir,
    input  wire [31:0] data_in,

    output wire [2:0]  opcode,
    output wire [4:0]  ir_addr
);

    reg [31:0] instr;

    always @(posedge clk) begin
        if (rst)
            instr <= 32'd0;
        else if (ld_ir)
            instr <= data_in;
    end

    assign opcode  = instr[7:5];
    assign ir_addr = instr[4:0];

endmodule