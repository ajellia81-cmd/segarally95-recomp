#ifndef I960_HOST_H
#define I960_HOST_H

#include "i960_lift.h"
#include "track_viewer.h"

/* When set, boot_entry skips the HW timer spin @ fp+0x40 (host harness). */
extern int i960_host_skip_hw_timer;

/* Host HLE of timer0 IRQ @ 0x25C68 — drain the MIDI UART TX ring. */
void irq_timer0_drain_pending(void);

/* True when the live boot viewer is running (I960_HOST_BOOT_SCREEN=1). */
int i960_host_boot_screen(void);

/* True when boot harness should skip the 240-frame sound→copyright wait. */
int i960_host_boot_fast_countdown(void);

/* True when --practice / I960_HOST_SKIP_PRACTICE: skip menus to desert START. */
int i960_host_skip_practice(void);
void i960_host_skip_practice_tick(void);
/* Desert course index while --practice (0x20a8c4). 0x214354 is also car-select. */
u32 i960_host_race_course_index(void);
/* Kept for callers; analog table 5 + 0x15200 write Delta MT. */
void i960_host_practice_force_delta_mt(void);
/* Recock analog to cabinet rest (0x80) during --practice intro. */
void i960_host_skip_practice_idle_wheel(void);
/* After SDL poll: keep Delta MT analog / desert RAM while menus run. */
void i960_host_skip_practice_hold_inputs(void);
/* 1 while --practice desert START is holding analog 0x80 (until 0x214120). */
int i960_host_skip_practice_intro_locked(void);
void i960_host_boot_clock_mark(void);
double i960_host_boot_clock_elapsed(void);

/* True when geo_vsync_wait uses realtime video timer (env I960_HOST_VIDEO_SYNC). */
int i960_host_frame_pace_enabled(void);

/* Zero the lifted register file and set sp/fp for host execution. */
void i960_host_reset(void);

/* App-facing reset: explicit sound directory, returns 0/-1 instead of exit().
 * Call only after successful ROM load, on the sole core-owning thread.
 * Failure can leave partially reset global state: do not execute the core.
 * Success starts the existing sound-board thread; this is NOT a pause API. */
int i960_host_reset_checked(const char *sound_rom_dir);

/* App-facing loader: both paths required; no default lookup, board verification,
 * auto-extraction or exit(). Returns 0/-1; existing loader may partially mutate
 * global ROM state on error. Not a complete asset/provenance validator. */
int i960_host_load_extracted(const char *maincpu_path, const char *main_data_path);

/* Desktop loader: verifies board dumps, may auto-extract, exits on failure. */
void i960_host_load_rom(void);

/*
 * Cold boot @ boot_entry (ROM 0x310): stack setup, timer wait, then
 * maincpu_reset_entry. On host, skips the timer spin.
 */
void boot_entry_host(u32 arg0, u32 arg1, u32 arg2);

/*
 * After reset init: enter post_reset_dispatch @ 0x570 (infinite callx loop on HW).
 * Host run stops after I960_HOST_MAX_DISPATCH indirect calls (default 64).
 *
 * Env:
 *   I960_HOST_MAX_DISPATCH=N   stop after N call/callx (0 = unlimited)
 *   I960_HOST_TRACE_ABORT=1    abort on first unknown ROM target
 *   I960_HOST_TRACE_QUIET=1    suppress per-call stderr lines
 *   I960_HOST_VIDEO_SYNC=1     timer thread toggles videoctl bit 2 (on for the SDL window)
 *   I960_HOST_FRAME_HZ=60      video refresh for host timer (default 60)
 *   I960_HOST_BOOT_FAST_COUNTDOWN=0  use ROM 240-frame sound→copyright wait
 *   I960_HOST_SKIP_PRACTICE=1        skip menus → desert practice START (Delta MT)
 */
void i960_host_trace_init(void);
void i960_host_trace_summary(void);
void i960_host_dispatch_reset(void);
int i960_host_dispatch_halted(void);
void i960_host_request_halt(void);
void i960_host_frame_present(void);
void i960_host_run_post_reset(u32 arg0, u32 arg1, u32 arg2);

/* Host boundary extracted from game_dispatch_main @ 0x3150.
 * Requires the original cold-boot/post-reset prerequisites; begin ONCE at the
 * original game entry, then step on the same core-owning thread. Not reentrant.
 * step: 0 = already halted, 1 = one existing loop iteration completed (possibly
 * requesting halt during that iteration). May block in nested game/vsync calls.
 * Does not initialize assets, reset hardware, implement pause, or own shutdown.
 * No iOS caller is wired yet; never call this on the UIKit main thread. */
void i960_host_game_loop_begin(u32 arg0, u32 arg1, u32 arg2);
int i960_host_game_loop_step(void);

/* Boot milestones (tile-script completion hooks).
 *   I960_HOST_MILESTONE_BOOT=sound_init  halt after 0x005B9A10
 *   I960_HOST_MILESTONE_BOOT=copyright   halt after 0x005B9960 (default boot viewer)
 *   I960_HOST_MILESTONE_BOOT=splash      halt after comm_attract_inner_2 CGM draw
 * Legacy: I960_HOST_MILESTONE_SOUND_INIT=1 → sound_init */
void i960_host_milestone_boot_arm(const char *target);
void i960_host_milestone_boot_notify_script(u32 script_vaddr);
void i960_host_milestone_boot_notify_splash(u32 catalog_vaddr, u32 batch);
int i960_host_milestone_boot_reached(void);

void i960_host_milestone_sound_init_arm(void);
void i960_host_milestone_sound_init_notify(u32 script_vaddr);
int i960_host_milestone_sound_init_reached(void);

#endif
