module Bus_Path_Map(
    input  wire clk,
    input  wire rst,
    input wire [4:0]  data_addr,
    
    output wire [31:0] out_value
);

    // ==========================================
    // 1. KHAI BÁO CÁC ĐƯỜNG BUS VÀ DÂY TÍN HIỆU NỘI BỘ (PHẢI ĐẶT TRÊN CÙNG)
    // ==========================================
    
    // Tín hiệu kết nối dữ liệu và địa chỉ
    wire [31:0] data_bus;   // Bus dữ liệu 2 chiều (Data Bus)
    wire [31:0] mem_addr;   // Địa chỉ đưa vào Memory
    wire [31:0] pc_out;     // Đầu ra của Program Counter
    wire [31:0] ac_out;     // Đầu ra của Accumulator
    wire [31:0] alu_out;    // Kết quả tính toán của ALU
    wire [4:0]  ir_addr;    // Địa chỉ 5-bit trích xuất từ Lệnh
    wire [2:0]  opcode;     // Mã lệnh 3-bit
    
    // Tín hiệu điều khiển và trạng thái
    wire sel, rd, wr, ld_ir, ld_ac, inc_pc, ld_pc, data_e, halt;
    wire is_zero;

    // ==========================================
    // 2. GÁN TÍN HIỆU OUTPUT & XỬ LÝ CỔNG 3 TRẠNG THÁI
    // ==========================================
    

    // Khi lệnh là STO (Store), bật data_e = 1 để đẩy dữ liệu từ Accumulator ra bus.
    // Ngược lại, nhả bus ra (trạng thái High-Z - 32'bz) để Memory có thể đẩy dữ liệu lên Bus.
    assign data_bus = (data_e) ? ac_out : 32'bz;

    // ==========================================
    // 3. KẾT NỐI (INSTANTIATE) CÁC MODULE
    // ==========================================

    // Bộ định tuyến địa chỉ
    Address_mux #(32) MUX (
        .pc_addr(pc_out),
        .ir_addr(ir_addr),
        .sel(sel),
        .mem_addr(mem_addr)
    );

    // Bộ điều khiển trung tâm
    Controller CTRL (
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

    // Thanh ghi lệnh (Instruction Register)
    Instruction_Register IR (
        .clk(clk),
        .rst(rst),
        .ld_ir(ld_ir),
        .data_in(data_bus),
        .opcode(opcode),
        .ir_addr(ir_addr)
    );

    // Bộ đếm chương trình (Program Counter)
    PC Program_Counter (
        .clk(clk),
        .rst(rst),
        // Nối ir_addr 5-bit vào pc_in 32-bit bằng cách bù thêm 27 bit 0 ở đầu
        .pc_in({{27{1'b0}}, ir_addr}), 
        .inc_pc(inc_pc),
        .ld_pc(ld_pc),
        .pc_out(pc_out)
    );

   // Bộ nhớ RAM
    Memory RAM (
        .clk(clk),
        .rd(rd),           // Nối tín hiệu rd
        .wr(wr),           // Nối tín hiệu wr từ Controller
        .address(mem_addr),
        .data(data_bus) ,
        .debug_addr(data_addr),    // Nối vào input của Top module
        .debug_data(out_value)
    );

    // Thanh ghi chứa kết quả tạm thời (Accumulator)
    Accumulator ACC (
        .clk(clk),
        .rst(rst),
        .ld_ac(ld_ac),
        .data_in(alu_out), // Nhận kết quả trả về từ ALU
        .data_out(ac_out)
    );

    // Bộ số học và logic (ALU)
    ALU ALU_Unit (
        .inA(ac_out),      // Toán hạng A luôn là giá trị đang có trong Accumulator
        .inB(data_bus),    // Toán hạng B lấy từ bộ nhớ qua Data Bus
        .opCode(opcode),
        .out(alu_out),
        .is_zero(is_zero)
    );

//    assign out_value = RAM[data_addr];
endmodule