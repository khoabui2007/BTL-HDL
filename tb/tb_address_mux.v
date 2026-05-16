`timescale 1ns/1ps

module tb_address_mux;
    parameter WIDTH = 32;

    reg  [WIDTH-1:0] pc_addr;
    reg  [4:0]       ir_addr;
    reg              sel;
    reg  [WIDTH-1:0] expected;
    wire [WIDTH-1:0] mem_addr;

    Address_mux #(.WIDTH(WIDTH)) dut (
        .pc_addr(pc_addr),
        .ir_addr(ir_addr),
        .sel(sel),
        .mem_addr(mem_addr)
    );

    integer seed = 12345;

    function [WIDTH-1:0] ir_ext;
        input [4:0] addr;
        begin
            ir_ext = {{(WIDTH-5){1'b0}}, addr};
        end
    endfunction

    task update_expected;
    begin
        if (sel)
            expected = pc_addr;
        else
            expected = ir_ext(ir_addr);
    end
    endtask

    task check;
    begin
        #1;
        if (mem_addr !== expected)
            $display("[%0t] Error: sel=%b pc=%h ir=%h -> expected=%h got=%h",
                     $time, sel, pc_addr, ir_addr, expected, mem_addr);
        else
            $display("[%0t] OK: sel=%b mem_addr=%h",
                     $time, sel, mem_addr);
    end
    endtask

    initial begin
        $display("ADDRESS MUX test start");

        pc_addr = 32'd0;
        ir_addr = 5'd0;

        sel = 1; update_expected(); check();
        sel = 0; update_expected(); check();

        pc_addr = 32'hFFFFFFFF;
        ir_addr = 5'b11111;

        sel = 1; update_expected(); check();
        sel = 0; update_expected(); check();

        pc_addr = 32'h00000001;
        ir_addr = 5'b00001;

        sel = 1; update_expected(); check();
        sel = 0; update_expected(); check();

        pc_addr = 32'h7FFFFFFF;
        ir_addr = 5'b10000;

        sel = 1; update_expected(); check();
        sel = 0; update_expected(); check();

        pc_addr = 32'hA5A5A5A5;
        ir_addr = 5'b10101;

        repeat (4) begin
            sel = ~sel;
            update_expected();
            check();
        end

        repeat (20) begin
            pc_addr = $random(seed);
            ir_addr = $random(seed) & 5'h1F;
            sel     = $random(seed) % 2;

            update_expected();
            check();
        end

        sel = 1;
        repeat (5) begin
            pc_addr = $random(seed);
            ir_addr = $random(seed);
            update_expected();
            check();
        end

        sel = 0;
        repeat (5) begin
            pc_addr = $random(seed);
            ir_addr = $random(seed);
            update_expected();
            check();
        end

        pc_addr = 32'h12345678;
        ir_addr = 5'b01010;

        sel = 0;
        update_expected();
        check();

        sel = 1;
        #1 sel = 0;
        update_expected();
        check();

        repeat (10) begin
            sel = ~sel;
            pc_addr = $random(seed);
            ir_addr = $random(seed) & 5'h1F;

            update_expected();
            check();
        end

        #10;
        $display("ADDRESS MUX test end");
        $finish;
    end

endmodule