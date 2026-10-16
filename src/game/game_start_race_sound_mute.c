/* Race HUD/sound mute burst @ 0x1C7A0 — bal/call from slot4/slot5.
 * Four tile_texture_descriptor_apply pairs (g1=0): 0xad / 0xaf / 0xb5 / 0xb8.
 * source: disasm/maincpu/maincpu_01c7a0_34.asm */
// @rom 0x1c7a0 +0x34 game_start_race_sound_mute

#include "i960_lift.h"

#include "lift_syms.h"

void game_start_race_sound_mute(u32 arg0, u32 arg1, u32 arg2)
{
    (void)arg0;
    (void)arg1;
    (void)arg2;

    tile_texture_descriptor_apply(0xadu, 0, 0);
    tile_texture_descriptor_apply(0xafu, 0, 0);
    tile_texture_descriptor_apply(0xb5u, 0, 0);
    tile_texture_descriptor_apply(0xb8u, 0, 0);
}
