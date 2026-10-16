/* Practice / solo lap-time record @ 0x18270 — call from slot3 when
 * 0x202230==1 after course complete (g0 = 0x2020bc elapsed).
 *
 * source: disasm/maincpu/maincpu_018270_18c.asm */
// @rom 0x18270 +0x18c game_start_race_lap_record

#include "i960_lift.h"
#include "i960_mem.h"

#include "lift_syms.h"

void game_start_race_lap_record(u32 arg0, u32 arg1, u32 arg2)
{
    u32 time = arg0 != 0u ? arg0 : (u32)g0;
    u32 car;
    u32 bank;
    u32 base;
    u32 r5;
    u32 g5;
    u32 r4;
    u32 r6;
    u32 slot;
    u32 idx;
    u32 kind;

    (void)arg1;
    (void)arg2;

    car = i960_ld_u32(I960_WORKRAM, 0x214354, 0);
    bank = car + 1u;
    if (i960_ld_u32(I960_WORKRAM, 0x2020b4, 0) != 0u)
        bank = 5u;
    i960_st_u32(I960_WORKRAM, 0x20aa14, 0, bank);
    base = 0x01d002f0u + bank * 0x194u;

    /* @0x182B8: network (timer >= 0) skips the ranked insert. */
    if ((i32)i960_ld_u32(I960_WORKRAM, 0x20a560, 0) >= 0)
        goto bump_count;

    r5 = 0u;
    g5 = base;

    /* @0x182C4–0x18324: walk rows while recorded time < new time. */
    for (;;) {
        u32 cur = i960_ld_u32(I960_ABS, g5 + 0xd4u, 0);

        if (cur < time) {
            r5 += 1u;
            if ((i32)r5 > 15)
                break;
            g5 = i960_ld_u32(I960_ABS, g5 + 0xcu, 0);
            continue;
        }

        /* Insert position: optional down-shift when r5 < 15. */
        if ((i32)r5 < 15) {
            r6 = 0xa8u;
            r4 = base + r6;
            for (;;) {
                u32 need = (r5 + (r5 << 1)) << 2;
                u32 t;
                u16 a;
                u16 b;

                t = i960_ld_u32(I960_ABS, r4 + 0xd4u, 0);
                a = (u16)i960_ld_u16(I960_ABS, r4 + 0xdcu, 0);
                b = (u16)i960_ld_u16(I960_ABS, r4 + 0xdeu, 0);
                g0 = r4 + 0xe4u;
                g1 = r4 + 0xd8u;
                i960_st_u32(I960_ABS, r4 + 0xe0u, 0, t);
                i960_st_u16(I960_ABS, r4 + 0xe8u, 0, a);
                i960_st_u16(I960_ABS, r4 + 0xeau, 0, b);
                libc_strcpy((void *)(uintptr_t)g0,
                            (const void *)(uintptr_t)g1);
                r6 -= 12u;
                r4 -= 12u;
                if ((i32)r6 < (i32)need)
                    break;
            }
        }
        break;
    }

    i960_st_u32(I960_WORKRAM, 0x20a9fc, 0, r5);
    /* @0x18330: cmpibl 15,r5 → skip insert when 15 < r5 (r5 >= 16). */
    if ((i32)r5 > 15)
        goto after_insert;

    idx = r5 + (r5 << 1);
    slot = i960_ld_u32(I960_ABS, base + (idx << 2), 0);
    i960_st_u32(I960_ABS, slot + 0xd4u, 0, time);
    g14 = 0;
    i960_st_u16(I960_ABS, slot + 0xdeu, 0, 0);

    {
        u8 pen = (u8)(i960_ld_u8(I960_WORKRAM, 0x213b90, 0) & 0xffu);

        pen = (u8)(pen & 15u);
        if (pen == 0u) {
            if (i960_ld_u32(I960_WORKRAM, 0x2139d0, 0) == 0u) {
                i960_st_u16(I960_ABS, slot + 0xdcu, 0, 0);
                goto after_kind;
            }
            kind = 1u;
        } else if (i960_ld_u32(I960_WORKRAM, 0x2139d0, 0) == 0u) {
            kind = 2u;
        } else {
            kind = 3u;
        }
        idx = i960_ld_u32(I960_WORKRAM, 0x20a9fc, 0);
        idx = idx + (idx << 1);
        /* @0x183B4: stos kind → 0xdc(base)[idx*4] */
        i960_st_u16(I960_ABS, base + 0xdcu + (idx << 2), 0, (u16)kind);
    }

after_kind:
    {
        u32 best = i960_ld_u32(I960_ABS, base + 0xcu, 0);

        if (best > time || best == 0u) {
            i960_st_u32(I960_ABS, base + 0xcu, 0, time);
            game_start_race_name_copy(base, 0, 0);
        }
    }

after_insert:
bump_count:
    {
        u32 cnt_ea = base + 8u;

        i960_st_u32(I960_ABS, cnt_ea, 0,
                    i960_ld_u32(I960_ABS, cnt_ea, 0) + 1u);
    }
    g14 = 0;
    i960_st_u32(I960_WORKRAM, 0x20aa18, 0, 0u);
    i960_st_u32(I960_ABS, 0x01d002e8u, 0, 1u);
}
