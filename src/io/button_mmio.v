//==============================================================================
// button_mmio.v - S1..S5 synchronized, debounced, edge-latched MMIO input
//
// Address offsets in the button slot (0xFFFF_FC50):
//   +0x0 BTN_LEVEL       stable pressed level, bit 0 = S1 ... bit 4 = S5
//   +0x4 BTN_EDGE        latched rising-edge events
//   +0x8 BTN_EVENT_COUNT total debounced press events
//   +0xC BTN_ACK         write-one-to-clear event bits
//==============================================================================

`timescale 1ns / 1ps

module button_mmio #(
    parameter integer DEBOUNCE_CYCLES = 1000000
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [4:0]  btn_in,
    input  wire        bus_en,
    input  wire        bus_we,
    input  wire [3:0]  bus_addr,
    input  wire [31:0] bus_wdata,
    output reg  [31:0] bus_rdata,
    output wire        bus_ready
);

    reg [4:0] sync0;
    reg [4:0] sync1;
    reg [4:0] candidate;
    reg [4:0] stable;
    reg [20:0] debounce_count;
    reg [4:0] edge_latched;
    reg [31:0] event_count;
    wire [4:0] ack_mask = bus_wdata[4:0];
    wire ack_write = bus_en && bus_we && (bus_addr == 4'hC);
    wire debounce_accept = (sync1 != candidate) &&
                           (debounce_count == DEBOUNCE_CYCLES - 1);
    wire [4:0] press_accept = debounce_accept ? (sync1 & ~stable) : 5'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync0         <= 5'b0;
            sync1         <= 5'b0;
            candidate     <= 5'b0;
            stable        <= 5'b0;
            debounce_count <= 21'b0;
            edge_latched  <= 5'b0;
            event_count   <= 32'b0;
        end else begin
            sync0 <= btn_in;
            sync1 <= sync0;

            if (sync1 != candidate) begin
                if (debounce_count == DEBOUNCE_CYCLES - 1) begin
                    candidate      <= sync1;
                    stable         <= sync1;
                    debounce_count <= 21'b0;
                end else begin
                    debounce_count <= debounce_count + 1'b1;
                end
            end else begin
                debounce_count <= 21'b0;
            end

            if (ack_write || (press_accept != 5'b0))
                edge_latched <= (edge_latched & ~(ack_write ? ack_mask : 5'b0)) |
                                press_accept;

            if (press_accept != 5'b0)
                event_count <= event_count +
                               {{31{1'b0}}, press_accept[0]} +
                               {{31{1'b0}}, press_accept[1]} +
                               {{31{1'b0}}, press_accept[2]} +
                               {{31{1'b0}}, press_accept[3]} +
                               {{31{1'b0}}, press_accept[4]};
        end
    end

    always @(*) begin
        bus_rdata = 32'b0;
        if (bus_en && !bus_we) begin
            case (bus_addr)
                4'h0: bus_rdata = {27'b0, stable};
                4'h4: bus_rdata = {27'b0, edge_latched};
                4'h8: bus_rdata = event_count;
                default: bus_rdata = 32'b0;
            endcase
        end
    end

    assign bus_ready = bus_en;

endmodule
