# Project File Index

> Final synchronization: 2026-07-13.  The project has passed acceptance.
> This index describes the current repository rather than the initial empty
> skeleton recorded in historical planning documents.

## Read in this order

1. `README.md` - final scope, board operation, program/bitstream map.
2. `docs/design/architecture.md` - CPU/SoC structure.
3. `docs/design/isa.md` and `docs/design/mac_extension.md` - instruction set.
4. `docs/design/memory_map.md` and `docs/design/interfaces.md` - MMIO and ports.
5. `docs/design/test_plan.md` and `reports/tables/test_results.md` - verification evidence.
6. `reports/vivado/` and `reports/tables/ppa_comparison.md` - implementation evidence.

## Repository map

| Directory / file | Contents |
|---|---|
| `README.md` | Final project overview, operation guide, source/test/bitstream map and reproducibility notes |
| `constraints/minisys.xdc` | Minisys pins, I/O standards and 100 MHz timing constraint |
| `src/board/minisys_top.v` | FPGA top level; ports to board, VGA, buttons and switches; CPU mode parameter |
| `src/soc/soc_top.v` | SoC integration: CPU, memories, decoder, MMIO, performance counters and VGA |
| `src/core/alu.v` | Arithmetic and logical operations |
| `src/core/control_unit.v` | RV32I/MAC instruction decode and control signals |
| `src/core/regfile.v` | x0-fixed 32-register, 3-read/1-write register file for MAC |
| `src/core/riscv_mc_cpu.v` | Six-state RV32I multi-cycle FSM CPU, main VGA demo core |
| `src/core/riscv_pipeline_cpu.v` | Five-stage RV32I pipeline with forwarding/stall/flush logic |
| `src/core/csr_perf_counter.v` | Hardware cycle, retired-instruction and MAC counters |
| `src/core/mac_unit.v` | Custom MAC datapath |
| `src/core/pipeline/` | BTB and branch prediction helper |
| `src/bus/` | MMIO/data-RAM address decoding and read-data mux |
| `src/memory/` | Instruction/data RAM |
| `src/io/button_mmio.v` | Debounced/latched five-button MMIO event interface |
| `src/io/vga_mmio_regs.v` | CPU-written VGA field register bank |
| `src/io/vga_dashboard.v` | 640x480 dashboard, game, benchmark, trace and Tetris rendering |
| `src/io/font_rom.v` | VGA glyph data |
| `src/io/gpio_*.v`, `seg7_driver.v` | LED, switch and seven-segment MMIO peripherals |
| `src/io/kbd4x4_scanner.v`, `vga_test_pattern.v`, `vga_button_demo.v` | Earlier/auxiliary input and video prototypes; final user input is S1-S5 |
| `tests/` | Assembly source and generated `.hex` images for CPU/program-level checks |
| `sim/tb/` | XSim Verilog testbenches; each checks a defined module or CPU-MMIO sequence |
| `scripts/` | Vivado batch build/check scripts and game-program image builder |
| `processor_fpga/boot_rom.mem` | Program image consumed by the Vivado board project; generated from the selected `.hex` image |
| `reports/vivado/` | Selected checked-in implementation reports; generated run directories are excluded |
| `reports/tables/` | Performance, PPA, CPI, hazard and test-result tables |
| `reports/figures/` | HTML defense presentation and performance dashboard |
| `docs/ai_logs/` | AI use declaration and chronological audit log |

## Test and program index

| Path | Pairing testbench | Main assertion |
|---|---|---|
| `tests/basic/basic_test.S` | `tb_cpu_basic.v` | Arithmetic/memory CPU path reaches expected registers and RAM |
| `tests/basic/memory_sequence_game.S` | selected CPU simulation | Deterministic RAM sequence exercise |
| `tests/basic/switch_seg_game.S` | board/MMIO demonstration | Switch read and seven-segment write |
| `tests/load_store/lw_sw_test.S/.hex` | `tb_load_store.v` | `mem[0]=42`, `mem[1]=99`, `x5=141` |
| `tests/branch/beq_bne_test.S/.hex` | `tb_branch.v` | taken and not-taken BEQ/BNE; `x10=12` |
| `tests/mac/dot_normal.S/.hex` | `tb_dot_product.v` | Baseline dot product result 70 |
| `tests/mac/dot_mac.S/.hex` | `tb_dot_product.v` | MAC dot product result 70 and counter increment |
| `tests/perf/perf_mmio.S/.hex` | `tb_perf_mmio.v` | CPU reads cycle/instret/MAC MMIO snapshots |
| `tests/perf/retirement_test.S/.hex` | `tb_perf_integration.v` | Retirement events for ALU, memory, branch and MAC |
| `tests/pipeline/hazard_test.hex` | `tb_pipeline_hazard.v` | RAW forwarding, load-use stall and control flush |
| `tests/pipeline/branch_loop_test.S` | `tb_pipeline_btb.v` | Loop/BTB behavior |
| `tests/demo/cpu_guess_game.S/.hex` | game/benchmark/Tetris testbenches | Deployed CPU software for the four VGA pages |

### All testbenches

| Group | Testbenches | Coverage |
|---|---|---|
| Core units | `tb_alu`, `tb_regfile`, `tb_control_unit`, `tb_mac`, `tb_perf_counter` | Combinational/clocked core behaviour and decode |
| Multi-cycle CPU | `tb_cpu_basic`, `tb_load_store`, `tb_branch`, `tb_dot_product`, `tb_perf_integration`, `tb_perf_mmio` | Instruction execution, memory, branches, MAC and performance MMIO |
| Pipeline | `tb_pipeline_basic`, `tb_pipeline_hazard`, `tb_pipeline_btb` | Basic flow, hazards/forwarding/stalls/flushes and BTB |
| VGA/MMIO | `tb_button_mmio`, `tb_vga_mmio`, `tb_vga_perf_snapshot`, `tb_perf_dashboard` | Button event path, display-field writes and stable performance snapshot |
| CPU game | `tb_cpu_game_mmio`, `tb_benchmark`, `tb_cpu_benchmark_select`, `tb_cpu_tetris_mmio`, `tb_tetris_geometry` | CPU-controlled guessing game, all benchmark selections, Tetris input/state and geometry |

## Build and bitstream index

| Script / image | Purpose |
|---|---|
| `scripts/build_cpu_guess_game.ps1` | Assemble/convert the VGA game program to a `.hex` ROM image |
| `scripts/check_cpu_vga_rtl.tcl` | Read RTL and run CPU/VGA-oriented Vivado checks |
| `scripts/build_cpu_vga_bitstream.tcl` | Build the main `CPU_MODE=0` VGA demonstration image |
| `scripts/build_cpu_vga_pipeline.tcl` | Build `CPU_MODE=5` pipeline configuration and export PPA evidence |
| `scripts/build_cpu_vga_standalone.tcl` | Standalone CPU/VGA implementation flow |
| `build_cpu_vga/minisys_top_cpu_vga.bit` | Local generated main VGA bitstream, ignored by Git |
| `processor_fpga/minisys_top_cpu_tetris.bit` | Local archived Tetris/VGA bitstream, ignored by Git |
| `processor_fpga/processor_fpga.runs/impl_1/minisys_top.bit` | Mutable Vivado implementation output, ignored by Git |

## Documentation sets

| Directory | Purpose |
|---|---|
| `docs/design/` | Architecture, ISA, interface, memory map, game plan, test plan and board design |
| `docs/planning/` | Historical project decisions, completion checklist, pipeline build guidance and defense preparation |
| `docs/team/` | Roles, reviews and historical collaboration process |
| `docs/hardware/` | Board pinout and hardware notes |
| `docs/changelogs/` | Earlier change record |
| `docs/ai_logs/` | AI assistance declaration and immutable-style work record |

## Evidence handling

Only source and selected textual evidence are versioned.  `.runs`, `.cache`,
`.Xil`, `.wdb`, `.log`, bitstreams and other generated Vivado state are excluded
by `.gitignore`.  When reproducing PPA, archive the utilization and timing
reports from the exact `CPU_MODE`/program/constraint combination being cited.
