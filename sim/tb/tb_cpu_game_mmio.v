`timescale 1ns/1ps

module tb_cpu_game_mmio;
    reg clk = 0;
    reg rst_n = 0;
    reg [4:0] btn = 0;
    reg [15:0] sw = 0;
    wire [15:0] led;
    wire [7:0] seg_an, seg_cat;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync, uart_tx;
    wire [31:0] debug_pc;
    wire [7:0] debug_state;

    always #5 clk = ~clk;

    soc_top #(
        .CPU_MODE(0),
        .SYS_CLK_FREQ(300),
        .INST_INIT_FILE("C:/Users/28641/Desktop/Project-based Curriculum Stage/tests/demo/cpu_guess_game.hex")
    ) dut (
        .clk(clk), .rst_n(rst_n), .led(led), .sw(sw), .btn(btn),
        .seg_an(seg_an), .seg_cat(seg_cat), .vga_r(vga_r), .vga_g(vga_g),
        .vga_b(vga_b), .vga_hsync(vga_hsync), .vga_vsync(vga_vsync),
        .uart_rx(1'b1), .uart_tx(uart_tx), .debug_pc(debug_pc),
        .debug_state(debug_state)
    );

    reg saw_btn_read = 0;
    reg saw_vga_write_after_read = 0;
    reg saw_btn_ack = 0;
    always @(posedge clk) begin
        if (dut.dbus_en && !dut.dbus_we && dut.dbus_addr == 32'hFFFF_FC54)
            saw_btn_read <= 1;
        if (saw_btn_read && dut.dbus_en && dut.dbus_we &&
            (dut.dbus_addr == 32'hFFFF_FC40 || dut.dbus_addr == 32'hFFFF_FC44))
            saw_vga_write_after_read <= 1;
        if (dut.dbus_en && dut.dbus_we && dut.dbus_addr == 32'hFFFF_FC5C)
            saw_btn_ack <= 1;
    end

    task press_key;
        input integer bit_index;
        integer timeout;
        begin
            btn[bit_index] = 1'b1;
            repeat (8) @(posedge clk);
            btn[bit_index] = 1'b0;
            repeat (8) @(posedge clk);
            timeout = 0;
            while ((dut.button_mmio_inst.edge_latched != 0) && timeout < 3000) begin
                @(posedge clk); timeout = timeout + 1;
            end
            if (timeout >= 3000) $fatal(1, "CPU did not ACK button event");
            repeat (12) @(posedge clk);
        end
    endtask

    integer target;
    integer i;
    integer timeout;
    initial begin
        repeat (5) @(posedge clk); rst_n = 1;

        timeout = 0;
        while ((dut.vga_x4_target == 0) && timeout < 200000) begin
            @(posedge clk); timeout = timeout + 1;
        end
        if (timeout >= 200000) $fatal(1, "CPU game initialization timeout pc=%h", debug_pc);
        target = dut.vga_x4_target;
        if (target < 1 || target > 999)
            $fatal(1, "bad target %0d pc=%h state=%0d x4=%h writes=%0d last=%0d guess=%h x3=%h x30=%h x31=%h",
                   target, debug_pc, debug_state,
                   dut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[4],
                   dut.vga_write_count, dut.vga_regs_inst.last_field,
                   dut.vga_guess, dut.vga_x3_guess,
                   dut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[30],
                   dut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[31]);

        // Submit zero: target is guaranteed non-zero, therefore TOO LOW.
        press_key(4);
        if (dut.vga_hint != 1 || dut.vga_attempts != 1)
            $fatal(1, "TOO LOW path failed hint=%0d attempts=%0d", dut.vga_hint, dut.vga_attempts);

        // Build the hidden target using CPU-handled decimal digit controls.
        for (i = 0; i < target / 100; i = i + 1) press_key(2);
        press_key(1);
        for (i = 0; i < (target / 10) % 10; i = i + 1) press_key(2);
        press_key(1);
        for (i = 0; i < target % 10; i = i + 1) press_key(2);
        if (dut.vga_guess != target) $fatal(1, "guess construction failed %0d != %0d", dut.vga_guess, target);

        // One above target exercises TOO HIGH, then decrement and win.
        press_key(2);
        press_key(4);
        if (dut.vga_hint != 2 || dut.vga_attempts != 2)
            $fatal(1, "TOO HIGH path failed hint=%0d attempts=%0d", dut.vga_hint, dut.vga_attempts);
        press_key(3);
        press_key(4);
        if (dut.vga_hint != 3 || dut.vga_game_state != 4 || dut.vga_attempts != 3)
            $fatal(1, "CORRECT path failed hint=%0d state=%0d attempts=%0d",
                   dut.vga_hint, dut.vga_game_state, dut.vga_attempts);

        if (!saw_btn_read || !saw_vga_write_after_read || !saw_btn_ack)
            $fatal(1, "missing BTN-read -> VGA-write -> BTN-ACK evidence");

        $display("PASS: CPU BTN LW -> RV32I game branches -> VGA SW, target=%0d", target);
        $finish;
    end
endmodule
