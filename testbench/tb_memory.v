`timescale 1ns/1ps

module tb_memory;
    reg clk;
    reg mode;
    reg [31:0] address;
    reg [31:0] data_drv;
    reg [31:0] expected;
    wire [31:0] data;

    assign data = (mode == 0) ? data_drv : 32'bz;

    memory dut (
        .clk(clk),
        .mode(mode),
        .address(address),
        .data(data)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer seed = 123;

    task check;
    begin
        #1;
        if (data !== expected)
            $display("[%0t] Error: addr=%h expected=%h got=%h", $time, address, expected, data);
        else
            $display("[%0t] OK: addr=%h data=%h", $time, address, data);
    end
    endtask

    initial begin
        $display("MEMORY test start");

        address = 32'h00000004;
        data_drv = 32'hA5A5A5A5;
        mode = 0;

        @(posedge clk);

        mode = 1;
        expected = 32'hA5A5A5A5;

        @(posedge clk);
        check();

        address = 32'h00000FFC;
        data_drv = 32'hFFFFFFFF;
        mode = 0;

        @(posedge clk);

        mode = 1;
        expected = 32'hFFFFFFFF;

        @(posedge clk);
        check();

        repeat (10) begin
            address = $random(seed) & 32'h00000FFC;
            data_drv = $random(seed);
            mode = 0;

            @(posedge clk);

            mode = 1;
            expected = data_drv;

            @(posedge clk);
            check();
        end

        mode = 1;
        repeat (3) begin
            @(posedge clk);
            check();
        end

        $display("MEMORY test end");
        $finish;
    end

endmodule