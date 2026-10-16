/* Per-lap best commit @ 0x1C940 — call from slot3 after line cross (id 0).
 * Compares 0x2020d0[lap] to SRAM best @ 0x1d00300 + car*0x194; updates when
 * best==0 or this lap is strictly faster; bumps 0x2020c0; redraws HUD.
 * source: disasm/maincpu/maincpu_01c940_80.asm */
// @rom 0x1c940 +0x80 game_start_race_lap_best

#include "i960_lift.h"
#include "i960_mem.h"

#include "lift_syms.h"

void game_start_race_lap_best(u32 arg0, u32 arg1, u32 arg2)
{
    u32 car;
    u32 stride = 0x194u;
    u32 best_ea;
    u32 best;
    u32 lap;
    u32 this_lap;

    (void)arg0;
    (void)arg1;
    (void)arg2;

    car = i960_ld_u32(I960_WORKRAM, 0x214354, 0);
    best_ea = 0x01d00300u + car * stride;
    best = i960_ld_u32(I960_ABS, best_ea, 0);
    lap = i960_ld_u32(I960_WORKRAM, 0x2020c0, 0);

    /* @0x1C960: best==0 → always take; else skip when this_lap >= best. */
    if (best != 0u) {
        this_lap = i960_ld_u32(I960_WORKRAM, 0x2020d0u + (lap << 2), 0);
        if (this_lap >= best)
            goto bump_lap;
    }

    car = i960_ld_u32(I960_WORKRAM, 0x214354, 0);
    this_lap = i960_ld_u32(I960_WORKRAM, 0x2020d0u + (lap << 2), 0);
    best_ea = 0x01d00300u + car * stride;
    i960_st_u32(I960_ABS, best_ea, 0, this_lap);
    i960_st_u32(I960_ABS, 0x01d002e8u, 0, 1u);
    g0 = 14u;
    comm_palette_index_call(14u);

bump_lap:
    lap = i960_ld_u32(I960_WORKRAM, 0x2020c0, 0);
    i960_st_u32(I960_WORKRAM, 0x2020c0, 0, lap + 1u);
    g0 = (u32)-1;
    game_start_race_hud_lap_time((u32)g0, 0, 0);
}
