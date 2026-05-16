/*Controller FSM (Bộ điều khiển)
Đầu vào (Lắng nghe): Nhận opcode (biết lệnh gì) và is_zero (biết giá trị có bằng 0 không? để nhảy SKZ).
Đầu ra (Ra lệnh): Nó liên tục nhảy qua 8 trạng thái 
1 INST_ADDR,2 INST_FETCH,3 INST_LOAD,4 IDLE,5 OP_ADDR,6 OP_FETCH,7 ALU_OP,STORE. 
ở mỗi trạng thái nó bật/tắt tổ hợp các công tắc: sel, rd, wr, ld_ir, ld_ac, inc_pc, ld_pc, data_e, halt.
*/
module Controller(
    input   wire clk, wire rst,
    input   is_zero, 
            [2:0] opcode,
            
    output  reg sel,
            reg rd,
            reg wr,
            reg ld_ir,
            reg ld_ac,
            reg inc_pc,
            reg ld_pc,
            reg data_e,
            reg halt
);  
    //Khai bao cac state
    //localparam = const trong C++
    localparam INST_ADDR    =3'd0;
    localparam INST_FETCH   =3'd1;
    localparam INST_LOAD    =3'd2;
    localparam IDLE         =3'd3;
    localparam OP_ADDR      =3'd4;
    localparam OP_FETCH     =3'd5;
    localparam ALU_OP       =3'd6;
    localparam STORE        =3'd7;
    
    reg [2:0] state;
    // Encode OPCODE
    wire is_halt=   (opcode==3'b000);
    wire is_skz=    (opcode==3'b001); 
    wire is_sto=    (opcode==3'b110); 
    wire is_jmp=    (opcode==3'b111);
    wire is_aluOp= (opcode==3'b010||opcode==3'b011||opcode==3'b100||opcode==3'b101);
    
    //Chay state                        
    always @(posedge clk)begin          
        if (rst) begin                  
            state<=INST_ADDR;  
                     
        end else begin
            if (halt) begin 
                state<=state;               
            end else begin                      
                state<=state+1;             
            end
        end                            
    end
    
   //xuất 
    always @(*) begin
    //Tránh Latch  
       sel=0; 
       rd=0;     
       wr=0;     
       ld_ir=0;  
       ld_ac=0;  
       inc_pc=0;
       ld_pc=0;
       data_e=0;
       halt=0;

       case(state)
            INST_ADDR: begin 
                sel=1;     
            end 
            
            INST_FETCH: begin
                sel=1; 
                rd=1;
            end
          
            INST_LOAD : begin
                sel=1;
                rd=1;
                ld_ir=1;
            end         
            
            IDLE      : begin
                sel   = 1;
                rd    = 1;
                ld_ir = 1;
            end
            
            OP_ADDR: begin
                sel = 0;
                if (is_halt) halt = 1; // Dừng máy nếu là lệnh HLT
                if (!is_halt) inc_pc = 1;
            end

            OP_FETCH: begin
                sel = 0;
                if (is_aluOp) rd = 1;
            end

            ALU_OP: begin
                sel = 0;
                if (is_aluOp) rd = 1;
                if (is_skz && is_zero) inc_pc = 1; // Nhảy cóc lệnh tiếp theo
                if (is_jmp) ld_pc = 1;             // Nạp địa chỉ nhảy
                if (is_sto) data_e = 1;            // Mở cổng đẩy data ra Bus
            end

            STORE: begin
                sel = 0;
                if (is_aluOp) begin
                    rd = 1;
                    ld_ac = 1; // Lưu kết quả vào Accumulator
                end
                if (is_jmp) ld_pc = 1;
                if (is_sto) begin
                    wr = 1;       // Cho phép ghi vào Memory
                    data_e = 1;   // Tiếp tục mở cổng đẩy data
                end
            end
            
            default: ; // Không làm gì thêm
        endcase
    end
endmodule