/* Championship car-node attach @ 0x2C770 — called per AI from 0x219F0.
 * g0=node, g1=road index, g2=payload (ldq at fp+0x40). Ends in road_attach.
 * source: disasm/maincpu/maincpu_02c770_e0.asm */
// @rom 0x2c770 +0xe0 game_start_race_obj_car_attach_champ

#include "i960_lift.h"
#include "i960_fp.h"
#include "i960_mem.h"
#include "model2_rom.h"

#include "lift_syms.h"

void game_start_race_obj_car_attach_champ(u32 arg0, u32 arg1, u32 arg2)
{
    u32 node = arg0;
    u32 road = arg1;
    u32 payload = arg2;
    u32 course;
    u32 mod;
    u32 rem;
    u32 span_base;
    u32 sample;
    u32 row;
    u32 y_bits;
    u32 pose;
    u32 fl;
    u32 dest;
    u32 lo;
    u32 hi;
    double y;
    u32 even, odd;

    if (node == 0u)
        return;

    /* ROM @0x2C770–0x2C7AC: ld 0x214354; remi (road+mod), mod. */
    course = i960_ld_u32(I960_WORKRAM, 0x214354, 0);
    mod = model2_workram_mirror_u32(0x5dce70u + (course << 4));
    span_base = model2_workram_mirror_u32(0x5dce7cu + (course << 4));
    if (mod == 0u) {
        rem = 0u;
    } else {
        i32 r = ((i32)road + (i32)mod) % (i32)mod;

        if (r < 0)
            r += (i32)mod;
        rem = (u32)r;
    }

    i960_st_u16(I960_ABS, node, 0x8a, (u16)road);
    /* shlo 16 / shri 16 — low 16 of rem into e4. */
    i960_st_u32(I960_ABS, node, 0xe4, rem & 0xffffu);
    i960_st_u16(I960_ABS, node, 0x88, (u16)rem);

    sample = i960_ld_u32(I960_ABS, span_base + ((rem & 0xffffu) << 4), 0);
    i960_st_u32(I960_ABS, node, 0x14, sample);

    row = span_base + ((i960_ld_u32(I960_ABS, node, 0xe4) & 0xffffu) << 4);
    y_bits = i960_ld_u32(I960_ABS, row + 4u, 0);
    /* @0x2C7CC–0x2C7E8: y + 0.3 (double 0x3fd3333333333333). */
    y = i960_u32_to_f64(y_bits);
    even = 0x33333333u;
    odd = 0x3fd33333u;
    y += i960_rifl_read(even, odd);
    i960_st_u32(I960_ABS, node, 0x18, (u32)i960_f64_to_u32(y));
    i960_st_u32(I960_ABS, node, 0x1c, i960_ld_u32(I960_ABS, row + 8u, 0));

    dest = node + 0x10u;
    hi = i960_ld_u8(I960_ABS, dest, 0);
    lo = payload ? (i960_ld_u8(I960_ABS, payload, 0) & 15u) : 0u;
    hi = (hi & (u8)~0x0fu) | (u8)lo;
    i960_st_u8(I960_ABS, dest, 0, (u8)hi);

    pose = i960_ld_u32(I960_ABS, node, 0x8c);
    fl = i960_ld_u8(I960_ABS, pose + 0x51u, 0);
    fl = (u8)((fl << 1) & (u8)(15u << 3));
    dest = 0x0020cd00u + fl;
    i960_st_u32(I960_ABS, node, 0xec, dest);
    if (payload != 0u) {
        u32 a = i960_ld_u32(I960_ABS, payload, 4);
        u32 b = 0;

        i960_st_u32(I960_ABS, dest, 0, a);
        i960_st_u32(I960_ABS, dest, 4, b);
    }

    g0 = node;
    game_start_race_obj_road_attach(node, 0, 0);
}
