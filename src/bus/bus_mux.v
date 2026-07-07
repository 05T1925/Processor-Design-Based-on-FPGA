//==============================================================================
// bus_mux.v - Read Data Multiplexer for Unified Bus
//
// Based on: minisys_unified/rtl/bus/bus_mux.v
//
// Multiplexes read data from all slaves back to the CPU dbus_rdata.
//==================================================================== ==========

module bus_mux (
    input  wire [31:0] data_ram_rdata,
    input  wire [31:0] led_rdata,
    input  wire [31:0] switch_rdata,
    input  wire [31:0] seg7_rdata,
    input  wire [31:0] uart_rdata,
    input  wire [31:0] vga_rdata,
    input  wire [31:0] kbd4x4_rdata,
    input  wire [31:0] ps2_rdata,
    input  wire [31:0] timer_rdata,
    input  wire [31:0] pwm_rdata,
    input  wire [31:0] buzzer_rdata,
    input  wire [31:0] wdt_rdata,
    input  wire [31:0] perf_rdata,
    input  wire [31:0] result_rdata,

    input  wire        data_ram_sel,
    input  wire        led_sel,
    input  wire        switch_sel,
    input  wire        seg7_sel,
    input  wire        uart_sel,
    input  wire        vga_sel,
    input  wire        kbd4x4_sel,
    input  wire        ps2_sel,
    input  wire        timer_sel,
    input  wire        pwm_sel,
    input  wire        buzzer_sel,
    input  wire        wdt_sel,
    input  wire        perf_sel,
    input  wire        result_sel,

    output wire [31:0] dbus_rdata
);

    assign dbus_rdata =
        led_sel      ? led_rdata      :
        switch_sel   ? switch_rdata   :
        seg7_sel     ? seg7_rdata     :
        uart_sel     ? uart_rdata     :
        vga_sel      ? vga_rdata      :
        kbd4x4_sel   ? kbd4x4_rdata   :
        ps2_sel      ? ps2_rdata      :
        timer_sel    ? timer_rdata    :
        pwm_sel      ? pwm_rdata      :
        buzzer_sel   ? buzzer_rdata   :
        wdt_sel      ? wdt_rdata      :
        perf_sel     ? perf_rdata     :
        result_sel   ? result_rdata   :
        data_ram_sel ? data_ram_rdata :
        32'h0000_0000;

endmodule
