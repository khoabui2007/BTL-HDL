`timescale 1ns/1ps

module tb_PC;
    reg clk;
    reg rst;
    reg inc_pc;
    reg ld_pc;
    reg inc_pc_d;
    reg ld_pc_d;
    reg [31:0] expected;
    reg [31:0] pc_in;
    reg [31:0] pc_in_d;
    wire [31:0] pc_out;

    integer error_count = 0;

    integer seed = 12345;

    PC dut (
        .clk(clk),
        .rst(rst),
        .inc_pc(inc_pc),
        .ld_pc(ld_pc),
        .pc_in(pc_in),
        .pc_out(pc_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task latch_inputs;
    begin
        inc_pc_d = inc_pc;
        ld_pc_d  = ld_pc;
        pc_in_d  = pc_in;
    end
    endtask

    task update_expected;
    begin
        if (rst)
            expected = 32'd0;
        else if (ld_pc_d)
            expected = pc_in_d;
        else if (inc_pc_d)
            expected = expected + 1;
    end
    endtask

    task check;
    begin
        #1;
        if (pc_out !== expected) begin
            $display("[%0t] Error: exp=%h, got=%h", $time, expected, pc_out);
            error_count = error_count + 1;
        end else begin
            $display("[%0t] OK: PC=%h", $time, pc_out);
        end
    end
    endtask

    task step;
    begin
        latch_inputs();
        @(posedge clk);
        update_expected();
        check();
    end
    endtask

    initial begin
        $display("PC test start");

        rst = 1;
        inc_pc = 0;
        ld_pc = 0;
        pc_in = 0;
        expected = 0;

        repeat (3) step();

        rst = 0;
        step();

        pc_in = 32'd100;
        ld_pc = 1;
        step();
        ld_pc = 0;

        repeat (3) step();

        inc_pc = 1;
        repeat (5) step();
        inc_pc = 0;

        inc_pc = 1;
        step();
        inc_pc = 0;
        step();

        pc_in = 32'd123;
        ld_pc = 1;
        step();

        ld_pc = 0;
        pc_in = 32'd999;
        step();

        ld_pc = 1;
        repeat (3) begin
            pc_in = $random(seed);
            step();
        end
        ld_pc = 0;

        pc_in = 32'd55;
        ld_pc = 1;
        inc_pc = 1;
        step();

        ld_pc = 0;
        inc_pc = 0;

        ld_pc = 1;

        pc_in = 0;              step();
        pc_in = 1;              step();
        pc_in = 32'h7FFFFFFF;   step();
        pc_in = 32'hFFFFFFFF;   step();

        ld_pc = 0;

        inc_pc = 1;
        step();
        inc_pc = 0;

        repeat (10) begin
            inc_pc = $random(seed) % 2;
            ld_pc  = $random(seed) % 2;
            pc_in  = $random(seed);
            step();
        end

        inc_pc = 0;
        ld_pc = 0;

        repeat (5) begin
            pc_in = $random(seed);
            step();
        end

        rst = 1;
        ld_pc = 1;
        inc_pc = 1;
        pc_in = 32'hAAAA;
        step();

        #3 rst = 0;
        step();

        ld_pc = 1;
        pc_in = 32'd777;
        #2 ld_pc = 0;
        step();

        inc_pc = 1;
        #2 inc_pc = 0;
        step();
        
        #20;

        if (error_count == 0)
            $display("Pass");
        else
            $display("Fail: %0d errors =====", error_count);

        $display("PC test end");
        $finish;
    end

endmodule