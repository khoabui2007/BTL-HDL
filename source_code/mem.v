module Memory (
    input clk,
    input rd,           // Tín hiệu Read
    input wr,           // Tín hiệu Write (Write Enable)
    input [31:0] address,
    inout [31:0] data ,
    input [4:0] debug_addr,     // Cổng mới
    output [31:0] debug_data
);

    reg [31:0] ram [0:31];
    reg [31:0] data_out;
    
    // Chỉ đẩy data ra Bus khi có tín hiệu Read
    assign data = (rd) ? data_out : 32'bz;
    assign debug_data = ram[debug_addr];
    always @(posedge clk) begin
        if (wr) begin
            ram[address[4:0]] <= data; // Chỉ ghi khi có tín hiệu wr = 1 (State STORE)
        end
        else if (rd) begin
            data_out <= ram[address[4:0]]; 
        end
    end
    
endmodule