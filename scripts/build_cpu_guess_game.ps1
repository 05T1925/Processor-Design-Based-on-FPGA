param(
    [string]$Source = "tests/demo/cpu_guess_game.S",
    [string]$Output = "tests/demo/cpu_guess_game.hex",
    [switch]$InstallBootRom
)

$ErrorActionPreference = "Stop"

function Parse-Number([string]$text) {
    if ($text.StartsWith("-0x")) { return -[Convert]::ToInt32($text.Substring(3), 16) }
    if ($text.StartsWith("0x")) { return [Convert]::ToInt32($text.Substring(2), 16) }
    return [int]$text
}
function Reg([string]$text) {
    if ($text -notmatch '^x([0-9]|[12][0-9]|3[01])$') { throw "Bad register: $text" }
    return [int]$Matches[1]
}
function U32([int64]$value) { return [uint32]($value -band [int64]4294967295) }
function Enc-I($opcode,$funct3,$rd,$rs1,$imm) {
    U32((([int64]$imm -band 0xFFF) -shl 20) -bor ($rs1 -shl 15) -bor
        ($funct3 -shl 12) -bor ($rd -shl 7) -bor $opcode)
}
function Enc-R($opcode,$funct3,$funct7,$rd,$rs1,$rs2) {
    U32(($funct7 -shl 25) -bor ($rs2 -shl 20) -bor ($rs1 -shl 15) -bor
        ($funct3 -shl 12) -bor ($rd -shl 7) -bor $opcode)
}
function Enc-S($funct3,$rs1,$rs2,$imm) {
    $u = [int64]$imm -band 0xFFF
    U32((($u -shr 5) -shl 25) -bor ($rs2 -shl 20) -bor ($rs1 -shl 15) -bor
        ($funct3 -shl 12) -bor (($u -band 0x1F) -shl 7) -bor 0x23)
}
function Enc-B($funct3,$rs1,$rs2,$imm) {
    $u = [int64]$imm -band 0x1FFF
    U32(((($u -shr 12) -band 1) -shl 31) -bor ((($u -shr 5) -band 0x3F) -shl 25) -bor
        ($rs2 -shl 20) -bor ($rs1 -shl 15) -bor ($funct3 -shl 12) -bor
        ((($u -shr 1) -band 0xF) -shl 8) -bor ((($u -shr 11) -band 1) -shl 7) -bor 0x63)
}
function Enc-U($opcode,$rd,$imm20) {
    U32((([uint64]$imm20 -band 0xFFFFF) -shl 12) -bor ($rd -shl 7) -bor $opcode)
}
function Enc-J($rd,$imm) {
    $u = [int64]$imm -band 0x1FFFFF
    U32(((($u -shr 20) -band 1) -shl 31) -bor ((($u -shr 1) -band 0x3FF) -shl 21) -bor
        ((($u -shr 11) -band 1) -shl 20) -bor ((($u -shr 12) -band 0xFF) -shl 12) -bor
        ($rd -shl 7) -bor 0x6F)
}

$instructions = New-Object System.Collections.Generic.List[object]
$labels = @{}
$pc = 0
foreach ($raw in Get-Content -LiteralPath $Source) {
    $line = ($raw -replace '#.*$', '').Trim()
    if (!$line) { continue }
    if ($line.EndsWith(':')) {
        $labels[$line.Substring(0, $line.Length - 1)] = $pc
    } else {
        $instructions.Add([pscustomobject]@{ Pc=$pc; Text=$line })
        $pc += 4
    }
}

$words = New-Object System.Collections.Generic.List[uint32]
foreach ($item in $instructions) {
    $tokens = $item.Text -split '[,\s()]+' | Where-Object { $_ }
    $op = $tokens[0].ToLowerInvariant()
    $word = switch ($op) {
        'addi' { Enc-I 0x13 0 (Reg $tokens[1]) (Reg $tokens[2]) (Parse-Number $tokens[3]); break }
        'andi' { Enc-I 0x13 7 (Reg $tokens[1]) (Reg $tokens[2]) (Parse-Number $tokens[3]); break }
        'ori'  { Enc-I 0x13 6 (Reg $tokens[1]) (Reg $tokens[2]) (Parse-Number $tokens[3]); break }
        'srli' { Enc-I 0x13 5 (Reg $tokens[1]) (Reg $tokens[2]) (Parse-Number $tokens[3]); break }
        'slli' { Enc-I 0x13 1 (Reg $tokens[1]) (Reg $tokens[2]) (Parse-Number $tokens[3]); break }
        'add'  { Enc-R 0x33 0 0x00 (Reg $tokens[1]) (Reg $tokens[2]) (Reg $tokens[3]); break }
        'sub'  { Enc-R 0x33 0 0x20 (Reg $tokens[1]) (Reg $tokens[2]) (Reg $tokens[3]); break }
        'xor'  { Enc-R 0x33 4 0x00 (Reg $tokens[1]) (Reg $tokens[2]) (Reg $tokens[3]); break }
        'or'   { Enc-R 0x33 6 0x00 (Reg $tokens[1]) (Reg $tokens[2]) (Reg $tokens[3]); break }
        'sltu' { Enc-R 0x33 3 0x00 (Reg $tokens[1]) (Reg $tokens[2]) (Reg $tokens[3]); break }
        'lw'   { Enc-I 0x03 2 (Reg $tokens[1]) (Reg $tokens[3]) (Parse-Number $tokens[2]); break }
        'sw'   { Enc-S 2 (Reg $tokens[3]) (Reg $tokens[1]) (Parse-Number $tokens[2]); break }
        'beq'  { Enc-B 0 (Reg $tokens[1]) (Reg $tokens[2]) ($labels[$tokens[3]] - $item.Pc); break }
        'bne'  { Enc-B 1 (Reg $tokens[1]) (Reg $tokens[2]) ($labels[$tokens[3]] - $item.Pc); break }
        'blt'  { Enc-B 4 (Reg $tokens[1]) (Reg $tokens[2]) ($labels[$tokens[3]] - $item.Pc); break }
        'bge'  { Enc-B 5 (Reg $tokens[1]) (Reg $tokens[2]) ($labels[$tokens[3]] - $item.Pc); break }
        'bltu' { Enc-B 6 (Reg $tokens[1]) (Reg $tokens[2]) ($labels[$tokens[3]] - $item.Pc); break }
        'lui'  { Enc-U 0x37 (Reg $tokens[1]) (Parse-Number $tokens[2]); break }
        'jal'  { Enc-J (Reg $tokens[1]) ($labels[$tokens[2]] - $item.Pc); break }
        'jalr' { Enc-I 0x67 0 (Reg $tokens[1]) (Reg $tokens[3]) (Parse-Number $tokens[2]); break }
        'mac'  { Enc-R 0x0B 0 0x01 (Reg $tokens[1]) (Reg $tokens[2]) (Reg $tokens[3]); break }
        default { throw "Unsupported instruction at $($item.Pc): $($item.Text)" }
    }
    $words.Add([uint32]$word)
}

$hex = $words | ForEach-Object { $_.ToString('X8') }
$outputDir = Split-Path -Parent $Output
if ($outputDir) { New-Item -ItemType Directory -Force -Path $outputDir | Out-Null }
Set-Content -LiteralPath $Output -Value $hex -Encoding ASCII
if ($InstallBootRom) {
    Set-Content -LiteralPath 'processor_fpga/boot_rom.mem' -Value $hex -Encoding ASCII
    Set-Content -LiteralPath 'processor_fpga/boot_rom.hex' -Value $hex -Encoding ASCII
}
Write-Host "Generated $($words.Count) instructions from $Source -> $Output"
