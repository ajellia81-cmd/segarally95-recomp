/* Best-time name field copy @ 0x1EB88 — bal from lap_record @ 0x183D0.
 * mov g14,g1; clear g14; g6=0; g7=47; copy words from 0x20aed0 into
 * 0x14(g0)… until g6 > 47 (48 stores).
 * source: disasm/maincpu/maincpu_01eb88_3c.asm */
// @rom 0x1eb88 +0x3c game_start_race_name_copy

#include "i960_lift.h"
#include "i960_mem.h"

void game_start_race_name_copy(u32 arg0, u32 arg1, u32 arg2)
{
    u32 dst = arg0 != 0u ? arg0 : (u32)g0;
    u32 src = 0x0020aed0u;
    u32 g6 = 0u;
    u32 g7 = 31u + 16u; /* @0x1EB9C */

    (void)arg1;
    (void)arg2;

    g14 = 0;
    for (;;) {
        u32 w = i960_ld_u32(I960_WORKRAM, src, 0);

        src += 4u;
        g6 += 1u;
        i960_st_u32(I960_ABS, dst + 0x14u, 0, w);
        dst += 4u;
        if ((i32)g6 > (i32)g7)
            break;
    }
}
