//==============================================================================
// bus_decoder.v - Address Decoder for Unified Bus
//
// Based on: minisys_unified/rtl/bus/bus_decoder.v
//
// Decodes dbus_addr into peripheral chip-select signals using addr[9:4].
// Address regions:
//   - 0x1000_0000 ~ 0x1000_7FFF → Data RAM
//   - 0xFFFF_FC00 ~ 0xFFFF_FCAF → Peripherals
//==============================================================================

module bus_decoder (
    input  wire [31:0] dbus_addr,
    input  wire        dbus_en,

    output wire        data_ram_sel,
    output wire        led_sel,
    output wire        switch_sel,
    output wire        seg7_sel,
    output wire        uart_sel,
    output wire        vga_sel,
    output wire        kbd4x4_sel,
    output wire        ps2_sel,
    output wire        timer_sel,
    output wire        pwm_sel,
    output wire        buzzer_sel,
    output wire        wdt_sel,
    output wire        perf_sel,
    output wire        result_sel
);

    wire in_data_ram;
    wire in_periph;

    assign in_data_ram = (dbus_addr >= 32'h1000_0000) &&
                         (dbus_addr <  32'h1000_8000);

    assign in_periph   = (dbus_addr >= 32'hFFFF_FC00) &&
                         (dbus_addr <= 32'hFFFF_FCCF);

    wire [5:0] periph_id = dbus_addr[9:4];

    assign data_ram_sel = dbus_en && in_data_ram;

    assign led_sel      = dbus_en && in_periph && (periph_id == 6'b00_0000);
    assign switch_sel   = dbus_en && in_periph && (periph_id == 6'b00_0001);
    assign seg7_sel     = dbus_en && in_periph && (periph_id == 6'b00_0010);
    assign uart_sel     = dbus_en && in_periph && (periph_id == 6'b00_0011);
    assign vga_sel      = dbus_en && in_periph && (periph_id == 6'b00_0100);
    assign kbd4x4_sel   = dbus_en && in_periph && (periph_id == 6'b00_0101);
    assign ps2_sel      = dbus_en && in_periph && (periph_id == 6'b00_0110);
    assign timer_sel    = dbus_en && in_periph && (periph_id == 6'b00_0111);
    assign pwm_sel      = dbus_en && in_periph && (periph_id == 6'b00_1000);
    assign buzzer_sel   = dbus_en && in_periph && (periph_id == 6'b00_1001);
    assign wdt_sel      = dbus_en && in_periph && (periph_id == 6'b00_1010);
    assign perf_sel     = dbus_en && in_periph && (periph_id == 6'b00_1011);
    assign result_sel   = dbus_en && in_periph && (periph_id == 6'b00_1100);

endmodule
