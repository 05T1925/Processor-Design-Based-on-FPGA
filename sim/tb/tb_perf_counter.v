`timescale 1ns / 1ps

module tb_perf_counter;

    reg clk;
    reg rst;
    reg halted;
    reg instret_pulse;
    reg mac_pulse;

    wire [31:0] cycle_count;
    wire [31:0] instret_count;
    wire [31:0] mac_count;

    integer errors;

    csr_perf_counter uut (
        .clk           (clk),
        .rst           (rst),
        .halted        (halted),
        .instret_pulse (instret_pulse),
        .mac_pulse     (mac_pulse),
        .cycle_count   (cycle_count),
        .instret_count (instret_count),
        .mac_count     (mac_count)
    );

    always #5 clk = ~clk;

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task check_counts;
        input [31:0] expected_cycle;
        input [31:0] expected_instret;
        input [31:0] expected_mac;
        input [8*32-1:0] name;
        begin
            if ((cycle_count !== expected_cycle) ||
                (instret_count !== expected_instret) ||
                (mac_count !== expected_mac)) begin
                $display("FAIL: %0s cycle=%0d/%0d instret=%0d/%0d mac=%0d/%0d",
                         name,
                         cycle_count, expected_cycle,
                         instret_count, expected_instret,
                         mac_count, expected_mac);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s cycle=%0d instret=%0d mac=%0d",
                         name, cycle_count, instret_count, mac_count);
            end
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        halted = 0;
        instret_pulse = 0;
        mac_pulse = 0;
        errors = 0;

        tick;
        tick;
        check_counts(0, 0, 0, "reset clears all counters");

        rst = 0;
        tick;
        tick;
        tick;
        check_counts(3, 0, 0, "cycle counter while running");

        instret_pulse = 1;
        tick;
        instret_pulse = 0;
        check_counts(4, 1, 0, "single retirement pulse");

        instret_pulse = 1;
        tick;
        tick;
        instret_pulse = 0;
        check_counts(6, 3, 0, "consecutive retirement pulses");

        instret_pulse = 1;
        mac_pulse = 1;
        tick;
        instret_pulse = 0;
        mac_pulse = 0;
        check_counts(7, 4, 1, "simultaneous retirement and MAC");

        halted = 1;
        tick;
        tick;
        check_counts(7, 4, 1, "cycle counter freezes while halted");

        rst = 1;
        tick;
        check_counts(0, 0, 0, "reset while halted");

        if (errors == 0)
            $display("ALL PERFORMANCE COUNTER TESTS PASSED");
        else
            $display("PERFORMANCE COUNTER TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
