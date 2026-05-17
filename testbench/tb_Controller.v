`timescale 1ns/1ps

module tb_Controller;
    reg clk, rst;
    reg is_zero;
    reg [2:0] opcode;

    wire sel, rd, wr, ld_ir, ld_ac, inc_pc, ld_pc, data_e, halt;

    Controller dut (
        .clk(clk), .rst(rst),
        .is_zero(is_zero), .opcode(opcode),
        .sel(sel), .rd(rd), .wr(wr), .ld_ir(ld_ir), .ld_ac(ld_ac),
        .inc_pc(inc_pc), .ld_pc(ld_pc), .data_e(data_e), .halt(halt)
    );

    // Tạo xung clock chu kỳ 10ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer error = 0;

    initial begin
        $display("--- CONTROLLER TEST START ---");

        // 1. Hệ thống Khởi tạo (Reset)
        rst = 1; opcode = 3'b000; is_zero = 0;
        @(negedge clk);
        rst = 0; // Nhả reset tại cạnh xuống

        // 2. TEST LỆNH ALU_OP (Ví dụ: LDA - 3'b101)
        // Chạy trọn vẹn 1 chu kỳ lệnh (8 trạng thái từ 0 -> 7)
        $display("[%0t ns] >> Testing ALU_OP (LDA)...", $time);
        opcode = 3'b101; 
        
        // Ta có thể dùng vòng lặp chờ đúng 8 chu kỳ clk để CPU xử lý xong
        repeat (8) @(posedge clk); 

        // 3. TEST LỆNH SKZ (3'b001) khi is_zero = 1
        $display("[%0t ns] >> Testing SKZ with is_zero=1...", $time);
        @(negedge clk); // Gán lệnh tại sườn xuống để FSM nạp đồng bộ từ trạng thái 0
        opcode = 3'b001;
        is_zero = 1;

        // Cho FSM chạy 6 chu kỳ để tiến từ trạng thái 0 đến trạng thái 6 (ALU_OP)
        repeat (6) @(posedge clk);
        #1; // Trễ nhẹ 1ns để tín hiệu tổ hợp xuất ra ổn định
        if (inc_pc !== 1) begin
            $display("Error: At ALU_OP state, SKZ failed to set inc_pc=1");
            error = error + 1;
        end else begin
            $display("[%0t ns] OK: SKZ passed (inc_pc = 1)", $time);
        end
        
        // Chạy nốt 2 chu kỳ còn lại của lệnh SKZ để hoàn thành vòng lặp FSM
        repeat (2) @(posedge clk);

        // 4. TEST LỆNH JMP (3'b111)
        $display("[%0t ns] >> Testing JMP...", $time);
        @(negedge clk);
        opcode = 3'b111;
        is_zero = 0;

        // Lệnh JMP bật ld_pc tại trạng thái 6 (ALU_OP) và trạng thái 7 (STORE)
        repeat (6) @(posedge clk);
        #1;
        if (ld_pc !== 1) begin
            $display("Error: JMP failed to set ld_pc=1");
            error = error + 1;
        end else begin
            $display("[%0t ns] OK: JMP passed (ld_pc = 1)", $time);
        end
        
        // Chạy nốt 2 chu kỳ còn lại
        repeat (2) @(posedge clk);

        // 5. TEST LỆNH HLT (3'b000) - Lệnh dừng máy phải test cuối cùng
        $display("[%0t ns] >> Testing HLT...", $time);
        @(negedge clk);
        opcode = 3'b000;

        // Lệnh HLT bật chân halt tại trạng thái 4 (OP_ADDR)
        repeat (4) @(posedge clk);
        #1;
        if (halt !== 1) begin
            $display("Error: HLT failed to set halt=1");
            error = error + 1;
        end else begin
            $display("[%0t ns] OK: HLT passed (halt = 1). CPU Freezed.", $time);
        end

        // --- KẾT LUẬN ---
        $display("-------------------------------------");
        if (error == 0)
            $display(">>> RESULT: CONTROLLER PASSED <<<");
        else
            $display(">>> RESULT: CONTROLLER FAILED WITH %0d ERRORS <<<", error);

        $finish;
    end

endmodule