`timescale 1ns/1ps

module tb_Controller;
    reg clk, rst;
    reg is_zero;
    reg [2:0] opcode;

    wire sel, rd, wr, ld_ir, ld_ac, inc_pc, ld_pc, data_e, halt;

    Controller dut (
        .clk(clk),
        .rst(rst),
        .is_zero(is_zero),
        .opcode(opcode),
        .sel(sel),
        .rd(rd),
        .wr(wr),
        .ld_ir(ld_ir),
        .ld_ac(ld_ac),
        .inc_pc(inc_pc),
        .ld_pc(ld_pc),
        .data_e(data_e),
        .halt(halt)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer error = 0;

    task check_halt;
    input expected;
    begin
        #1;
        if (halt !== expected) begin
            $display("[%0t] Error: halt expected=%b got=%b", $time, expected, halt);
            error = error + 1;
        end
    end
    endtask

    initial begin
        $display("CONTROLLER start test");

        rst = 1;
        opcode = 0;
        is_zero = 0;

        repeat (2) @(posedge clk);
        rst = 0;

        opcode = 3'b000;
        repeat (6) @(posedge clk);
        check_halt(1);

        opcode = 3'b001;
        is_zero = 1;
        repeat (6) @(posedge clk);

        if (inc_pc !== 1) begin
            $display("Error: SKZ failed to increment PC");
            error = error + 1;
        end

        opcode = 3'b111;
        repeat (6) @(posedge clk);

        if (ld_pc !== 1) begin
            $display("Error: JMP failed");
            error = error + 1;
        end

        if (error == 0)
            $display("CONTROLLER passed");
        else
            $display("CONTROLLER failed: %0d errors", error);

        $finish;
    end

endmodule