#include "port_host.h"
#include "model2_rom.h"
#include <math.h>
static float clamp(float x, float lo, float hi) {
    if (!isfinite(x)) return 0;
    return x < lo ? lo : x > hi ? hi : x;
}
void port_input_apply(const port_input_t *p) {
    if (!p) { port_input_release(); return; }
    float s = clamp(p->steer, -1, 1);
    model2_io_analog_set(MODEL2_IO_AN_STEER,
        (u8)(128 + (int)(s * (s < 0 ? 128 : 127))));
    model2_io_analog_set(MODEL2_IO_AN_ACCEL, (u8)(clamp(p->throttle, 0, 1)*255));
    model2_io_analog_set(MODEL2_IO_AN_BRAKE, (u8)(clamp(p->brake, 0, 1)*255));
    model2_io_in0_set_mask(MODEL2_IO_IN0_COIN1, !!p->coin);
    model2_io_in0_set_mask(MODEL2_IO_IN0_START1, !!p->start);
    model2_io_in0_set_mask(MODEL2_IO_IN0_VR, !!p->view);
    model2_io_shifter_set(p->gear <= 4 ? p->gear : 0);
}
void port_input_release(void) {
    const port_input_t idle = {0};
    port_input_apply(&idle);
}
