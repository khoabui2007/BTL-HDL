`timescale 1ns/1ps

module tb_ALU;
    reg [31:0] inA, inB;
    reg [2:0] opCode;
    reg [31:0] expected;

    wire [31:0] out;
    wire is_zero;

    ALU dut (
        .inA(inA),
        .inB(inB),
        .opCode(opCode),
        .out(out),
        .is_zero(is_zero)
    );

    integer seed = 999;

    task compute_expected;
    begin
        case (opCode)
            3'b010: expected = inA + inB;
            3'b011: expected = inA & inB;
            3'b100: expected = inA ^ inB;
            3'b101: expected = inB;
            default: expected = inA;
        endcase
    end
    endtask

    task check;
    begin
        #1;
        if (out !== expected)
            $display("[%0t] Error: op=%b expected=%h got=%h",
                $time, opCode, expected, out);
        else
            $display("[%0t] OK: op=%b out=%h", $time, opCode, out);
    end
    endtask

    initial begin
        $display("ALU test start");

        repeat (20) begin
            inA = $random(seed);
            inB = $random(seed);
            opCode = $random(seed) % 8;

            compute_expected();
            check();
        end

        inA = 0; inB = 0;
        repeat (8) begin
            opCode = opCode + 1;
            compute_expected();
            check();
        end

        $display("ALU test end");
        $finish;
    end

endmodule