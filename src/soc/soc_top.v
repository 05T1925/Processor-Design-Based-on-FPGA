//==============================================================================
// soc_top.v - SoC Integration Top-Level
//
// Instantiates: CPU (via cpu_top selector), instruction memory, data memory,
// bus decoder, bus mux, and all peripherals.
//
// The cpu_top selects the CPU core based on CPU_MODE parameter:
//   0 = RV32I multi-cycle FSM (P0 baseline) ★ PRIMARY
//   1 = RV32I single-cycle
//   2 = MIPS single-cycle
//   3 = MIPS 5-stage pipeline basic
//   4 = MIPS 5-stage pipeline advanced
//==============================================================================

`include "../core/public.vh"

module soc_top #(
    parameter CPU_MODE         = 0,
    parameter INST_RAM_SIZE    = 32768,
    parameter DATA_RAM_SIZE    = 32768,
    parameter UART_BAUD        = 115200,
    parameter SYS_CLK_FREQ     = 50_000_000
) (
    input  wire        clk,
    input  wire        rst_n,

    // External I/O
    output wire [15:0] led,
    input  wire [15:0] sw,

    output wire [7:0]  seg_an,
    output wire [7:0]  seg_cat,

    input  wire        uart_rx,
    output wire        uart_tx,

    // Debug
    output wire [31:0] debug_pc,
    output wire [7:0]  debug_state
);

    //==========================================================================
    // CPU buses
    //==========================================================================
    wire [31:0] ibus_addr;
    wire [31:0] ibus_rdata;
    wire        ibus_en;
    wire        ibus_ready;
    wire [31:0] dbus_addr;
    wire [31:0] dbus_wdata;
    wire [31:0] dbus_rdata;
    wire [3:0]  dbus_byte_sel;
    wire        dbus_we;
    wire        dbus_en;
    wire        dbus_ready;
    wire        dbus_error;
    wire [31:0] perf_cycle_count;
    wire [31:0] perf_instret_count;
    wire [31:0] perf_mac_count;
    wire [31:0] perf_br_total_count;
    wire [31:0] perf_br_mispred_count;
    wire [31:0] perf_btb_hit_count;

    wire [5:0] irq = 6'b000000;

    //==========================================================================
    // CPU Core (selected by CPU_MODE)
    //==========================================================================
    cpu_top #(
        .CPU_MODE(CPU_MODE)
    ) cpu_top_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .irq            (irq),
        .ibus_addr      (ibus_addr),
        .ibus_rdata     (ibus_rdata),
        .ibus_en        (ibus_en),
        .ibus_ready     (ibus_ready),
        .dbus_addr      (dbus_addr),
        .dbus_wdata     (dbus_wdata),
        .dbus_rdata     (dbus_rdata),
        .dbus_byte_sel  (dbus_byte_sel),
        .dbus_we        (dbus_we),
        .dbus_en        (dbus_en),
        .dbus_ready     (dbus_ready),
        .dbus_error     (dbus_error),
        .debug_pc       (debug_pc),
        .debug_state    (debug_state),
        .perf_cycle_count   (perf_cycle_count),
        .perf_instret_count (perf_instret_count),
        .perf_mac_count     (perf_mac_count),
        .perf_br_total_count  (perf_br_total_count),
        .perf_br_mispred_count(perf_br_mispred_count),
        .perf_btb_hit_count   (perf_btb_hit_count)
    );

    //==========================================================================
    // Instruction Memory
    //==========================================================================
    inst_ram #(
        .RAM_SIZE(INST_RAM_SIZE)
    ) inst_ram_inst (
        .clk        (clk),
        .addr       (ibus_addr),
        .rdata      (ibus_rdata),
        .en         (ibus_en),
        .upg_clk    (clk),
        .upg_rst_n  (rst_n),
        .upg_wen    (1'b0),
        .upg_addr   (14'b0),
        .upg_wdata  (32'b0)
    );
    assign ibus_ready = 1'b1;

    //==========================================================================
    // Bus Decoder
    //==========================================================================
    wire data_ram_sel;
    wire led_sel, switch_sel, seg7_sel, uart_sel, vga_sel;
    wire kbd4x4_sel, ps2_sel, timer_sel, pwm_sel, buzzer_sel, wdt_sel;
    wire perf_sel, result_sel;

    bus_decoder bus_decoder_inst (
        .dbus_addr      (dbus_addr),
        .dbus_en        (dbus_en),
        .data_ram_sel   (data_ram_sel),
        .led_sel        (led_sel),
        .switch_sel     (switch_sel),
        .seg7_sel       (seg7_sel),
        .uart_sel       (uart_sel),
        .vga_sel        (vga_sel),
        .kbd4x4_sel     (kbd4x4_sel),
        .ps2_sel        (ps2_sel),
        .timer_sel      (timer_sel),
        .pwm_sel        (pwm_sel),
        .buzzer_sel     (buzzer_sel),
        .wdt_sel        (wdt_sel),
        .perf_sel       (perf_sel),
        .result_sel     (result_sel)
    );

    //==========================================================================
    // Data Memory
    //==========================================================================
    wire [31:0] data_ram_rdata;
    wire        data_ram_ready;

    data_ram #(
        .RAM_SIZE(DATA_RAM_SIZE)
    ) data_ram_inst (
        .clk        (clk),
        .addr       (dbus_addr),
        .wdata      (dbus_wdata),
        .byte_sel   (dbus_byte_sel),
        .we         (dbus_we & data_ram_sel),
        .en         (dbus_en & data_ram_sel),
        .rdata      (data_ram_rdata),
        .ready      (data_ram_ready)
    );

    //==========================================================================
    // Peripherals
    //==========================================================================

    // LED
    wire [31:0] led_rdata;
    wire        led_ready;
    gpio_led gpio_led_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .bus_en     (led_sel),
        .bus_we     (dbus_we),
        .bus_addr   (dbus_addr[3:0]),
        .bus_wdata  (dbus_wdata),
        .bus_rdata  (led_rdata),
        .bus_ready  (led_ready),
        .led_out    (led)
    );

    // DIP Switches
    wire [31:0] switch_rdata;
    wire        switch_ready;
    gpio_switch gpio_switch_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .bus_en     (switch_sel),
        .bus_we     (dbus_we),
        .bus_addr   (dbus_addr[3:0]),
        .bus_wdata  (dbus_wdata),
        .bus_rdata  (switch_rdata),
        .bus_ready  (switch_ready),
        .sw_in      (sw)
    );

    // 7-Segment Display
    wire [31:0] seg7_rdata;
    wire        seg7_ready;
    seg7_driver seg7_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .bus_en     (seg7_sel),
        .bus_we     (dbus_we),
        .bus_addr   (dbus_addr[3:0]),
        .bus_wdata  (dbus_wdata),
        .bus_rdata  (seg7_rdata),
        .bus_ready  (seg7_ready),
        .seg_an     (seg_an),
        .seg_cat    (seg_cat)
    );

    // UART (placeholder - P2)
    wire [31:0] uart_rdata = 32'b0;
    wire        uart_ready = 1'b1;
    assign uart_tx = 1'b1;

    // Reserved peripherals (placeholders)
    wire [31:0] vga_rdata    = 32'b0;
    wire        vga_ready    = 1'b1;
    wire [31:0] kbd4x4_rdata = 32'b0;
    wire        kbd4x4_ready = 1'b1;
    wire [31:0] ps2_rdata    = 32'b0;
    wire        ps2_ready    = 1'b1;
    wire [31:0] timer_rdata  = 32'b0;
    wire        timer_ready  = 1'b1;
    wire [31:0] pwm_rdata    = 32'b0;
    wire        pwm_ready    = 1'b1;
    wire [31:0] buzzer_rdata = 32'b0;
    wire        buzzer_ready = 1'b1;
    wire [31:0] wdt_rdata    = 32'b0;
    wire        wdt_ready    = 1'b1;

    // Performance counters (read-only MMIO)
    //   0xFFFF_FCB0: cycle_count
    //   0xFFFF_FCB4: instret_count
    //   0xFFFF_FCB8: mac_count
    reg  [31:0] perf_rdata;
    wire        perf_ready   = 1'b1;

    always @(*) begin
        case (dbus_addr[3:2])
            2'b00:   perf_rdata = perf_cycle_count;
            2'b01:   perf_rdata = perf_instret_count;
            2'b10:   perf_rdata = perf_mac_count;
            default: perf_rdata = 32'b0;
        endcase
    end

    // BTB statistics (MMIO: 0xFFFF_FCC0 - 0xFFFF_FCC8)
    // Repurposed from result_reg placeholder.
    //   0xFFFF_FCC0: br_total_count   (total branches encountered)
    //   0xFFFF_FCC4: br_mispred_count (mispredictions)
    //   0xFFFF_FCC8: btb_hit_count    (BTB lookup hits)
    reg  [31:0] result_rdata;
    wire        result_ready = 1'b1;

    always @(*) begin
        case (dbus_addr[3:2])
            2'b00:   result_rdata = perf_br_total_count;
            2'b01:   result_rdata = perf_br_mispred_count;
            2'b10:   result_rdata = perf_btb_hit_count;
            default: result_rdata = 32'b0;
        endcase
    end

    //==========================================================================
    // Bus Read-Data Multiplexer
    //==========================================================================
    bus_mux bus_mux_inst (
        .data_ram_rdata (data_ram_rdata),
        .led_rdata      (led_rdata),
        .switch_rdata   (switch_rdata),
        .seg7_rdata     (seg7_rdata),
        .uart_rdata     (uart_rdata),
        .vga_rdata      (vga_rdata),
        .kbd4x4_rdata   (kbd4x4_rdata),
        .ps2_rdata      (ps2_rdata),
        .timer_rdata    (timer_rdata),
        .pwm_rdata      (pwm_rdata),
        .buzzer_rdata   (buzzer_rdata),
        .wdt_rdata      (wdt_rdata),
        .perf_rdata     (perf_rdata),
        .result_rdata   (result_rdata),
        .data_ram_sel   (data_ram_sel),
        .led_sel        (led_sel),
        .switch_sel     (switch_sel),
        .seg7_sel       (seg7_sel),
        .uart_sel       (uart_sel),
        .vga_sel        (vga_sel),
        .kbd4x4_sel     (kbd4x4_sel),
        .ps2_sel        (ps2_sel),
        .timer_sel      (timer_sel),
        .pwm_sel        (pwm_sel),
        .buzzer_sel     (buzzer_sel),
        .wdt_sel        (wdt_sel),
        .perf_sel       (perf_sel),
        .result_sel     (result_sel),
        .dbus_rdata     (dbus_rdata)
    );

    // Bus ready MUX
    assign dbus_ready = data_ram_sel ? data_ram_ready :
                        led_sel      ? led_ready      :
                        switch_sel   ? switch_ready   :
                        seg7_sel     ? seg7_ready     :
                        uart_sel     ? uart_ready     :
                        perf_sel     ? perf_ready     :
                        1'b1;
    assign dbus_error = 1'b0;

endmodule
