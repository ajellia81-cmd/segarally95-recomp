/* Synthetic control-flow test: all game services and memory reads are fakes.
 * No ROM loader, game binary, hardware backend or emulator is linked. */
#include "i960_host.h"
#include "i960_mem.h"
#include "model2_rom.h"
#include "lift_syms.h"
#include <stdio.h>
#include <string.h>

MODEL2_HOST_ALIGN u8 model2_crx_ram[0x40000];
static char trace[4096];
static int halted, presents, halt_at, writes;
static void event(const char *name) { strcat(trace, name); strcat(trace, " "); }
#define VOID2(name, tag) void name(u32 a, u32 b) { event(tag); }
#define VOID3(name, tag) void name(u32 a, u32 b, u32 c) { event(tag); }
#define RET2(name, tag) u32 name(u32 a, u32 b) { event(tag); return 0; }
RET2(game_irq_wr_stub, "irq")
RET2(game_comm_aa24_seed, "seed")
RET2(game_workram_bx_stub, "work")
VOID3(game_staging_init, "staging")
VOID3(game_subsys_init_stub, "subsys")
VOID3(game_cold_boot_init, "cold")
VOID3(boot_tile_splash_frame, "splash")
VOID2(format_scan_bx_stub, "format")
VOID3(game_mode_apply, "mode")
VOID3(comm_board_dispatch, "board")
VOID3(backup_sram_sync, "backup")
VOID2(copro_fifo_init, "copro")
VOID3(game_frame_update, "frame")
VOID3(texture_bank_select, "texture")
VOID2(geo_fifo_emit, "emit")
RET2(geo_fifo_preset, "preset")
int i960_host_dispatch_halted(void) { return halted; }
int i960_host_boot_screen(void) { return 1; }
void i960_host_frame_present(void) {
    event("present");
    if (++presents == halt_at) halted = 1;
}
void *i960_vaddr_ptr(u32 address) { return NULL; }
const u8 *model2_rom_at(u32 address) { return NULL; }
u32 i960_ld_u32(i960_space space, u32 base, u32 offset) {
    /* Exercise the optional indirect mode callback without reading any data. */
    return base == 0x5a2110 ? 123u : 0u;
}
void i960_call_indirect(uintptr_t target) { event("indirect"); }
void i960_st_u32(i960_space space, u32 base, u32 offset, u32 value) { ++writes; }
void i960_mmio_write_u32(u32 offset, u32 value) { ++writes; }
#define CHECK(x) do { if (!(x)) { fprintf(stderr, "failed: %s\ntrace: %s\n", #x, trace); return 1; } } while (0)
int main(void)
{
    const char *one_frame = "board backup indirect copro frame texture mode emit preset present ";
    int prior_writes;
    i960_host_game_loop_begin(0, 0, 0);
    CHECK(strcmp(trace, "irq seed work staging subsys cold splash present format mode ") == 0);
    trace[0] = 0;
    CHECK(i960_host_game_loop_step() == 1);
    CHECK(strcmp(trace, one_frame) == 0);
    CHECK(presents == 2);
    halted = 1;
    trace[0] = 0;
    prior_writes = writes;
    CHECK(i960_host_game_loop_step() == 0);
    CHECK(trace[0] == 0 && writes == prior_writes);
    /* The unchanged desktop entry must keep stepping until the same halt gate. */
    halted = 0; presents = 0; halt_at = 4;
    game_dispatch_main(0, 0, 0);
    CHECK(presents == 4 && halted);
    return 0;
}
