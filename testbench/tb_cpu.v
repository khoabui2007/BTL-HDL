`timescale 1ns/1ps

module tb_cpu;
    reg clk, rst;
    reg [4:0] ram_addr;      // Cổng địa chỉ để soi RAM
    wire [31:0] out_value;   // Giá trị trả về từ cổng debug của CPU
    
    integer err = 0;

    // Kết nối với CPU (DUT)
    Bus_Path_Map dut (
        .clk(clk), 
        .rst(rst), 
        .data_addr(ram_addr), 
        .out_value(out_value)
    );

    // Tạo xung Clock 100MHz (Chu kỳ 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Hàm tạo mã máy (Instruction Encoder)
    function [31:0] instr;
        input [2:0] op;
        input [4:0] addr;
        instr = {24'd0, op, addr};
    endfunction

    // Task kiểm tra kết quả chuyên nghiệp
    task check;
        input [4:0] addr_to_check;
        input [31:0] actual_val;
        input [31:0] expected_val;
        begin
            if (actual_val !== expected_val) begin
                $display("  [FAIL] RAM[%0d]: Expected %d, Got %d", addr_to_check, expected_val, actual_val);
                err = err + 1;
            end else begin
                $display("  [OK]   RAM[%0d]: %d", addr_to_check, actual_val);
            end
        end
    endtask

initial begin
    $display("--- CPU TEST START ---");

    // 1. Khởi tạo hệ thống
    rst = 1;
    ram_addr = 0;
    #36.6; // Chờ reset một khoảng lẻ để tránh trùng mép xung clock
    rst = 0;
    $display("Time: %t | Reset Released", $time);

    // 2. Nạp dữ liệu vào RAM (Backdoor loading)
    dut.RAM.ram[10] = 5;
    dut.RAM.ram[11] = 3;
    dut.RAM.ram[12] = 32'd0;

    // 3. Nạp chương trình vào RAM
    dut.RAM.ram[0] = instr(3'b001, 12); // SKZ 12
    dut.RAM.ram[2] = instr(3'b101, 10); // LDA 10
    dut.RAM.ram[3] = instr(3'b010, 11); // ADD 11
    dut.RAM.ram[4] = instr(3'b100, 10); // XOR 10 (Kỳ vọng: 8 xor 5)
    dut.RAM.ram[5] = instr(3'b110, 12); // STO 12 (Kỳ vọng: 8 xor 5)
    dut.RAM.ram[6] = instr(3'b111, 9); // JMP 9
    dut.RAM.ram[9] = instr(3'b000, 0);  // HLT

    // 4. Vòng lặp chạy mô phỏng
    begin : simulation_block
        repeat (500) begin
            @(posedge clk);
            
            // Log trạng thái mỗi khi bắt đầu một chu kỳ lệnh mới (State 0)
            if (dut.CTRL.state == 3'd0) begin
                $display("Time: %t | PC: %d | Op: %b | AC: %d", 
                         $time, dut.Program_Counter.pc_out, dut.CTRL.opcode, dut.ACC.data_out);
            end

            // Thoát vòng lặp nếu phát hiện lệnh HALT
            if (dut.CTRL.halt) begin
                $display("Time: %t | HALT DETECTED!", $time);
                disable simulation_block; 
            end
        end
    end

    // 5. Kiểm tra kết quả sau khi HALT
    $display("\n--- FINAL RAM CHECK ---");
    
ram_addr = 5'd12; #1;
        check(ram_addr, out_value, 13); 

        // Kiểm tra các ô nhớ khác
        ram_addr = 5'd10; #1; check(ram_addr, out_value, 5);
        ram_addr = 5'd11; #1; check(ram_addr, out_value, 3);
    // 6. Tổng kết
    $display("----------------------------------");
    if (err == 0)
        $display(">>> SUCCESS: CPU PASSED ALL TESTS <<<");
    else
        $display(">>> FAILED: %0d errors <<<", err);

    $finish;
end     
endmodule