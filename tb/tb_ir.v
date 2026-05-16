`timescale 1ns/1ps

module tb_ir;
    reg clk, rst, ld_ir;
    reg [31:0] data_in;
    reg [2:0] exp_opcode;
    reg [4:0] exp_addr;

    wire [2:0] opcode;
    wire [4:0] ir_addr;

    ir dut (
        .clk(clk),
        .rst(rst),
        .ld_ir(ld_ir),
        .data_in(data_in),
        .opcode(opcode),
        .ir_addr(ir_addr)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task check;
    begin
        #1;
        if (opcode !== exp_opcode || ir_addr !== exp_addr)
            $display("[%0t] Error: expected op=%b addr=%b got op=%b addr=%b",
                $time, exp_opcode, exp_addr, opcode, ir_addr);
        else
            $display("[%0t] OK: op=%b addr=%b", $time, opcode, ir_addr);
    end
    endtask

    initial begin
        $display("IR test start");

        rst = 1; ld_ir = 0;
        @(posedge clk);
        check();

        rst = 0;

        data_in = 32'b00000000_00000000_00000000_10101010;
        ld_ir = 1;

        exp_opcode = data_in[7:5];
        exp_addr   = data_in[4:0];

        @(posedge clk);
        ld_ir = 0;
        check();

        data_in = 32'hFFFFFFFF;
        @(posedge clk);
        check();

        repeat (10) begin
            data_in = $random;
            ld_ir = 1;

            exp_opcode = data_in[7:5];
            exp_addr   = data_in[4:0];

            @(posedge clk);
            ld_ir = 0;
            check();
        end

        $display("IR test end");
        $finish;
    end

endmodule