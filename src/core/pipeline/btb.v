//==============================================================================
// btb.v - Branch Target Buffer with 2-bit Saturating Counter Predictor
//
// Direct-mapped BTB for RV32I 5-stage pipeline CPU.
//
// Features:
//   - Configurable number of entries (default: 16)
//   - 2-bit saturating counter per entry (Smith predictor)
//     - 00 = Strongly Not Taken (SNT)
//     - 01 = Weakly Not Taken   (WNT)
//     - 10 = Weakly Taken       (WT)
//     - 11 = Strongly Taken     (ST)
//   - Prediction: taken if counter MSB == 1
//   - Lookup in IF stage (PC-based)
//   - Update in EX stage (branch resolution feedback)
//   - Built-in accuracy statistics (lookup/hit/mispred counters)
//
// Entry format (per entry):
//   {valid, pc_tag[TAG_WIDTH-1:0], target_addr[31:0], counter[1:0]}
//
// Board: Minisys (XC7A100T-FGG484-1, 100MHz)
//==============================================================================

`include "../public.vh"

module btb #(
    parameter ENTRIES   = 16,              // Number of BTB entries (power of 2)
    parameter TAG_WIDTH = 28               // PC[31:4] stored as tag
) (
    input  wire        clk,
    input  wire        rst_n,

    //----------------------------------------------------------------------
    // Lookup interface (IF stage) — combinational read
    //----------------------------------------------------------------------
    input  wire [31:0] lookup_pc,          // Current PC in IF stage
    output wire        predict_taken,      // Prediction: 1 = taken, 0 = not-taken
    output wire [31:0] predict_target,     // Predicted branch target address

    //----------------------------------------------------------------------
    // Update interface (EX stage) — sequential write on branch resolution
    //----------------------------------------------------------------------
    input  wire        update_valid,       // 1 = a branch instruction is resolving
    input  wire [31:0] update_pc,          // PC of the resolving branch
    input  wire [31:0] update_target,      // Actual target address (PC+imm or JALR target)
    input  wire        update_taken,       // Actual branch outcome: 1 = taken

    //----------------------------------------------------------------------
    // Statistics interface (exposed to performance counters / MMIO)
    //----------------------------------------------------------------------
    output wire [31:0] btb_lookup_count,   // Total BTB lookups (branches fetched)
    output wire [31:0] btb_hit_count,      // BTB hits (entry found with valid=1)
    output wire [31:0] btb_mispred_count   // Mispredictions (prediction ≠ actual)
);

    //--------------------------------------------------------------------------
    // Local parameters
    //--------------------------------------------------------------------------
    // IDX_WIDTH = log2(ENTRIES).  Supported ENTRIES: 4, 8, 16, 32, 64
    localparam IDX_WIDTH = (ENTRIES == 4)  ? 2 :
                           (ENTRIES == 8)  ? 3 :
                           (ENTRIES == 16) ? 4 :
                           (ENTRIES == 32) ? 5 :
                           (ENTRIES == 64) ? 6 : 4;  // default 16 entries

    //--------------------------------------------------------------------------
    // BTB entry storage
    //--------------------------------------------------------------------------
    reg                 btb_valid   [0:ENTRIES-1];
    reg [TAG_WIDTH-1:0] btb_tag     [0:ENTRIES-1];
    reg [31:0]          btb_target  [0:ENTRIES-1];
    reg [1:0]           btb_counter [0:ENTRIES-1];

    //--------------------------------------------------------------------------
    // Index and tag extraction
    //--------------------------------------------------------------------------
    wire [IDX_WIDTH-1:0] lookup_idx;
    wire [TAG_WIDTH-1:0] lookup_tag;
    wire [IDX_WIDTH-1:0] update_idx;
    wire [TAG_WIDTH-1:0] update_tag;

    // Use PC[IDX_WIDTH+1:2] as index (skip lowest 2 bits since instrs are 4B aligned)
    assign lookup_idx = lookup_pc[IDX_WIDTH+1:2];
    assign lookup_tag = lookup_pc[31:4];
    assign update_idx = update_pc[IDX_WIDTH+1:2];
    assign update_tag = update_pc[31:4];

    //--------------------------------------------------------------------------
    // BTB lookup (combinational)
    //
    // Hit condition: valid && tag match
    // Prediction: counter MSB (1 = predict taken)
    //--------------------------------------------------------------------------
    wire lookup_hit;
    wire [1:0] lookup_counter_val;

    assign lookup_hit          = btb_valid[lookup_idx] &&
                                 (btb_tag[lookup_idx] == lookup_tag);
    assign lookup_counter_val  = btb_counter[lookup_idx];
    assign predict_taken       = lookup_hit && lookup_counter_val[1];  // MSB=1 → taken
    assign predict_target      = btb_target[lookup_idx];

    //--------------------------------------------------------------------------
    // 2-bit saturating counter state machine
    //
    // State encoding:
    //   2'b00 = SNT (Strongly Not Taken) — predict not-taken
    //   2'b01 = WNT (Weakly Not Taken)   — predict not-taken
    //   2'b10 = WT  (Weakly Taken)       — predict taken
    //   2'b11 = ST  (Strongly Taken)     — predict taken
    //
    // Transition on branch resolution:
    //   If actually taken:   counter++, saturate at 2'b11
    //   If actually not-taken: counter--, saturate at 2'b00
    //--------------------------------------------------------------------------
    wire [1:0] update_counter_old;
    wire [1:0] update_counter_new;

    assign update_counter_old = btb_counter[update_idx];

    assign update_counter_new = update_taken ?
        // Taken: increment, saturate at 11
        ((update_counter_old == 2'b00) ? 2'b01 :
         (update_counter_old == 2'b01) ? 2'b10 :
         (update_counter_old == 2'b10) ? 2'b11 :
                                          2'b11) :
        // Not taken: decrement, saturate at 00
        ((update_counter_old == 2'b11) ? 2'b10 :
         (update_counter_old == 2'b10) ? 2'b01 :
         (update_counter_old == 2'b01) ? 2'b00 :
                                          2'b00);

    //--------------------------------------------------------------------------
    // Misprediction detection (combinational, for statistics)
    //
    // A misprediction occurs when:
    //   1. BTB said "taken" but branch was not taken, OR
    //   2. BTB said "not taken" but branch was taken
    //
    // Note: "not taken" prediction includes both BTB miss (no entry) and
    //       BTB hit with counter saying not-taken.
    //--------------------------------------------------------------------------
    wire update_mispred;
    assign update_mispred = update_valid &&
                            (predict_taken != update_taken);

    //--------------------------------------------------------------------------
    // BTB entry update (sequential)
    //--------------------------------------------------------------------------
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ENTRIES; i = i + 1) begin
                btb_valid[i]   <= `FALSE;
                btb_tag[i]     <= {TAG_WIDTH{1'b0}};
                btb_target[i]  <= `ZERO_WORD;
                btb_counter[i] <= 2'b00;       // Start at SNT
            end
        end else if (update_valid) begin
            // Update (or allocate) the entry indexed by update PC
            btb_valid[update_idx]   <= `TRUE;
            btb_tag[update_idx]     <= update_tag;
            btb_target[update_idx]  <= update_target;
            btb_counter[update_idx] <= update_counter_new;
        end
    end

    //--------------------------------------------------------------------------
    // Statistics counters
    //--------------------------------------------------------------------------
    reg [31:0] lookup_cnt;
    reg [31:0] hit_cnt;
    reg [31:0] mispred_cnt;

    // lookup_count: incremented each cycle IF stage queries the BTB
    // (we count actual branch lookups externally — here we expose raw counters)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lookup_cnt  <= 32'd0;
            hit_cnt     <= 32'd0;
            mispred_cnt <= 32'd0;
        end else begin
            // Increment on update (resolution) rather than every lookup cycle,
            // since the BTB is consulted every cycle but only meaningful on branches.
            // The CPU should gate these by actual branch instruction fetch/resolution.
            if (update_valid) begin
                lookup_cnt  <= lookup_cnt + 32'd1;
                if (lookup_hit)
                    hit_cnt <= hit_cnt + 32'd1;
                if (update_mispred)
                    mispred_cnt <= mispred_cnt + 32'd1;
            end
        end
    end

    assign btb_lookup_count = lookup_cnt;
    assign btb_hit_count    = hit_cnt;
    assign btb_mispred_count = mispred_cnt;

endmodule
