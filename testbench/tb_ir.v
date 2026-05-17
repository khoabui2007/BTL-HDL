`timescale 1ns/1ps

module tb_ir;
    reg clk, rst, ld_ir;
    reg [31:0] data_in;
    reg [2:0] exp_opcode;
    reg [4:0] exp_addr;

    wire [2:0] opcode;
    wire [4:0] ir_addr;
    
    integer error_count = 0; // Biến đếm lỗi tổng quan

    Instruction_Register dut (
        .clk(clk),
        .rst(rst),
        .ld_ir(ld_ir),
        .data_in(data_in),
        .opcode(opcode),
        .ir_addr(ir_addr)
    );

    // Tạo xung Clock 10ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task kiểm tra kết quả tự động
    task check;
    begin
        #1; // Trễ 1ns sau cạnh lên clock để dữ liệu đầu ra kịp cập nhật ổn định
        if (opcode !== exp_opcode || ir_addr !== exp_addr) begin
            $display("[%0t ns] ERROR: Expected op=%b addr=%b | Got op=%b addr=%b",
                     $time, exp_opcode, exp_addr, opcode, ir_addr);
            error_count = error_count + 1;
        end else begin
            $display("[%0t ns] OK: op=%b addr=%b", $time, opcode, ir_addr);
        end
    end
    endtask

    // Kịch bản kiểm thử đồng bộ
    initial begin
        $display("--- IR TEST START ---");

        // 1. Kiểm thử trạng thái Khởi tạo (Reset)
        rst = 1; ld_ir = 0; data_in = 0;
        exp_opcode = 3'b000; // Kỳ vọng sau khi rst đầu ra phải về 0
        exp_addr   = 5'b00000;
        
        repeat (2) @(posedge clk); // Giữ reset 2 chu kỳ
        check(); // Kiểm tra đầu ra sau reset

        // Nhả reset tại cạnh xuống để an toàn
        @(negedge clk);
        rst = 0;

        // 2. Kiểm thử nạp dữ liệu cố định (LDA 10 chẳng hạn)
        data_in = 32'b00000000_00000000_00000000_10101010; // op=101, addr=01010
        ld_ir = 1;
        exp_opcode = data_in[7:5];
        exp_addr   = data_in[4:0];
        
        @(posedge clk); // Chờ cạnh lên để mạch nạp dữ liệu
        check();

        // 3. Kiểm thử tính năng Giữ dữ liệu (Khi ld_ir xuống 0, đổi dữ liệu ngoài xem IR có bị đổi theo không)
        @(negedge clk);
        ld_ir = 0;
        data_in = 32'hFFFFFFFF; // Thay đổi data_in ngẫu nhiên trên Bus
        // exp_opcode và exp_addr giữ nguyên giá trị cũ vì không nạp (ld_ir=0)
        
        @(posedge clk);
        check(); // Đầu ra phải giữ nguyên không đổi

        // 4. Kiểm thử ngẫu nhiên 10 chu kỳ liên tục (Stress test)
        repeat (10) begin
            @(negedge clk); // Thay đổi kích thích tại cạnh xuống của clock
            data_in = $random;
            ld_ir = 1;
            exp_opcode = data_in[7:5];
            exp_addr   = data_in[4:0];

            @(posedge clk); // Chờ mạch cập nhật tại cạnh lên
            check();
        end

        // 5. Tắt ghi và kiểm tra chu kỳ cuối
        @(negedge clk);
        ld_ir = 0;
        @(posedge clk);
        check();

        // --- TỔNG KẾT ---
        $display("-------------------------------------");
        if (error_count == 0)
            $display(">>> RESULT: PASS ALL TESTS <<<");
        else
            $display(">>> RESULT: FAIL WITH %0d ERRORS <<<", error_count);
            
        $display("--- IR TEST END ---");
        $finish;
    end

endmodule