`timescale 1ns/1ps

module tb_ac;

    reg clk;
    reg rst;
    reg ld_ac;
    reg  [31:0] data_in;
    reg  [31:0] expected;
    integer seed = 123;
    integer error_count = 0;

    wire [31:0] data_out;

    Accumulator dut (
        .clk(clk),
        .rst(rst),
        .ld_ac(ld_ac),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Tạo xung Clock 10ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task tự động kiểm tra kết quả ổn định sau posedge clk 1ns
    task check;
    begin
        #1; // Trễ nhẹ để dữ liệu phần cứng kịp cập nhật ổn định
        if (data_out !== expected) begin
            $display("[%0t ns] ERROR: Expected=%h, Got=%h | rst=%b, ld_ac=%b", 
                     $time, expected, data_out, rst, ld_ac);
            error_count = error_count + 1;
        end else begin
            $display("[%0t ns] OK: AC=%h", $time, data_out);
        end
    end
    endtask

    // Kịch bản kiểm thử đồng bộ hoàn toàn
    initial begin
        $display("--- AC TEST START ---");

        // 1. Kiểm thử trạng thái khởi tạo (Reset)
        rst = 1; ld_ac = 0; data_in = 0; expected = 0;
        repeat (3) @(posedge clk);
        check(); // Sau 3 chu kỳ rst, AC phải bằng 0

        // Nhả reset tại sườn xuống để an toàn
        @(negedge clk);
        rst = 0;

        // 2. Test nạp dữ liệu cố định (Gán sườn xuống, ăn clk sườn lên)
        @(negedge clk);
        data_in = 32'd10;
        ld_ac   = 1;
        expected = 32'd10;
        
        @(posedge clk); // Mạch ăn dữ liệu tại đây
        check();

        // 3. Test tính năng giữ nguyên dữ liệu (Hold Value) khi ld_ac = 0
        // Dù dữ liệu ngoài bus (data_in) thay đổi ngẫu nhiên, AC không được đổi
        repeat (5) begin
            @(negedge clk);
            ld_ac = 0;
            data_in = $random(seed);
            // expected giữ nguyên là 10 (giá trị cũ)
            
            @(posedge clk);
            check();
        end

        // 4. Test nạp chuỗi dữ liệu liên tục (Sequential Load)
        // Bật ld_ac liên tục, mỗi chu kỳ nạp 1 số mới
        @(negedge clk);
        ld_ac = 1;

        data_in = 32'd1; expected = 32'd1;
        @(posedge clk); check();

        @(negedge clk);
        data_in = 32'd2; expected = 32'd2;
        @(posedge clk); check();

        @(negedge clk);
        data_in = 32'd3; expected = 32'd3;
        @(posedge clk); check();

        // 5. Test tắt ld_ac và thay đổi data_in (Đảm bảo AC giữ nguyên giá trị 3)
        @(negedge clk);
        ld_ac = 0;
        data_in = 32'h55;
        expected = 32'd3; 
        
        @(posedge clk); check();

        // 6. Test nạp lại giá trị mới ổn định (Bỏ qua các lệnh nhấp nháy #1 nhiễu phần cứng cũ)
        @(negedge clk);
        ld_ac = 1;
        data_in = 32'h55;
        expected = 32'h55;
        
        @(posedge clk); check();

        // 7. Test Ưu tiên Reset (Bật cả rst=1 và ld_ac=1, nạp data khác -> đầu ra phải ưu tiên về 0)
        @(negedge clk);
        rst = 1;
        ld_ac = 1;
        data_in = 32'hAAAA;
        expected = 0; // Ưu tiên reset luôn bằng 0

        @(posedge clk); check();

        // Nhả reset và tắt ld_ac
        @(negedge clk);
        rst = 0;
        ld_ac = 0;

        // 8. Stress test: Nạp ngẫu nhiên liên tục nhiều chu kỳ
        repeat (5) begin
            @(negedge clk);
            data_in = $random(seed);
            expected = data_in; // Kì vọng ăn theo dữ liệu mới vì bật ghi
            ld_ac = 1;

            @(posedge clk); check();
        end

        // 9. Cú chốt: Đưa về trạng thái an toàn
        @(negedge clk);
        ld_ac = 0;
        rst = 1;
        expected = 0;
        
        @(posedge clk); check();

        // --- TỔNG KẾT ---
        $display("-------------------------------------");
        if (error_count == 0)
            $display(">>> RESULT: ACCUMULATOR PASSED <<<");
        else
            $display(">>> RESULT: ACCUMULATOR FAILED WITH %0d ERRORS <<<", error_count);
            
        $display("--- AC TEST END ---");
        $finish;
    end

endmodule