`timescale 1ns/1ps

module tb_memory();
    reg clk;
    reg rd;
    reg wr;
    reg [31:0] address;
    reg [4:0] debug_addr;
    
    reg [31:0] data_drv;     // Biến trung gian của TB để lái dữ liệu vào bus
    reg [31:0] expected;     // Giá trị kỳ vọng để đối chiếu
    reg tb_drive_en;         // Bật bằng 1 khi TB muốn ghi dữ liệu, bằng 0 khi muốn đọc
    
    wire [31:0] data;
    wire [31:0] debug_data;

    integer seed = 123;
    integer error_count = 0;
                reg [4:0] rand_addr;
            reg [31:0] rand_data;

    // Điều khiển Bus hai chiều (inout data)
    // Nếu tb_drive_en = 1 (TB đang ghi), đẩy data_drv ra bus data
    // Nếu tb_drive_en = 0 (TB đang đọc), thả nổi bus data (32'bz) để RAM đẩy dữ liệu ra
    assign data = (tb_drive_en) ? data_drv : 32'bz;

    // Kết nối chính xác với DUT mới
    Memory dut (
        .clk(clk),
        .rd(rd),
        .wr(wr),
        .address(address),
        .data(data),
        .debug_addr(debug_addr),
        .debug_data(debug_data)
    );

    // Tạo xung Clock 10ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task tự động kiểm tra kết quả tại sườn lên xung clock
    task check;
    begin
        #1; // Trễ nhẹ 1ns để dữ liệu RAM/Debug kịp cập nhật ra ngoài
        if (data !== expected) begin
            $display("[%0t ns] ERROR: At Addr=%h | Expected=%h, Got=%h", $time, address, expected, data);
            error_count = error_count + 1;
        end else begin
            $display("[%0t ns] OK: At Addr=%h | Data=%h", $time, address, data);
        end
    end
    endtask

    // Kịch bản kiểm thử đồng bộ hoàn toàn
    initial begin
        $display("--- MEMORY TEST START ---");

        // 1. Khởi tạo trạng thái ban đầu ổn định
        rd = 0; wr = 0; address = 0; debug_addr = 0;
        data_drv = 0; tb_drive_en = 0; expected = 0;
        @(posedge clk);

        // 2. TEST GHI DỮ LIỆU (Write Mode) vào ô nhớ 4
        $display("[%0t ns] >> Testing Write to Address 4...", $time);
        @(negedge clk);
        address = 32'h00000004;
        data_drv = 32'hA5A5A5A5;
        tb_drive_en = 1; // Testbench chiếm quyền lái bus dữ liệu
        wr = 1;          // Kích hoạt tín hiệu ghi vào RAM
        rd = 0;

        @(posedge clk); // Mạch thực hiện ghi tại cạnh lên này

        // 3. TEST ĐỌC DỮ LIỆU (Read Mode) từ ô nhớ 4 vừa ghi
        $display("[%0t ns] >> Testing Read from Address 4...", $time);
        @(negedge clk);
        wr = 0;          // Tắt tín hiệu ghi
        rd = 1;          // Kích hoạt tín hiệu đọc từ RAM
        tb_drive_en = 0; // Testbench thả nổi bus dữ liệu (Z) để RAM xuất dữ liệu ra
        expected = 32'hA5A5A5A5; // Giá trị kỳ vọng nhận được

        @(posedge clk); // RAM đẩy dữ liệu ra bus tại cạnh lên này
        check();

        // 4. TEST CỔNG DEBUG (Kiểm tra xem debug_addr đọc trực tiếp không phụ thuộc clk)
        $display("[%0t ns] >> Testing Debug Port at Addr 4...", $time);
        @(negedge clk);
        debug_addr = 5'd4; // Trỏ cổng debug vào ô nhớ số 4
        #1; // Cổng debug là mạch tổ hợp (assign), cập nhật ngay sau trễ mạch
        if (debug_data !== 32'hA5A5A5A5) begin
            $display("ERROR: Debug port failed! Expected A5A5A5A5, got %h", debug_data);
            error_count = error_count + 1;
        end else begin
            $display("OK: Debug port working! debug_data = %h", debug_data);
        end

        // 5. TEST GHI/ĐỌC ngẫu nhiên 10 chu kỳ (Stress test dữ liệu)
        $display("[%0t ns] >> Testing Random Write & Read sequences...", $time);
        repeat (10) begin

            
            rand_addr = $random(seed) % 32; // Giới hạn vùng nhớ từ 0 -> 31 ô
            rand_data = $random(seed);

            // Bước A: Ghi dữ liệu ngẫu nhiên
            @(negedge clk);
            address = {27'd0, rand_addr};
            data_drv = rand_data;
            tb_drive_en = 1;
            wr = 1; rd = 0;

            @(posedge clk); // Ăn clk ghi vào RAM

            // Bước B: Đọc lại dữ liệu đó ra để đối chiếu
            @(negedge clk);
            wr = 0; rd = 1;
            tb_drive_en = 0; // Thả nổi bus ngay để tránh báo sai lỗi
            expected = rand_data;

            @(posedge clk); // Ăn clk RAM xuất dữ liệu
            check();
        end

        // 6. TEST TRẠNG THÁI TRỞ KHÁNG CAO (Khi tắt cả rd và wr)
        $display("[%0t ns] >> Testing High-Impedance (Z) state...", $time);
        @(negedge clk);
        rd = 0; wr = 0;
        tb_drive_en = 0;
        
        #1; // Trễ nhẹ để bus xả về Z
        if (data !== 32'bz) begin
            $display("ERROR: Bus is not floating (Z) when rd=0 and wr=0! got %h", data);
            error_count = error_count + 1;
        end else begin
            $display("OK: Bus correctly floating at High-Z.");
        end

        // --- TỔNG KẾT BÁO CÁO ---
        $display("-------------------------------------");
        if (error_count == 0)
            $display(">>> RESULT: MEMORY MODULE PASSED <<<");
        else
            $display(">>> RESULT: MEMORY MODULE FAILED WITH %0d ERRORS <<<", error_count);
            
        $display("--- MEMORY TEST END ---");
        $finish;
    end

endmodule