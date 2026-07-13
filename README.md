# FPGA RISC-V CPU: VGA Games and Performance Visualization

## Final status

This course project is complete and has passed acceptance.  It implements an
RV32I subset CPU on the Minisys FPGA board, a custom MAC instruction, MMIO
peripherals, CPU-driven VGA guessing-number and Tetris pages, and a selectable
five-stage pipeline implementation with forwarding, stalls, flushes and a BTB.

The main demonstration image is the multi-cycle RV32I version because its CPU,
MMIO, VGA game flow and counter data are easy to observe on the board.  The
pipeline implementation, its test/on-board verification and PPA work have also
been completed by the teammate responsible for that delivery.  Do not describe
model estimates as measured PPA; use the exported Vivado reports supplied with
the final delivery for exact pipeline numbers.

| Item | Final state |
|---|---|
| RV32I multi-cycle CPU | Complete; 31 RV32I-subset instructions plus custom MAC; EBREAK is a test/halt helper |
| Five-stage pipeline | Complete; forwarding, load-use stall, control flush and BTB are implemented |
| CPU-driven VGA | Complete; PAGE 1 registers/guessing, PAGE 2 benchmark, PAGE 3 trace, PAGE 4 Tetris |
| MMIO performance counters | Complete; cycles, retired instructions and MAC count are read by CPU software |
| Board demonstration | Complete; switches and S1-S5 drive the CPU program through MMIO |
| Simulation and PPA | Core/game testbenches and final pipeline verification are complete; archive Vivado reports with the delivery evidence |

## Platform and architecture

- Board: Minisys FPGA with EES-329B-V1.1, Xilinx Artix-7 XC7A100T-FGG484
- Toolchain: Vivado 2018.3 and Vivado XSim
- Clock constraint: 100 MHz
- CPU modes: `CPU_MODE=0` multi-cycle RV32I, `CPU_MODE=5` five-stage RV32I pipeline
- Memory: instruction RAM and data RAM each default to 32 KiB
- External interfaces: 16 switches, 5 push buttons, LEDs, 8-digit seven-segment display, VGA and inactive 4x4 keypad pins

```text
buttons / switches -> button_mmio / GPIO -> CPU LW
                                          |
CPU SW -> VGA MMIO registers -> VGA dashboard -> display
          performance counters <- CPU execution events
```

The counters are real hardware signals.  `cycle_count`, `instret_count` and
`mac_count` are generated in `csr_perf_counter.v`; the program reads them via
MMIO and commits display fields.  Thus the VGA page displays CPU-observed
hardware values rather than a host-side fabricated value.

## Source tree

| Path | Contents and role |
|---|---|
| `src/core/` | ALU, decoder, immediate/branch logic, register file, multi-cycle CPU, pipeline CPU, MAC and performance counters |
| `src/core/pipeline/` | 16-entry BTB and branch-prediction helper |
| `src/bus/` | Data-bus address decoder and read-data mux |
| `src/memory/` | Instruction/data RAM implementation |
| `src/io/` | LED, switch, seven-segment, button MMIO, VGA register bank/dashboard/font and optional keypad/test-pattern modules |
| `src/soc/soc_top.v` | Integrates CPU, memories, MMIO decode, counters and all visible peripherals |
| `src/board/minisys_top.v` | Board top-level and pin-facing port list; `CPU_MODE` selects core |
| `constraints/minisys.xdc` | Minisys board constraints and 100 MHz timing constraint |
| `tests/` | Assembly programs and their generated machine-code images |
| `sim/tb/` | XSim testbenches: unit, CPU, MMIO, game, Tetris, benchmark and pipeline coverage |
| `scripts/` | Build/check Tcl and game-program conversion scripts |
| `reports/` | Vivado reports, performance/PPA tables and defense HTML material |
| `docs/` | ISA, interfaces, memory map, design history, test plan, team records and AI audit log |

Detailed current file descriptions are in [docs/PROJECT_INDEX.md](docs/PROJECT_INDEX.md).

## CPU and MMIO highlights

The normal instruction-set description is in `docs/design/isa.md`.  The public
acceptance wording is **31 RV32I-subset instructions + 1 custom MAC = 32 main
functional instructions**.  `EBREAK` exists in RTL to finish tests but is not
counted as one of those 32 main instructions.

The custom `MAC` encoding uses RISC-V `custom-0` (`opcode=0001011`,
`funct3=000`, `funct7=0000001`) and performs:

```text
rd = old(rd) + rs1 * rs2
```

The third register-file read port provides `old(rd)`.  This is the main
instruction-set extension and is counted by the performance counter.

Key performance-counter MMIO addresses:

| Address | Value |
|---|---|
| `0xFFFF_FCB0` | non-HALT CPU cycle count |
| `0xFFFF_FCB4` | retired instruction count |
| `0xFFFF_FCB8` | completed MAC instruction count |

PAGE 2 uses fixed-point fields: `CPI X100=(cycles*100)/instret`, `IPC
X100=(instret*100)/cycles`, `MIPS X10=(instret*1000)/cycles`.  Benchmark
results appear after S5 launches the selected workload; `MAC CYC` is meaningful
for the MAC workload, and may legitimately be zero for other workloads.

## Demonstration operation

`SW[2:0]` selects the VGA page/mode.  The deployed game program is
`tests/demo/cpu_guess_game.hex` (copied into `processor_fpga/boot_rom.mem` for
bitstream generation).  S1-S5 are sampled through MMIO, so a button action is
visible as CPU `LW -> branch -> VGA MMIO SW` activity.

| Page/mode | Purpose | S1-S5 behaviour |
|---|---|---|
| Guessing-number page | Enter a three-digit guess; target changes periodically | S1 selects digit, S2/S3 adjust it, S5 submits; the screen reports low/high/correct |
| Performance page | Select and run BRANCH/MEMORY/MAC/MIXED workloads | S1/S2 select benchmark; S5 runs it; data fields show counters and result |
| Trace page | Shows CPU/bus execution information | Observe during normal program execution |
| `SW[2:0]=100` Tetris | CPU-driven Tetris state sent to VGA MMIO | S1 left, S2 right, S3 soft drop/restart when paused, S4 rotate, S5 pause/resume |

The board keys are active through `button_mmio.v`; the original 4x4 keypad is
kept electrically inactive because the final demonstration route uses the
verified S1-S5 buttons.

## Test programs and bitstream relationship

| Program / test | What it verifies | Intended image/use |
|---|---|---|
| `tests/demo/cpu_guess_game.S/.hex` | Full CPU-MMIO game loop, page selection, benchmark dispatch, 30 s target refresh, Tetris game state and VGA field commits | Main VGA game image; build script copies it to `processor_fpga/boot_rom.mem` |
| `tests/basic/basic_test.S` | Basic arithmetic, memory and halt checkpoints | `tb_cpu_basic.v` unit/system simulation |
| `tests/basic/memory_sequence_game.S` | Deterministic data-RAM sequence processing | Basic memory exercise, not the VGA deployment image |
| `tests/basic/switch_seg_game.S` | Switch input and seven-segment MMIO | LED/SEG7 board/MMIO demonstration |
| `tests/load_store/lw_sw_test.S/.hex` | Two stores, two loads and add-back: `42 + 99 = 141` | `tb_load_store.v` |
| `tests/branch/beq_bne_test.S/.hex` | Taken/not-taken BEQ and BNE; final `x10=12` | `tb_branch.v` |
| `tests/mac/dot_normal.S/.hex` | 4-element dot product with ordinary RV32I operations; result 70 | `tb_dot_product.v` baseline |
| `tests/mac/dot_mac.S/.hex` | Same dot product with four custom MACs; result 70 | `tb_dot_product.v` MAC comparison |
| `tests/perf/perf_mmio.S/.hex` | CPU reads all three performance-counter MMIO registers | `tb_perf_mmio.v` |
| `tests/perf/retirement_test.S/.hex` | Retirement accounting for ALU, memory, branch and MAC | `tb_perf_integration.v` |
| `tests/pipeline/hazard_test.hex` | RAW forwarding, load-use stall, branch/JAL flush checks | `tb_pipeline_hazard.v` |
| `tests/pipeline/branch_loop_test.S` | Repetitive branches for BTB/pipeline behaviour | `tb_pipeline_btb.v` and pipeline evaluation |

### Testbench map

- Unit and basic CPU: `tb_alu`, `tb_regfile`, `tb_control_unit`, `tb_cpu_basic`, `tb_load_store`, `tb_branch`, `tb_mac`, `tb_perf_counter`, `tb_perf_integration`, `tb_perf_mmio`, `tb_dot_product`.
- Pipeline: `tb_pipeline_basic`, `tb_pipeline_hazard`, `tb_pipeline_btb`.
- VGA/MMIO/game: `tb_button_mmio`, `tb_vga_mmio`, `tb_vga_perf_snapshot`, `tb_perf_dashboard`, `tb_cpu_game_mmio`, `tb_benchmark`, `tb_cpu_benchmark_select`, `tb_cpu_tetris_mmio`, `tb_tetris_geometry`.

The latter group validates the real control path, not only screen pixels: it
checks button acknowledgement, CPU reads from button MMIO, CPU writes to VGA
MMIO, benchmark selection/result commits, Tetris edge movement/rotation/drop
and restart behaviour.

### Bitstream files

Bitstreams are deliberately ignored by Git because each is a large Vivado
generated binary.  Their role is:

| File | Role |
|---|---|
| `build_cpu_vga/minisys_top_cpu_vga.bit` | Generated VGA CPU demonstration image when present locally |
| `processor_fpga/minisys_top_cpu_tetris.bit` | Locally archived CPU-driven Tetris/VGA image |
| `processor_fpga/processor_fpga.runs/impl_1/minisys_top.bit` | Vivado implementation output; may be overwritten by the next build |

Build scripts are more durable than those files: `scripts/build_cpu_vga_bitstream.tcl`
builds the main multi-cycle VGA image, and `scripts/build_cpu_vga_pipeline.tcl`
builds the `CPU_MODE=5` pipeline variant.  Keep a copied, date-stamped bit file
beside the acceptance evidence rather than committing generated binaries.

## Reproducible checks

1. Run `scripts/check_cpu_vga_rtl.tcl` in Vivado for RTL compile/lint checks.
2. Add all source files and the selected `sim/tb/tb_*.v` to XSim, then run the
   matching testbench from the mapping above.
3. For the main board image, generate `tests/demo/cpu_guess_game.hex`, copy it
   to `processor_fpga/boot_rom.mem`, then run
   `scripts/build_cpu_vga_bitstream.tcl`.
4. For the pipeline, run `scripts/build_cpu_vga_pipeline.tcl` with the same
   constraints and capture utilization/timing reports as final evidence.

The checked-in current VGA SoC report in `reports/vivado/` is directly
traceable: WNS `+0.464 ns`, TNS `0`, WHS `+0.030 ns`, THS `0`, 23,859 LUTs,
3,907 registers and 3 DSP48E1s.  These figures include VGA/dashboard logic and
must not be confused with an isolated CPU core.  Pipeline PPA values must be
taken from that pipeline implementation run's reports.

## Documentation and evidence

- Architecture: `docs/design/architecture.md`
- ISA / MAC: `docs/design/isa.md`, `docs/design/mac_extension.md`
- Memory map / interfaces: `docs/design/memory_map.md`, `docs/design/interfaces.md`
- Test plan and board operation: `docs/design/test_plan.md`, `docs/design/board_demo.md`
- Final task state: `docs/design/task_board.md`, `docs/planning/progress_checklist.md`
- Vivado evidence: `reports/vivado/`, `reports/tables/ppa_comparison.md`
- Defense material: `reports/figures/defense_presentation.html`
- AI use record: `docs/ai_logs/ai_usage_log.md`

## Repository hygiene

Do not commit `.runs/`, `.cache/`, `.Xil/`, `.wdb`, `.log`, bitstreams or other
Vivado-generated state.  They are intentionally ignored.  Commit RTL, assembly
programs, testbenches, build scripts, source documentation and selected final
text reports only.
