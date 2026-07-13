//==============================================================================
// font_rom.v - Compact 8x8 uppercase/hex font used by the VGA dashboard
//==============================================================================

`timescale 1ns / 1ps

module font_rom (
    input  wire [7:0] char_code,
    input  wire [2:0] row,
    output reg  [7:0] pixels
);
    reg [63:0] glyph;
    reg [63:0] shifted;

    always @(*) begin
        case (char_code)
            "0": glyph = 64'h3C666E7666663C00;
            "1": glyph = 64'h1838181818187E00;
            "2": glyph = 64'h3C66060C30607E00;
            "3": glyph = 64'h3C66061C06663C00;
            "4": glyph = 64'h0C1C3C6C7E0C0C00;
            "5": glyph = 64'h7E607C0606663C00;
            "6": glyph = 64'h1C30607C66663C00;
            "7": glyph = 64'h7E66060C18181800;
            "8": glyph = 64'h3C66663C66663C00;
            "9": glyph = 64'h3C66663E060C3800;
            "A": glyph = 64'h183C66667E666600;
            "B": glyph = 64'h7C66667C66667C00;
            "C": glyph = 64'h3C66606060663C00;
            "D": glyph = 64'h786C6666666C7800;
            "E": glyph = 64'h7E60607860607E00;
            "F": glyph = 64'h7E60607860606000;
            "G": glyph = 64'h3C66606E66663E00;
            "H": glyph = 64'h6666667E66666600;
            "I": glyph = 64'h7E18181818187E00;
            "J": glyph = 64'h1E0C0C0C0C6C3800;
            "K": glyph = 64'h666C7870786C6600;
            "L": glyph = 64'h6060606060607E00;
            "M": glyph = 64'h63777F6B63636300;
            "N": glyph = 64'h66767E7E6E666600;
            "O": glyph = 64'h3C66666666663C00;
            "P": glyph = 64'h7C66667C60606000;
            "Q": glyph = 64'h3C6666666A6C3600;
            "R": glyph = 64'h7C66667C786C6600;
            "S": glyph = 64'h3C66603C06663C00;
            "T": glyph = 64'h7E18181818181800;
            "U": glyph = 64'h6666666666663C00;
            "V": glyph = 64'h66666666663C1800;
            "W": glyph = 64'h6363636B7F776300;
            "X": glyph = 64'h66663C183C666600;
            "Y": glyph = 64'h6666663C18181800;
            "Z": glyph = 64'h7E060C1830607E00;
            ":": glyph = 64'h0018180018180000;
            ".": glyph = 64'h0000000000181800;
            "-": glyph = 64'h0000007E00000000;
            "/": glyph = 64'h060C183060C08000;
            ">": glyph = 64'h6030180C18306000;
            "=": glyph = 64'h00007E007E000000;
            "%": glyph = 64'h62660C1830664600;
            "_": glyph = 64'h0000000000007E00;
            default: glyph = 64'h0000000000000000;
        endcase
        shifted = glyph >> ((3'd7 - row) * 8);
        pixels = shifted[7:0];
    end
endmodule
