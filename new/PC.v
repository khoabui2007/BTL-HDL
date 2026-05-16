/*  Program Counter (PC)
Chức năng: Là bộ đếm trỏ tới dòng lệnh tiếp theo.
Kết nối: 
Đầu vào (Input): * 
    ir_addr (từ IR): Nạp địa chỉ mới nếu lệnh hiện tại là lệnh nhảy (JMP).
    inc_pc (từ Controller): Nhận chớp xung bằng 1 thì đếm tiến lên 1.   
    ld_pc (từ Controller): Nhận chớp xung bằng 1 thì nuốt cái ir_addr vào.
Đầu ra (Output):
    pc_addr 32-bit: Luôn xuất giá trị đếm hiện tại đưa thẳng đến cổng của khối MUX.
*/

module PC(
    input wire clk,
          wire rst,
    input wire [31:0]pc_in, 
          wire inc_pc, 
          wire ld_pc,
    output reg [31:0]pc_out
);
    always@(posedge clk) begin
        if (rst) begin
            pc_out <= 32'd0;
        end
        else if (inc_pc)begin
            pc_out <= pc_out + 1;
        end
        else if (ld_pc)begin
            pc_out<=pc_in;
        end
    end
    
endmodule 