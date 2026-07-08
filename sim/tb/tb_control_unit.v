`timescale 1ns / 1ps
`include "public.vh"

module tb_control_unit;

    reg  [31:0] instr;

    wire [`ALUOP_BUS]   alu_op;
    wire [`ALUTYPE_BUS] alu_type;
    wire                alu_src_imm;
    wire                reg_write;
    wire                reg_read_rs1;
    wire                reg_read_rs2;
    wire                rd_old_read;
    wire                mem_read;
    wire                mem_write;
    wire [1:0]          wb_sel;
    wire [2:0]          branch_type;
    wire                jump;
    wire                jump_reg;
    wire [2:0]          imm_sel;
    wire                is_mac;
    wire                halt;
    wire                illegal_instr;
    wire                instret_pulse;
    wire                mac_pulse;

    control_unit uut (
        .instr(instr),
        .alu_op(alu_op),
        .alu_type(alu_type),
        .alu_src_imm(alu_src_imm),
        .reg_write(reg_write),
        .reg_read_rs1(reg_read_rs1),
        .reg_read_rs2(reg_read_rs2),
        .rd_old_read(rd_old_read),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .wb_sel(wb_sel),
        .branch_type(branch_type),
        .jump(jump),
        .jump_reg(jump_reg),
        .imm_sel(imm_sel),
        .is_mac(is_mac),
        .halt(halt),
        .illegal_instr(illegal_instr),
        .instret_pulse(instret_pulse),
        .mac_pulse(mac_pulse)
    );

    initial begin
        // ADD
        instr = 32'b0000000_00011_00010_000_00001_0110011;
        #1;
        if (reg_write && reg_read_rs1 && reg_read_rs2 &&
            !alu_src_imm &&
            (alu_type == `ALUTYPE_ARITH) &&
            (alu_op == `ALUOP_ADD) &&
            (wb_sel == 2'b00) &&
            instret_pulse && !illegal_instr)
            $display("PASS: ADD decode");
        else
            $display("FAIL: ADD decode");

        // SUB
        instr = 32'b0100000_00011_00010_000_00001_0110011;
        #1;
        if (reg_write &&
            (alu_type == `ALUTYPE_ARITH) &&
            (alu_op == `ALUOP_SUB) &&
            !illegal_instr)
            $display("PASS: SUB decode");
        else
            $display("FAIL: SUB decode");

        // ANDI
        instr = 32'b000000000001_00010_111_00001_0010011;
        #1;
        if (reg_write && reg_read_rs1 && alu_src_imm &&
            (alu_type == `ALUTYPE_LOGIC) &&
            (alu_op == `ALUOP_AND) &&
            !illegal_instr)
            $display("PASS: ANDI decode");
        else
            $display("FAIL: ANDI decode");

        // SRLI
        instr = 32'b0000000_00101_00010_101_00001_0010011;
        #1;
        if (reg_write && reg_read_rs1 && alu_src_imm &&
            (alu_type == `ALUTYPE_SHIFT) &&
            (alu_op == `ALUOP_SRL) &&
            !illegal_instr)
            $display("PASS: SRLI decode");
        else
            $display("FAIL: SRLI decode");

        // SRAI
        instr = 32'b0100000_00101_00010_101_00001_0010011;
        #1;
        if (reg_write && reg_read_rs1 && alu_src_imm &&
            (alu_type == `ALUTYPE_SHIFT) &&
            (alu_op == `ALUOP_SRA) &&
            !illegal_instr)
            $display("PASS: SRAI decode");
        else
            $display("FAIL: SRAI decode");

        // LW
        instr = 32'b000000000100_00010_010_00001_0000011;
        #1;
        if (reg_write && reg_read_rs1 && mem_read &&
            !mem_write && alu_src_imm &&
            (wb_sel == 2'b01) &&
            !illegal_instr)
            $display("PASS: LW decode");
        else
            $display("FAIL: LW decode");

        // SW
        instr = 32'b0000000_00001_00010_010_00100_0100011;
        #1;
        if (!reg_write && reg_read_rs1 && reg_read_rs2 &&
            mem_write && !mem_read &&
            alu_src_imm &&
            !illegal_instr)
            $display("PASS: SW decode");
        else
            $display("FAIL: SW decode");

        // BEQ
        instr = 32'b0000000_00011_00010_000_00100_1100011;
        #1;
        if (reg_read_rs1 && reg_read_rs2 &&
            (branch_type == `RV_F3_BEQ) &&
            (alu_type == `ALUTYPE_JUMP) &&
            instret_pulse &&
            !illegal_instr)
            $display("PASS: BEQ decode");
        else
            $display("FAIL: BEQ decode");

        // JAL
        instr = 32'b00000000000100000000_00001_1101111;
        #1;
        if (reg_write && jump && !jump_reg &&
            (wb_sel == 2'b10) &&
            !illegal_instr)
            $display("PASS: JAL decode");
        else
            $display("FAIL: JAL decode");

        // JALR
        instr = 32'b000000000100_00010_000_00001_1100111;
        #1;
        if (reg_write && !jump && jump_reg &&
            reg_read_rs1 && alu_src_imm &&
            (wb_sel == 2'b10) &&
            !illegal_instr)
            $display("PASS: JALR decode");
        else
            $display("FAIL: JALR decode");

        // LUI
        instr = 32'b00000000000000010000_00001_0110111;
        #1;
        if (reg_write &&
            (alu_type == `ALUTYPE_MOVE) &&
            (alu_op == `ALUOP_LUI) &&
            !illegal_instr)
            $display("PASS: LUI decode");
        else
            $display("FAIL: LUI decode");

        // AUIPC
        instr = 32'b00000000000000010000_00001_0010111;
        #1;
        if (reg_write &&
            reg_read_rs1 &&
            alu_src_imm &&
            (alu_type == `ALUTYPE_MOVE) &&
            (alu_op == `ALUOP_AUIPC) &&
            !illegal_instr)
            $display("PASS: AUIPC decode");
        else
            $display("FAIL: AUIPC decode");

        // EBREAK
        instr = `RV_EBREAK;
        #1;
        if (halt && !illegal_instr && !instret_pulse)
            $display("PASS: EBREAK decode");
        else
            $display("FAIL: EBREAK decode");

        // MAC
        instr = 32'b0000000_00011_00010_000_00001_0001011;
        #1;
        if (is_mac && reg_write && reg_read_rs1 &&
            reg_read_rs2 && rd_old_read &&
            (alu_type == `ALUTYPE_MAC) &&
            (alu_op == `ALUOP_MAC) &&
            (wb_sel == 2'b11) &&
            mac_pulse && instret_pulse &&
            !illegal_instr)
            $display("PASS: MAC decode");
        else
            $display("FAIL: MAC decode");

        // Illegal instruction
        instr = 32'hFFFFFFFF;
        #1;
        if (illegal_instr)
            $display("PASS: illegal instruction decode");
        else
            $display("FAIL: illegal instruction decode");

        $display("ALL CONTROL UNIT TESTS FINISHED");
        $finish;
    end

endmodule