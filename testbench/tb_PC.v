`timescale 1ns/1ps

module tb_PC;
    reg clk;
    reg rst;
    reg inc_pc;
    reg ld_pc;
    reg [31:0] pc_in;
    
    wire [31:0] pc_out;
    reg [31:0] expected;

    integer error_count = 0;
    integer seed = 12345;

    // Khởi tạo DUT
    PC dut (
        .clk(clk),
        .rst(rst),
        .inc_pc(inc_pc),
        .ld_pc(ld_pc),
        .pc_in(pc_in),
        .pc_out(pc_out)
    );

    // Tạo xung Clock chu kỳ 10ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task tự động cập nhật giá trị kỳ vọng dựa theo ĐÚNG độ ưu tiên của module PC
    task update_expected;
    begin
        if (rst)
            expected = 32'd0;
        else if (inc_pc)        // Ưu tiên 1: inc_pc (Khớp hoàn toàn với phần cứng)
            expected = expected + 1;
        else if (ld_pc)         // Ưu tiên 2: ld_pc
            expected = pc_in;
        // Nếu không bật chân nào, expected giữ nguyên giá trị cũ
    end
    endtask

    // Task kiểm tra kết quả tại cạnh lên của clock (sau khi mạch đã ổn định #1ns)
    task check;
    begin
        #1; // Trễ nhẹ để mạch cập nhật xong
        if (pc_out !== expected) begin
            $display("[%0t ns] Error: Expected=%h, Got=%h | rst=%b, inc=%b, ld=%b", 
                     $time, expected, pc_out, rst, inc_pc, ld_pc);
            error_count = error_count + 1;
        end else begin
            $display("[%0t ns] OK: PC=%h", $time, pc_out);
        end
    end
    endtask

    // Kịch bản kiểm thử (Chạy đồng bộ tại cạnh xuống của Clock)
    initial begin
        $display("--- PC TEST START ---");

        // Trạng thái ban đầu
        rst = 1; inc_pc = 0; ld_pc = 0; pc_in = 0; expected = 0;
        
        // Giữ reset trong 3 chu kỳ clock
        repeat (3) @(negedge clk);
        
        // Nhả reset
        rst = 0;
        @(negedge clk);

        // Test trường hợp nạp địa chỉ (Load PC)
        pc_in = 32'd100; ld_pc = 1;
        update_expected(); @(posedge clk); check();
        
        // Tắt chân Load, kiểm tra xem PC có giữ nguyên giá trị không
        @(negedge clk); ld_pc = 0;
        repeat (3) begin
            update_expected(); @(posedge clk); check();
            @(negedge clk);
        end

        // Test tăng địa chỉ liên tục (Increment PC)
        inc_pc = 1;
        repeat (5) begin
            update_expected(); @(posedge clk); check();
            @(negedge clk);
        end
        inc_pc = 0;

        // Test nạp địa chỉ mới giá trị lớn
        pc_in = 32'hFFFFFFFF; ld_pc = 1;
        update_expected(); @(posedge clk); check();
        
        // Test trường hợp đặc biệt: Bật CẢ HAI chân (inc_pc và ld_pc cùng bằng 1)
        // Hệ thống phải ưu tiên inc_pc (tăng từ FFFFFFFF lên 0)
        @(negedge clk);
        pc_in = 32'd55; ld_pc = 1; inc_pc = 1;
        update_expected(); @(posedge clk); check();

        // Test ngẫu nhiên 10 chu kỳ để ép xung (Stress test)
        repeat (10) begin
            @(negedge clk);
            inc_pc = $random(seed) % 2;
            ld_pc  = $random(seed) % 2;
            pc_in  = $random(seed);
            update_expected(); 
            @(posedge clk); check();
        end

        // Test kích hoạt lại Reset ngẫu nhiên
        @(negedge clk);
        rst = 1; inc_pc = 1; ld_pc = 1; pc_in = 32'hAAAA;
        update_expected(); @(posedge clk); check();

        #20;
        $display("-------------------------------------");
        if (error_count == 0)
            $display(">>> RESULT: PASS <<<");
        else
            $display(">>> RESULT: FAIL WITH %0d ERRORS <<<", error_count);
        $display("--- PC TEST END ---");
        $finish;
    end

endmodule