/* Championship post-fanfare scene slot @ 0x1BE40 — table 0x5BA820[4].
 *
 * After YOU WIN / DNF fanfare PRG bumps 0x2020ac to 4, attract_scene_slot
 * dispatch callx's here. Advances 0x214354 (course) and adjusts 0x2020ac
 * to re-enter hud_setup / race or results.
 *
 * 2020b0 != 0 → course complete (slot3 st 1); == 0 → unfinished / DNF path.
 *
 * source: disasm/maincpu/maincpu_01be40_120.asm */
// @rom 0x1be40 +0x110 game_start_race_champ_course_advance

#include "i960_lift.h"
#include "lift_log.h"
#include "i960_mem.h"

#include "lift_syms.h"

#include <stdio.h>

void game_start_race_champ_course_advance(u32 arg0, u32 arg1, u32 arg2)
{
    u32 course;
    u32 done;
    u32 ac;
    static int logged;

    (void)arg0;
    (void)arg1;
    (void)arg2;

    course = i960_ld_u32(I960_WORKRAM, 0x214354, 0);
    done = i960_ld_u32(I960_WORKRAM, 0x2020b0, 0);

    if (!logged) {
        lift_log("lift: champ_course_advance course=%u done=%u ac=%u\n",
                 (unsigned)course, (unsigned)done,
                 (unsigned)i960_ld_u32(I960_WORKRAM, 0x2020ac, 0));
        fflush(stderr);
        logged = 1;
    }

    /* @0x1BE50: cmpibne 3,course → 1be78. */
    if (course == 3u) {
        /* @0x1BE54: cmpibne 0,done → 1bef4 (ac += 1). */
        if (done != 0u) {
            ac = i960_ld_u32(I960_WORKRAM, 0x2020ac, 0);
            i960_st_u32(I960_WORKRAM, 0x2020ac, 0, ac + 1u);
            return;
        }
        /* course==3 && done==0: clear 2020c8; ac += 6. */
        g14 = 0;
        i960_st_u32(I960_WORKRAM, 0x2020c8, 0, 0u);
        ac = i960_ld_u32(I960_WORKRAM, 0x2020ac, 0);
        i960_st_u32(I960_WORKRAM, 0x2020ac, 0, ac + 6u);
        return;
    }

    /* @0x1BE78: cmpibe 0,done → 1bf38 (ac += 5). */
    if (done == 0u) {
        ac = i960_ld_u32(I960_WORKRAM, 0x2020ac, 0);
        i960_st_u32(I960_WORKRAM, 0x2020ac, 0, ac + 5u);
        return;
    }

    /* done != 0, course != 3. */
    course = i960_ld_u32(I960_WORKRAM, 0x214354, 0);
    if (course == 2u) {
        /* @0x1BE88–0x1BE9C: g0=2020b8; 214354=−1; call lap_record. */
        g0 = i960_ld_u32(I960_WORKRAM, 0x2020b8, 0);
        i960_st_u32(I960_WORKRAM, 0x214354, 0, (u32)-1);
        game_start_race_lap_record((u32)g0, 0, 0);

        if (i960_ld_u32(I960_WORKRAM, 0x2020c8, 0) == 0u) {
            /* @0x1BEAC–0x1BECC: 214354=3; ac -= 2. */
            i960_st_u32(I960_WORKRAM, 0x214354, 0, 3u);
            ac = i960_ld_u32(I960_WORKRAM, 0x2020ac, 0);
            i960_st_u32(I960_WORKRAM, 0x2020ac, 0, ac - 2u);
            return;
        }
        /* @0x1BED0–0x1BEE4: 214354=2; fall through to ac += 1. */
        i960_st_u32(I960_WORKRAM, 0x214354, 0, 2u);
        ac = i960_ld_u32(I960_WORKRAM, 0x2020ac, 0);
        i960_st_u32(I960_WORKRAM, 0x2020ac, 0, ac + 1u);
        return;
    }

    /* @0x1BEE8: cmpibne 3,course → 1bf0c. */
    course = i960_ld_u32(I960_WORKRAM, 0x214354, 0);
    if (course == 3u) {
        ac = i960_ld_u32(I960_WORKRAM, 0x2020ac, 0);
        i960_st_u32(I960_WORKRAM, 0x2020ac, 0, ac + 1u);
        return;
    }

    /* @0x1BF0C–0x1BF34: course += 1; ac -= 2 (re-enter hud_setup/race). */
    ac = i960_ld_u32(I960_WORKRAM, 0x2020ac, 0);
    i960_st_u32(I960_WORKRAM, 0x214354, 0, course + 1u);
    i960_st_u32(I960_WORKRAM, 0x2020ac, 0, ac - 2u);
}
