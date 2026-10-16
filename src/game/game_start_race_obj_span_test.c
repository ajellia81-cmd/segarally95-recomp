/* Object XZ span test @ 0x22850 — used by game_start_race_obj_scan.
 *
 * If (g0>>16)==(g2>>16), submit delta(self,other) through TGP 0x2c805959
 * with thresholds from 0x214360/364/368 (XZ only: third push is 0, not dy);
 * return 1 when readback > 0.
 * Else compare signed high halves (@0x22918–0x22930): shri both, then
 * cmpible other,self → ret 0; else ret 1. So return 1 iff other_hi > self_hi
 * (other is ahead on the packed span index).
 *
 * g1/g3 are pointers to xyz floats (self / other).
 *
 * source: disasm/maincpu/maincpu_022850_f0.asm */
// @rom 0x22850 +0xe0 game_start_race_obj_span_test

#include "i960_lift.h"
#include "i960_fp.h"
#include "i960_mem.h"

#include <string.h>

/* g1/g3 are host frame pointers (lda 0x40/50(fp)); keep full uintptr_t —
 * casting through u32 truncates arm64 and SEGVs when hi16(+0x54) matches. */
void game_start_race_obj_span_test(u32 self_z, void *self_xyz, u32 other_z)
{
    uintptr_t fp_save = fp;
    u8 frame[0x60];
    u32 self_hi = self_z >> 16;
    u32 other_hi = other_z >> 16;
    u32 *self = (u32 *)self_xyz;
    u32 *other = (u32 *)g3;
    double dx, dz;
    u32 hit;

    memset(frame, 0, sizeof(frame));
    fp = (uintptr_t)frame;

    if (self_hi != other_hi) {
        /* @0x22918: shri 16 both; cmpible other,self → 0; else → 1. */
        i32 other = (i32)other_z >> 16;
        i32 self = (i32)self_z >> 16;

        g0 = (other > self) ? 1u : 0u;
        fp = fp_save;
        return;
    }

    if (self == NULL || other == NULL) {
        g0 = 0;
        fp = fp_save;
        return;
    }

    /*
     * @0x22860–0x228F0: delta = other − self. Disasm computes dy into r5 then
     * `mov 0,r5` before `stl r4,0x40(fp)`, so the 0x44 word pushed is 0 — XZ
     * only. Push order: dx, 214360, 0, 214364, dz, 214368.
     */
    dx = i960_u32_to_f64(other[0]) - i960_u32_to_f64(self[0]);
    dz = i960_u32_to_f64(other[2]) - i960_u32_to_f64(self[2]);

    /* TGP 0x2c805959 — firmware @ 0x530 interleaved 3-term dot. */
    i960_mmio_write_u32(0x884000u, 0x2c805959u);
    i960_mmio_write_u32(0x884000u, (u32)i960_f64_to_u32(dx));
    i960_mmio_write_u32(0x884000u, i960_ld_u32(I960_WORKRAM, 0x214360, 0));
    i960_mmio_write_u32(0x884000u, 0u);
    i960_mmio_write_u32(0x884000u, i960_ld_u32(I960_WORKRAM, 0x214364, 0));
    i960_mmio_write_u32(0x884000u, (u32)i960_f64_to_u32(dz));
    i960_mmio_write_u32(0x884000u, i960_ld_u32(I960_WORKRAM, 0x214368, 0));
    hit = i960_mmio_read_u32(0x884000u);

    if (i960_u32_to_f64(hit) > 0.0)
        g0 = 1u;
    else
        g0 = 0u;
    fp = fp_save;
}
