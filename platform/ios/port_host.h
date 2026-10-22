#ifndef PORT_HOST_H
#define PORT_HOST_H
#include <stdint.h>
#include "model2_geo.h"
/* Inputs are copied under the UI/core gate, then applied on the core owner only. */
typedef struct {
    float steer, throttle, brake;
    unsigned coin, start, view, gear;
} port_input_t;
void port_input_apply(const port_input_t *input);
void port_input_release(void);
/* Implemented by native app. Return 1 to unwind the existing core halt gates. */
int port_host_poll(void);
void port_host_publish(const uint32_t *bottom, const uint32_t *priority, int opaque);
void port_host_report_error(const char *message);
void port_host_audio_start(void);
void port_host_audio_stop(void);
#endif
