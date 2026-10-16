/* Auto-lifted semantic C — edit by hand; not tier-3 byte-matched. */
/* source: /Users/craigs/Documents/segamod2/decomp/out/lift/slices/maincpu_00022b60_104.asm */
// @rom 0x22b60 +0x104 game_frame_update

#include "i960_lift.h"
#include "model2_rom.h"
#include "i960_mem.h"

/* convention: kind=leaf_ret  args g0,g1,g2  link g14 ret */
/* abi: u32 arg0=g0, u32 arg1=g1, u32 arg2=g2 → void */
/* call site: caller 0x323c */

/* pointers: g0=void *, g1=void *, g4=u32, g5=u32 *, g6=u32 * */

extern void libc_memcpy(void * dst, const void * src, u32 len);

void game_frame_update(u32 arg0, u32 arg1, u32 arg2)
{
    (void)arg0;
    (void)arg1;
    g2 = (uintptr_t)arg2;

    g4 = i960_ld_u32(I960_WORKRAM, 0x20a530, 0);
    /* lift: cmpibe 0, g4, 0x22c64 @ 0x22b68 */
    if ((unsigned char)g4 == 0)
        return;
    if ((unsigned char)g4 == 3) {
        g3 = 0 - 2;
        i960_st_u32(I960_WORKRAM, 0x20a560, 0, (u32)g3);
    }
    if ((unsigned char)g4 != 1)
        goto L_00022bd4;
    g4 = i960_ld_u32(I960_WORKRAM, 0x202098, 0);
    /*
     * @0x22B88–0x22B90: cmpibe 3 → call; cmpibne 2 → skip.
     * Call 0x22a10 when mode==3 or mode==2 (practice / attract).
     */
    if ((unsigned char)g4 == 3 || (unsigned char)g4 == 2)
        i960_call_rom(0x22a10);

    g4 = i960_ld_u32(I960_WORKRAM, 0x20a558, 0);
    g7 = 0;
    /* @0x22BA0: lda 0x20a598 / 0x20a570 — CRX window @ 0x00200000. */
    g6 = (uintptr_t)i960_vaddr_ptr(0x0020a598u);
    g5 = (uintptr_t)i960_vaddr_ptr(0x0020a570u);
    i960_st_u32(I960_WORKRAM, 0x20a594, 0, (u32)g4);
    do {
        g4 = *(u32 *)g5;
        g7 = g7 + 1;
        *(u32 *)g6 = (u32)g4;
        g6 = g6 + 4;
        g5 = g5 + 0x4;
    } while (g7 <= 3);

    L_00022bd4:
        g5 = i960_ld_u32(I960_WORKRAM, 0x20a560, 0);
        g6 = i960_ld_u32(I960_WORKRAM, 0x20a760, 0);
        /* @0x22BE4: ld 0x214354 (not host course remap). */
        g4 = i960_ld_u32(I960_WORKRAM, 0x214354, 0);
        r4 = (u32)i960_ld_u64(I960_WORKRAM, 0x20a770, 0);
        i960_st_u32(I960_WORKRAM, 0x20a5b0, 0, (u32)g4);
        i960_st_u32(I960_WORKRAM, 0x20a5ac, 0, (u32)g5);
        g4 = i960_ld_u32(I960_WORKRAM, 0x20a564, 0);
        g7 = i960_ld_u32(I960_WORKRAM, 0x20b0b0, 0);
        i960_st_u32(I960_WORKRAM, 0x20a5a8, 0, (u32)g4);
        i960_st_u32(I960_WORKRAM, 0x20a718, 0, (u32)g6);
        i960_st_u32(I960_WORKRAM, 0x20a71c, 0, (u32)r4);
        i960_st_u32(I960_WORKRAM, 0x20a720, 0, (u32)r5);
        g0 = (uintptr_t)i960_vaddr_ptr(0x1a12000u);
        /* @0x22C3C: lda 0x20a590 — CRX, not a separate workram window. */
        g1 = (uintptr_t)i960_vaddr_ptr(0x0020a590u);
        g2 = 7 << 6;
        i960_st_u32(I960_WORKRAM, 0x20a724, 0, (u32)r6);
        i960_st_u32(I960_WORKRAM, 0x20a728, 0, (u32)r7);
        i960_st_u32(I960_WORKRAM, 0x20a72c, 0, (u32)g7);
        libc_memcpy((void *)(uintptr_t)g0, (const void *)(uintptr_t)g1, g2);
}
