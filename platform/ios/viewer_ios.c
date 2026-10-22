/* Native host display callbacks; the lifted core stays on one background thread. */
#include "port_host.h"
#include "sys24_viewer.h"
#include "sys24_tile.h"
#include "model2_rom.h"
#include "model2_nvram.h"
#include "model2_snd.h"
#include "model2_hw.h"
#include "scene_policy.h"
#include <stdlib.h>
static sys24_tile_state_t *tiles;
static u32 *bottom, *priority;
static int was_opaque;
int sys24_viewer_wanted(void) { return 1; }
int sys24_viewer_open(const char *title) {
    (void)title;
    tiles = sys24_tile_create(SYS24_TILE_MASK_M2);
    bottom = calloc(SYS24_FB_WIDTH*SYS24_FB_HEIGHT, sizeof(u32));
    priority = calloc(SYS24_FB_WIDTH*SYS24_FB_HEIGHT, sizeof(u32));
    if (!tiles || !bottom || !priority) {
        port_host_report_error("화면 버퍼를 준비하지 못했습니다");
        return -1;
    }
    port_host_audio_start();
    return 0;
}
int sys24_viewer_poll_events(void) { return port_host_poll(); }
int sys24_viewer_flip(const u8 *map, const u8 *chars, const u8 *pal) {
    if (port_host_poll()) return 1;
    if (!tiles || !bottom || !priority) return 1;
    int opaque = viewer_tiles_opaque(i960_ld_u32(I960_WORKRAM,0x20209c,0),
                                     i960_ld_u32(I960_WORKRAM,0x20a808,0));
    if (opaque && !was_opaque) model2_geo_clear();
    was_opaque = opaque;
    if (!opaque) { model2_geo_kick(); model2_geo_decode(); }
    sys24_tile_bind(tiles, map, chars);
    /* Preserve the desktop game-start ranking ctrl fix around tile composition. */
    u8 *reg = viewer_is_game_start() ? model2_ram_mut(0x0100a008u) : NULL;
    u16 saved = reg ? (u16)(reg[0] | (reg[1]<<8)) : 0;
    if (reg) { u16 c=saved & ~0x4000u; reg[0]=(u8)c; reg[1]=(u8)(c>>8); }
    sys24_tile_draw_layers_rgb32(tiles,bottom,pal,opaque?0xff000000u:0,
                                 opaque?SYS24_PASS_ALL:SYS24_PASS_BOTTOM);
    if (!opaque) sys24_tile_draw_layers_rgb32(tiles,priority,pal,0,SYS24_PASS_PRIORITY);
    if (reg) { reg[0]=(u8)saved; reg[1]=(u8)(saved>>8); }
    port_host_publish(bottom, opaque?NULL:priority, opaque);
    return 0;
}
int sys24_viewer_present(const u8 *m,const u8 *c,const u8 *p) { return sys24_viewer_flip(m,c,p); }
void sys24_viewer_shutdown(void) {
    if (model2_nvram_save(NULL) != 0) port_host_report_error("NVRAM 저장에 실패했습니다");
    port_host_audio_stop();
    model2_snd_reset();
    model2_geo_shutdown();
    model2_hw_vsync_hw_shutdown();
    sys24_tile_destroy(tiles); tiles=NULL;
    free(bottom); bottom=NULL; free(priority); priority=NULL;
    was_opaque=0;
}
