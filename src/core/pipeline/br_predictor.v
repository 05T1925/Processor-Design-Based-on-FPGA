//==============================================================================
// br_predictor.v - Branch Prediction Accuracy Tracker with BTB Integration
//
// Wraps the BTB module and adds accuracy tracking logic for the 5-stage
// pipeline CPU. Provides:
//   - BTB lookup in IF stage (PC-based prediction)
//   - BTB update in EX stage (branch resolution feedback)
//   - Accuracy statistics (total branches, hits, mispredictions)
//   - Simple static fallback when BTB is disabled or misses
//
// This module acts as the bridge between the pipeline CPU's branch handling
// and the BTB's prediction mechanism.
//
// Board: Minisys (XC7A100T-FGG484-1, 100MHz)
//==============================================================================

`include "public.vh"

module br_predictor #(
    parameter BTB_ENTRIES = 16
) (
    input  wire        clk,
    input  wire        rst_n,

    //----------------------------------------------------------------------
    // IF stage: prediction lookup (combinational)
    //----------------------------------------------------------------------
    input  wire [31:0] if_pc,              // Current PC in IF stage
    input  wire        if_is_branch,       // 1 = current instruction is a branch
    output wire        predict_taken,      // BTB prediction: 1 = predict taken
    output wire [31:0] predict_target,     // BTB predicted target address

    //----------------------------------------------------------------------
    // ID stage: branch detection
    //----------------------------------------------------------------------
    input  wire [31:0] id_pc,              // PC of instruction in ID stage
    input  wire [2:0]  id_branch_type,     // Branch funct3 (BEQ/BNE/BLT/etc.)
    input  wire        id_is_branch,       // 1 = this is a conditional branch
    input  wire        id_is_jump,         // 1 = JAL
    input  wire        id_is_jump_reg,     // 1 = JALR
    input  wire [31:0] id_branch_target,   // Computed target (PC+imm)
    input  wire        id_valid,           // Valid instruction in ID

    //----------------------------------------------------------------------
    // EX stage: branch resolution (update BTB)
    //----------------------------------------------------------------------
    input  wire [31:0] ex_pc,              // PC of instruction in EX stage
    input  wire        ex_is_branch,       // 1 = this is a conditional branch
    input  wire        ex_branch_taken,    // Actual branch outcome
    input  wire [31:0] ex_branch_target,   // Actual target address
    input  wire        ex_valid,           // Valid instruction in EX
    input  wire [31:0] ex_pc_plus_4,       // Fall-through PC (PC+4)

    //----------------------------------------------------------------------
    // Statistics output (exposed to performance counters)
    //----------------------------------------------------------------------
    output wire [31:0] br_total_count,     // Total branches encountered
    output wire [31:0] br_taken_count,     // Branches actually taken
    output wire [31:0] br_mispred_count,   // Mispredictions (prediction ≠ actual)
    output wire [31:0] br_pred_taken_count,// Times we predicted taken
    output wire [31:0] btb_hit_count,      // BTB lookup hits
    output wire [31:0] btb_miss_count      // BTB lookup misses
);

    //--------------------------------------------------------------------------
    // BTB instantiation
    //--------------------------------------------------------------------------
    wire        btb_predict_taken;
    wire [31:0] btb_predict_target;
    wire [31:0] btb_lookup_cnt;
    wire [31:0] btb_hit_cnt;
    wire [31:0] btb_mispred_cnt;

    btb #(
        .ENTRIES(BTB_ENTRIES)
    ) u_btb (
        .clk              (clk),
        .rst_n            (rst_n),
        .lookup_pc        (if_pc),
        .predict_taken    (btb_predict_taken),
        .predict_target   (btb_predict_target),
        .update_valid     (ex_valid && ex_is_branch),
        .update_pc        (ex_pc),
        .update_target    (ex_branch_target),
        .update_taken     (ex_branch_taken),
        .btb_lookup_count (btb_lookup_cnt),
        .btb_hit_count    (btb_hit_cnt),
        .btb_mispred_count(btb_mispred_cnt)
    );

    //--------------------------------------------------------------------------
    // Prediction output — pass through from BTB
    //--------------------------------------------------------------------------
    assign predict_taken  = btb_predict_taken && if_is_branch;
    assign predict_target = btb_predict_target;

    //--------------------------------------------------------------------------
    // Branch statistics counters
    //--------------------------------------------------------------------------
    reg [31:0] total_branch_cnt;
    reg [31:0] taken_branch_cnt;
    reg [31:0] mispred_cnt;
    reg [31:0] pred_taken_cnt;

    // Count branches in EX stage (when they resolve)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_branch_cnt <= 32'd0;
            taken_branch_cnt <= 32'd0;
            mispred_cnt      <= 32'd0;
            pred_taken_cnt   <= 32'd0;
        end else begin
            // Count only conditional branches (not JAL/JALR)
            if (ex_valid && ex_is_branch) begin
                total_branch_cnt <= total_branch_cnt + 32'd1;

                if (ex_branch_taken)
                    taken_branch_cnt <= taken_branch_cnt + 32'd1;

                // Misprediction: prediction ≠ actual outcome
                if (btb_predict_taken != ex_branch_taken)
                    mispred_cnt <= mispred_cnt + 32'd1;

                // Count predictions of "taken"
                if (btb_predict_taken)
                    pred_taken_cnt <= pred_taken_cnt + 32'd1;
            end
        end
    end

    //--------------------------------------------------------------------------
    // Statistics output mapping
    //--------------------------------------------------------------------------
    assign br_total_count     = total_branch_cnt;
    assign br_taken_count     = taken_branch_cnt;
    assign br_mispred_count   = mispred_cnt;
    assign br_pred_taken_count = pred_taken_cnt;
    assign btb_hit_count      = btb_hit_cnt;
    assign btb_miss_count     = btb_lookup_cnt - btb_hit_cnt;

endmodule
