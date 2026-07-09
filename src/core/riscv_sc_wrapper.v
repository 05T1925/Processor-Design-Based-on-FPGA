//==============================================================================
// riscv_sc_wrapper.v - RV32I Single-Cycle CPU Wrapper (PLACEHOLDER)
//
// P1 task: adapt riscv-minisys-cpu single-cycle core to unified bus interface.
// Currently a placeholder — ties all outputs to safe inactive values.
//==============================================================================

`include "public.vh"

module riscv_sc_wrapper (
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
    output wire [7:0]  debug_state
);

    // Placeholder: safe inactive values (CPU_MODE=1 not yet implemented)
    assign ibus_addr     = 32'h0000_0000;
    assign ibus_en       = 1'b0;
    assign dbus_addr     = 32'h0000_0000;
    assign dbus_wdata    = 32'h0000_0000;
    assign dbus_byte_sel = 4'b0000;
    assign dbus_we       = 1'b0;
    assign dbus_en       = 1'b0;
    assign debug_pc      = 32'h0000_0000;
    assign debug_state   = 8'hFF;  // 0xFF = placeholder marker

endmodule
