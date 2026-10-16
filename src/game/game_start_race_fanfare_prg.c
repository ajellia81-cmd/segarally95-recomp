/* Race fanfare GEO PRG handlers — installed into 0x20ab50 by slot4/slot5.
 *
 * Each race_frame invokes geo_prg_slot(0) → callx(handler). Without these
 * lifts, staging_call_lifted misses the resolved ROM PC and ab60 never
 * ticks, so 2020ac never advances past the YOU WIN / time-up hold.
 *
 * Progression (disasm):
 *   0x20cf0 practice course-complete: ab60 > 480 → 2020ac += 1
 *   0x20e70 practice time-up:         ab60 > 480 → 2020ac += 7
 *   0x20ff0 champ time-up:            ab60 > 480 → 2020ac += 1
 *   0x20880 / 0x20a50 champ class win: at ab60==120 install continue PRG
 *   0x207c0 / 0x20990 continue:       ab60 > 480 → 2020ac += 1
 *   0x20bf0 champ class-3 win:        ab60 > 420 → 2020ac += 1
 *
 * Display/sound leaves (269d0 / 29eb0 / …) omitted — tick + scene advance
 * are enough to leave the fanfare hold.
 *
 * source: disasm maincpu_020cf0 / 020e70 / 020ff0 / 020880 / 0207c0 /
 *         020a50 / 020990 / 020bf0
 */
// @rom 0x20cf0 +0x180 game_start_race_fanfare_practice_win
// @rom 0x20e70 +0x180 game_start_race_fanfare_practice_dnf
// @rom 0x20ff0 +0x180 game_start_race_fanfare_champ_dnf
// @rom 0x20880 +0x100 game_start_race_fanfare_champ_win_0
// @rom 0x207c0 +0xc0  game_start_race_fanfare_champ_win_0_cont
// @rom 0x20a50 +0x140 game_start_race_fanfare_champ_win_2
// @rom 0x20990 +0xc0  game_start_race_fanfare_champ_win_2_cont
// @rom 0x20bf0 +0x100 game_start_race_fanfare_champ_win_3

#include "i960_lift.h"
#include "lift_log.h"
#include "i960_mem.h"

#include "lift_syms.h"

#include <stdio.h>

static void fanfare_tick(u32 threshold, u32 advance)
{
    u32 ab60 = i960_ld_u32(I960_WORKRAM, 0x20ab60, 0);

    /* cmpible ab60, threshold → skip; else 2020ac += advance. */
    if (ab60 > threshold) {
        u32 ac = i960_ld_u32(I960_WORKRAM, 0x2020ac, 0);

        i960_st_u32(I960_WORKRAM, 0x2020ac, 0, ac + advance);
    }
    i960_st_u32(I960_WORKRAM, 0x20ab60, 0, ab60 + 1u);
}

void game_start_race_fanfare_practice_win(u32 arg0, u32 arg1, u32 arg2)
{
    static int logged;

    (void)arg0;
    (void)arg1;
    (void)arg2;
    if (!logged) {
        lift_log("lift: fanfare_practice_win (0x20cf0)\n");
        fflush(stderr);
        logged = 1;
    }
    /* shlo 5,15 → 480 */
    fanfare_tick(480u, 1u);
}

void game_start_race_fanfare_practice_dnf(u32 arg0, u32 arg1, u32 arg2)
{
    static int logged;

    (void)arg0;
    (void)arg1;
    (void)arg2;
    if (!logged) {
        lift_log("lift: fanfare_practice_dnf (0x20e70)\n");
        fflush(stderr);
        logged = 1;
    }
    fanfare_tick(480u, 7u);
}

void game_start_race_fanfare_champ_dnf(u32 arg0, u32 arg1, u32 arg2)
{
    static int logged;

    (void)arg0;
    (void)arg1;
    (void)arg2;
    if (!logged) {
        lift_log("lift: fanfare_champ_dnf (0x20ff0)\n");
        fflush(stderr);
        logged = 1;
    }
    fanfare_tick(480u, 1u);
}

void game_start_race_fanfare_champ_win_0_cont(u32 arg0, u32 arg1, u32 arg2)
{
    static int logged;

    (void)arg0;
    (void)arg1;
    (void)arg2;
    if (!logged) {
        lift_log("lift: fanfare_champ_win_0_cont (0x207c0)\n");
        fflush(stderr);
        logged = 1;
    }
    fanfare_tick(480u, 1u);
}

void game_start_race_fanfare_champ_win_2_cont(u32 arg0, u32 arg1, u32 arg2)
{
    static int logged;

    (void)arg0;
    (void)arg1;
    (void)arg2;
    if (!logged) {
        lift_log("lift: fanfare_champ_win_2_cont (0x20990)\n");
        fflush(stderr);
        logged = 1;
    }
    fanfare_tick(480u, 1u);
}

void game_start_race_fanfare_champ_win_0(u32 arg0, u32 arg1, u32 arg2)
{
    u32 ab60;
    static int logged;

    (void)arg1;
    (void)arg2;
    if (!logged) {
        lift_log("lift: fanfare_champ_win_0 (0x20880)\n");
        fflush(stderr);
        logged = 1;
    }

    ab60 = i960_ld_u32(I960_WORKRAM, 0x20ab60, 0);
    /*
     * shlo 3,15 → 120: st next PRG through g0 (geo_prg_slot sets
     * g0=0x20ab50 before callx).
     */
    if (ab60 == (15u << 3)) {
        u32 slot = arg0 ? arg0 : 0x0020ab50u;

        i960_st_u32(I960_ABS, slot, 0, 0x005bf7c0u);
    }
    i960_st_u32(I960_WORKRAM, 0x20ab60, 0, ab60 + 1u);
}

void game_start_race_fanfare_champ_win_2(u32 arg0, u32 arg1, u32 arg2)
{
    u32 ab60;
    static int logged;

    (void)arg1;
    (void)arg2;
    if (!logged) {
        lift_log("lift: fanfare_champ_win_2 (0x20a50)\n");
        fflush(stderr);
        logged = 1;
    }

    ab60 = i960_ld_u32(I960_WORKRAM, 0x20ab60, 0);
    if (ab60 == (15u << 3)) {
        u32 slot = arg0 ? arg0 : 0x0020ab50u;

        i960_st_u32(I960_ABS, slot, 0, 0x005bf990u);
    }
    i960_st_u32(I960_WORKRAM, 0x20ab60, 0, ab60 + 1u);
}

void game_start_race_fanfare_champ_win_3(u32 arg0, u32 arg1, u32 arg2)
{
    static int logged;

    (void)arg0;
    (void)arg1;
    (void)arg2;
    if (!logged) {
        lift_log("lift: fanfare_champ_win_3 (0x20bf0)\n");
        fflush(stderr);
        logged = 1;
    }
    /* lda 0x1a4 → 420 */
    fanfare_tick(0x1a4u, 1u);
}
