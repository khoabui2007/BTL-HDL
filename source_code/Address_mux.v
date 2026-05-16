module Address_mux #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] pc_addr,
    input  wire [4:0]       ir_addr,
    input  wire             sel,
    output wire [WIDTH-1:0] mem_addr
);

    wire [WIDTH-1:0] ir_addr_ext;
    assign ir_addr_ext = {{(WIDTH-5){1'b0}}, ir_addr};

    assign mem_addr = (sel) ? pc_addr : ir_addr_ext;

endmodule