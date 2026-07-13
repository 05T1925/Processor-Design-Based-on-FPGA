`timescale 1ns/1ps

module tb_benchmark;
    reg clk=0, rst_n=0;
    reg [4:0] btn=0;
    reg [15:0] sw=0;
    wire [15:0] led;
    wire [7:0] seg_an, seg_cat;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync, uart_tx;
    wire [31:0] debug_pc;
    wire [7:0] debug_state;
    always #5 clk=~clk;

    soc_top #(
        .CPU_MODE(0), .SYS_CLK_FREQ(300),
        .INST_INIT_FILE("C:/Users/28641/Desktop/Project-based Curriculum Stage/tests/demo/cpu_guess_game.hex")
    ) dut (
        .clk(clk), .rst_n(rst_n), .led(led), .sw(sw), .btn(btn),
        .seg_an(seg_an), .seg_cat(seg_cat), .vga_r(vga_r), .vga_g(vga_g),
        .vga_b(vga_b), .vga_hsync(vga_hsync), .vga_vsync(vga_vsync),
        .uart_rx(1'b1), .uart_tx(uart_tx), .debug_pc(debug_pc),
        .debug_state(debug_state)
    );

    task press_key;
        input integer bit_index;
        integer timeout;
        begin
            btn[bit_index]=1; repeat(8) @(posedge clk);
            btn[bit_index]=0; repeat(8) @(posedge clk);
            timeout=0;
            while (dut.button_mmio_inst.edge_latched != 0 && timeout < 300000) begin
                @(posedge clk); timeout=timeout+1;
            end
            if (timeout >= 300000)
                $fatal(1, "benchmark timeout pc=%h x17=%h x18=%h x20=%h x22=%h",
                       debug_pc,
                       dut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[17],
                       dut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[18],
                       dut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[20],
                       dut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[22]);
            repeat(20) @(posedge clk);
        end
    endtask

    integer timeout;
    reg [31:0] branch_cycles;
    reg [31:0] branch_instret;
    reg [31:0] memory_cycles;
    initial begin
        repeat(5) @(posedge clk); rst_n=1;
        timeout=0;
        while (dut.vga_write_count < 8 && timeout < 10000) begin
            @(posedge clk); timeout=timeout+1;
        end
        if (timeout >= 10000) $fatal(1, "initialization timeout");

        sw[1:0]=2'b10;
        timeout=0;
        while (dut.vga_page != 2 && timeout < 10000) begin
            @(posedge clk); timeout=timeout+1;
        end
        if (timeout >= 10000) $fatal(1, "page switch timeout");

        press_key(4); // BENCH 0 BRANCH
        branch_cycles = dut.vga_cycles;
        branch_instret = dut.vga_instret;
        if (branch_cycles == 0 || dut.vga_instret == 0 ||
            dut.vga_cpi_x100 == 0 || dut.vga_ipc_x100 == 0 || dut.vga_mips_x10 == 0)
            $fatal(1, "branch metrics missing");
        if (dut.vga_cpi_x100 != (branch_cycles * 100) / branch_instret ||
            dut.vga_ipc_x100 != (branch_instret * 100) / branch_cycles ||
            dut.vga_mips_x10 != (branch_instret * 1000) / branch_cycles)
            $fatal(1, "fixed-point CPI/IPC/MIPS mismatch");

        press_key(1); // BENCH 1 MEMORY
        press_key(4);
        memory_cycles = dut.vga_cycles;
        if (memory_cycles == 0 || dut.vga_instret == 0)
            $fatal(1, "memory metrics missing");

        press_key(1); // BENCH 2 MAC
        press_key(4);
        if (dut.vga_bench_status != 1)
            $fatal(1, "MAC result mismatch");
        if (dut.vga_bench_normal == 0 || dut.vga_bench_mac == 0 ||
            dut.vga_bench_normal <= dut.vga_bench_mac || dut.vga_speedup_x100 <= 100)
            $fatal(1, "MAC speedup invalid normal=%0d mac=%0d speedup=%0d",
                   dut.vga_bench_normal, dut.vga_bench_mac, dut.vga_speedup_x100);
        if (dut.vga_speedup_x100 !=
            (dut.vga_bench_normal * 100) / dut.vga_bench_mac)
            $fatal(1, "speedup formula mismatch");
        if (dut.vga_mac_count == 0) $fatal(1, "real MAC counter was not updated");

        $display("PASS: branch=%0d cycles memory=%0d cycles MAC=%0d/%0d speedup=%0d/100",
                 branch_cycles, memory_cycles, dut.vga_bench_normal,
                 dut.vga_bench_mac, dut.vga_speedup_x100);
        $finish;
    end
endmodule
