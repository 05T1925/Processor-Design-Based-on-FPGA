`timescale 1ns/1ps

// The dashboard math is intentionally software-defined in the RV32I demo.
// This unit test freezes its fixed-point contract, including zero and wrap.
module tb_perf_dashboard;
    function [31:0] cpi_x100;
        input [31:0] cycles, instret;
        begin cpi_x100 = (instret == 0) ? 0 : (cycles * 100) / instret; end
    endfunction
    function [31:0] ipc_x100;
        input [31:0] cycles, instret;
        begin ipc_x100 = (cycles == 0) ? 0 : (instret * 100) / cycles; end
    endfunction
    function [31:0] mips_x10;
        input [31:0] cycles, instret;
        begin mips_x10 = (cycles == 0) ? 0 : (instret * 1000) / cycles; end
    endfunction
    function [31:0] speedup_x100;
        input [31:0] normal_cycles, mac_cycles;
        begin speedup_x100 = (mac_cycles == 0) ? 0 : (normal_cycles * 100) / mac_cycles; end
    endfunction

    reg [31:0] c, i;
    initial begin
        c = 2582; i = 1000;
        if (cpi_x100(c,i) != 258 || ipc_x100(c,i) != 38 || mips_x10(c,i) != 387)
            $fatal(1, "CPI/IPC/MIPS fixed-point mismatch");
        if (speedup_x100(193,22) != 877) $fatal(1, "speedup mismatch");
        if (cpi_x100(10,0) != 0 || ipc_x100(0,10) != 0 ||
            mips_x10(0,10) != 0 || speedup_x100(10,0) != 0)
            $fatal(1, "divide-by-zero guard failed");
        if (cpi_x100(32'hFFFF_FFF0, 32'd2) != 32'h7FFF_FCE0)
            $fatal(1, "32-bit wrap contract failed");
        $display("PASS: performance dashboard fixed-point math/zero/wrap");
        $finish;
    end
endmodule
