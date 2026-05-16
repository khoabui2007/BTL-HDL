`timescale 1ns/1ps

module tb_ac;

    reg clk;
    reg rst;
    reg ld_ac;
    reg  [31:0] data_in;
    reg  [31:0] expected;
    reg  [31:0] hold_val;
    integer seed = 123;

    wire [31:0] data_out;

    ac dut (
        .clk(clk),
        .rst(rst),
        .ld_ac(ld_ac),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task check;
    begin
        #1;
        if (data_out !== expected)
            $display("[%0t] ERROR: exp=%h, got=%h", $time, expected, data_out);
        else
            $display("[%0t] OK: AC=%h", $time, data_out);
    end
    endtask

    initial begin
        $display("AC test start");

        rst = 1; ld_ac = 0; data_in = 0; expected = 0;
        repeat (3) @(posedge clk);
        check();

        #3 rst = 0;

        data_in = 32'd10;
        ld_ac   = 1;
        expected = 32'd10;
        @(posedge clk);
        ld_ac = 0;
        check();

        hold_val = data_out;
        expected = hold_val;

        repeat (5) begin
            @(posedge clk);
            data_in = $random(seed);
            ld_ac = 0;
            check();
        end

        ld_ac = 1;

        data_in = 1; expected = 1;
        @(posedge clk); check();

        data_in = 2; expected = 2;
        @(posedge clk); check();

        data_in = 3; expected = 3;
        @(posedge clk); check();

        ld_ac = 0;

        data_in = 32'h55;
        expected = 32'h55;

        ld_ac = 1;
        #1 ld_ac = 0;
        #1 ld_ac = 1;

        @(posedge clk);
        ld_ac = 0;
        check();

        @(posedge clk);
        rst = 1;
        ld_ac = 1;
        data_in = 32'hAAAA;
        expected = 0;

        @(posedge clk);
        check();

        rst = 0;
        ld_ac = 0;

        repeat (5) begin
            data_in = $random(seed);
            expected = data_in;
            ld_ac = 1;

            @(posedge clk);
            ld_ac = 0;
            check();
        end

        @(posedge clk);
        rst = 1;
        expected = 0;

        @(posedge clk);
        rst = 0;
        check();

        #20;
        $display("AC test end");
        $finish;
    end

endmodule