//==============================================================================
// cpu_top.v - CPU Top-Level with Generate-Based Mode Selection
//
// Based on: minisys_unified/rtl/cpu/cpu_top.v
//
// Selects one CPU wrapper based on CPU_MODE parameter.
// All wrappers expose the same unified bus interface.
//
// CPU_MODE:
//   0 = RV32I multi-cycle FSM (P0 baseline) ★ PRIMARY
//   1 = RV32I single-cycle (from riscv-minisys-cpu)
//   2 = MIPS single-cycle (from SUSTech CS202, placeholder)
//   3 = MIPS 5-stage pipeline basic (from NCUT, placeholder)
//   4 = MIPS 5-stage pipeline advanced (from SEU, placeholder)
//==============================================================================

module cpu_top #(
    parameter CPU_MODE = 0
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [5:0]  irq,

    output wire [31:0] ibus_addr,
    input  wire [31:0] ibus_rdata,
    output wire        ibus_en,
    input  wire        ibus_ready,

    output wire [31:0] dbus_addr,
    output wire [31:0] dbus_wdata,
    input  wire [31:0] dbus_rdata,
    output wire [3:0]  dbus_byte_sel,
    output wire        dbus_we,
    output wire        dbus_en,
    input  wire        dbus_ready,
    input  wire        dbus_error,

    output wire [31:0] debug_pc,
    output wire [7:0]  debug_state,

    output wire [31:0] perf_cycle_count,
    output wire [31:0] perf_instret_count,
    output wire [31:0] perf_mac_count,

    // BTB statistics (valid only in MODE=5)
    output wire [31:0] perf_br_total_count,
    output wire [31:0] perf_br_mispred_count,
    output wire [31:0] perf_btb_hit_count
);

    generate
        //======================================================================
        // Mode 0: RV32I Multi-Cycle FSM CPU ★ PRIMARY
        //======================================================================
        if (CPU_MODE == 0) begin : gen_riscv_mc
            riscv_mc_wrapper riscv_mc_inst (
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
                .perf_mac_count     (perf_mac_count)
            );
            assign perf_br_total_count   = 32'b0;
            assign perf_br_mispred_count = 32'b0;
            assign perf_btb_hit_count    = 32'b0;

        //======================================================================
        // Mode 1: RV32I Single-Cycle (from riscv-minisys-cpu / BUPT)
        //======================================================================
        end else if (CPU_MODE == 1) begin : gen_riscv_sc
            riscv_sc_wrapper riscv_sc_inst (
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
                .debug_state    (debug_state)
            );
            assign perf_cycle_count   = 32'b0;
            assign perf_instret_count = 32'b0;
            assign perf_mac_count     = 32'b0;
            assign perf_br_total_count   = 32'b0;
            assign perf_br_mispred_count = 32'b0;
            assign perf_btb_hit_count    = 32'b0;

        //======================================================================
        // Mode 5: RV32I 5-Stage Pipeline CPU (P2 Sprint)
        //======================================================================
        end else if (CPU_MODE == 5) begin : gen_riscv_pipe
            riscv_pipe_wrapper riscv_pipe_inst (
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

        //======================================================================
        // Mode 2-4: MIPS modes (placeholder - use minisys_unified wrappers)
        //======================================================================
        end else begin : gen_placeholder
            // Placeholder: tie outputs to safe values
            assign ibus_addr     = 32'b0;
            assign ibus_en       = 1'b0;
            assign dbus_addr     = 32'b0;
            assign dbus_wdata    = 32'b0;
            assign dbus_byte_sel = 4'b0;
            assign dbus_we       = 1'b0;
            assign dbus_en       = 1'b0;
            assign debug_pc      = 32'b0;
            assign debug_state   = 8'b0;
            assign perf_cycle_count   = 32'b0;
            assign perf_instret_count = 32'b0;
            assign perf_mac_count     = 32'b0;
            assign perf_br_total_count   = 32'b0;
            assign perf_br_mispred_count = 32'b0;
            assign perf_btb_hit_count    = 32'b0;
        end
    endgenerate

endmodule
