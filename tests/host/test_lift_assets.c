/* Contract test with a fake loader. No filesystem or game data is accessed. */
#include "i960_host.h"
#include <stdio.h>
#include <string.h>

static int calls, result;
static const char *cpu_seen, *data_seen;
int model2_rom_load(const char *cpu, const char *data)
{
    ++calls;
    cpu_seen = cpu;
    data_seen = data;
    return result;
}
#define CHECK(x) do { if (!(x)) { fprintf(stderr, "failed: %s\n", #x); return 1; } } while (0)
int main(void)
{
    const char *invalid[] = {NULL, ""};
    unsigned i;
    for (i = 0; i < 2; ++i) {
        CHECK(i960_host_load_extracted(invalid[i], "fake-data") == -1);
        CHECK(i960_host_load_extracted("fake-cpu", invalid[i]) == -1);
    }
    CHECK(calls == 0);
    result = -1;
    CHECK(i960_host_load_extracted("fake-cpu", "fake-data") == -1);
    CHECK(calls == 1);
    CHECK(strcmp(cpu_seen, "fake-cpu") == 0);
    CHECK(strcmp(data_seen, "fake-data") == 0);
    result = 0;
    CHECK(i960_host_load_extracted("fake-cpu", "fake-data") == 0);
    CHECK(calls == 2);
    return 0;
}
