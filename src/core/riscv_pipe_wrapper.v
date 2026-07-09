//==============================================================================
// riscv_pipe_wrapper.v - RV32I 5-Stage Pipeline CPU Wrapper
//
// Adapts the riscv_pipeline_cpu internal interface to the unified ibus/dbus
// standard. Same interface as riscv_mc_wrapper.v for CPU_MODE interchangeability.
//
// Board: Minisys (XC7A100T-FGG484-1, 100MHz)
//==============================================================================

`include "public.vh"

module riscv_pipe_wrapper (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [5:0]  irq,

    // Unified instruction bus
    output wire [31:0] ibus_addr,
    input  wire [31:0] ibus_rdata,
    output wire        ibus_en,
    input  wire        ibus_ready,

    // Unified data bus
    output wire [31:0] dbus_addr,
    output wire [31:0] dbus_wdata,
    input  wire [31:0] dbus_rdata,
    output wire [3:0]  dbus_byte_sel,
    output wire        dbus_we,
    output wire        dbus_en,
    input  wire        dbus_ready,
    input  wire        dbus_error,

    // Debug
    output wire [31:0] debug_pc,
    output wire [7:0]  debug_state,

    // Performance counters
    output wire [31:0] perf_cycle_count,
    output wire [31:0] perf_instret_count,
    output wire [31:0] perf_mac_count
);

    //--------------------------------------------------------------------------
    // Pipeline CPU instantiation
    //
    // Memory map (same as multi-cycle):
    //   0x0000_0000 - 0x0000_7FFF: Instruction memory (ibus, read-only)
    //   0x1000_0000 - 0x1000_7FFF: Data memory (dbus, read/write)
    //   0xFFFF_FC00 - 0xFFFF_FCCF: MMIO peripherals (dbus, read/write)
    //--------------------------------------------------------------------------

    riscv_pipeline_cpu u_cpu (
        .clk            (clk),
        .rst_n          (rst_n),
        .ibus_addr      (ibus_addr),
        .ibus_rdata     (ibus_rdata),
        .ibus_en        (ibus_en),
        .dbus_addr      (dbus_addr),
        .dbus_wdata     (dbus_wdata),
        .dbus_rdata     (dbus_rdata),
        .dbus_byte_sel  (dbus_byte_sel),
        .dbus_we        (dbus_we),
        .dbus_en        (dbus_en),
        .debug_pc       (debug_pc),
        .debug_state    (debug_state),
        .debug_x10      (),
        .debug_illegal  (),
        .perf_cycle_count   (perf_cycle_count),
        .perf_instret_count (perf_instret_count),
        .perf_mac_count     (perf_mac_count)
    );

endmodule
