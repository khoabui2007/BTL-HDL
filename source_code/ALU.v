module ALU (
    input [31:0] inA , // accumulator
    input [31:0] inB, // bus
    input [2:0] opCode,
    output reg [31:0] out,
    output is_zero
);

    assign is_zero = ~|inA;
    
    localparam HLT = 3'b000, 
                SKZ =3'b001, 
                ADD =3'b010,
                AND =3'b011, 
                XOR =3'b100,
                LDA =3'b101,
                STO =3'b110, 
                JMP =3'b111;
    always @(*) begin   
        case (opCode)
            HLT:     out = inA;
            SKZ:     out = inA;
            ADD:     out = inA + inB;
            AND:     out = inA & inB;
            XOR:     out = inA ^ inB; 
            LDA:     out = inB;
            STO:     out = inA;
            JMP:     out = inA;            
            default: out = 32'b0;
        endcase
    end
endmodule