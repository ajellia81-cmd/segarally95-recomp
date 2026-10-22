/* Existing desktop scene policy, copied verbatim; keep in sync with sys24_viewer.c. */
#include "i960_mem.h"
static int viewer_is_splash_hold(u32 inner, u32 frame)
{
    /*
     * Splash bind seeds a negative hold in 0x20a808:
     *   inner2 → 0xfffffe5c (−420), inner4/6 → 0xffffff88 (−120).
     * Hold while signed frame < 0.
     */
    return (inner == 2u || inner == 4u || inner == 6u) && (i32)frame < 0;
}

/* Operator menu (main mode 4) is pure Sys24 tiles — no 3D underlay. */
static int viewer_is_test_menu(void)
{
    return i960_ld_u32(I960_WORKRAM, 0x202098, 0) == 4u;
}

/*
 * Game-start (main mode 3) and attract share MAME model2_v composite order:
 * even tilemaps under polygons, odd (priority) tilemaps over — see flip().
 */
static int viewer_is_game_start(void)
{
    return i960_ld_u32(I960_WORKRAM, 0x202098, 0) == 3u;
}

/*
 * Practice scene table @ 0x5BA880 slots [2]/3]: car_display @ 0x14D60 /
 * car_select @ 0x15200 (staged 0x5B3D60 / 0x5B4200). Champ table @ 0x5BA820
 * never reaches those. Detect either staged or ROM form.
 */
static int viewer_is_car_select_scene(void)
{
    u32 frame;
    u32 handler;
    u32 rom;
    const u32 tables[2] = { 0x005ba880u, 0x005ba820u };
    int t;

    if (!viewer_is_game_start())
        return 0;

    frame = i960_ld_u32(I960_WORKRAM, 0x2020ac, 0) & 15u;
    for (t = 0; t < 2; t++) {
        handler = i960_ld_u32(I960_WORKRAM, tables[t], frame << 2);
        if (handler == 0u)
            handler = model2_workram_mirror_u32(tables[t] + (frame << 2));
        if (handler == 0x00014d60u || handler == 0x00015200u
            || handler == 0x005b3d60u || handler == 0x005b4200u)
            return 1;
        /* Staged callx: 0x5A0000 + (rom - 0x1000). */
        if (handler >= 0x005a0000u && handler < 0x005c0000u) {
            rom = 0x1000u + (handler - 0x005a0000u);
            if (rom == 0x00014d60u || rom == 0x00015200u)
                return 1;
        }
    }
    return 0;
}

/* attract_hud_setup @ 0x1B940 / staged 0x5BA940 — START CGM, Sys24 only. */
static int viewer_is_start_banner(void)
{
    u32 frame;
    const u32 tables[2] = { 0x005ba820u, 0x005ba880u }; /* champ / practice */
    int t;

    /* Tables are always readable; only arm this during mode-3 game start. */
    if (!viewer_is_game_start())
        return 0;

    frame = i960_ld_u32(I960_WORKRAM, 0x2020ac, 0) & 15u;
    for (t = 0; t < 2; t++) {
        u32 handler = i960_ld_u32(I960_WORKRAM, tables[t], frame << 2);

        if (handler == 0u)
            handler = model2_workram_mirror_u32(tables[t] + (frame << 2));
        if (handler == 0x005ba940u || handler == 0x0001b940u)
            return 1;
        /* Staged callx: 0x5A0000 + (rom - 0x1000). */
        if (handler >= 0x005a0000u && handler < 0x005c0000u
            && (0x1000u + (handler - 0x005a0000u)) == 0x0001b940u)
            return 1;
    }
    return 0;
}

static int viewer_tiles_opaque(u32 inner, u32 frame)
{
    return viewer_is_splash_hold(inner, frame) || viewer_is_test_menu()
        || viewer_is_start_banner();
}
