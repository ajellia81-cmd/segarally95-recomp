/* App entry: never fall back to desktop extraction or terminate the process. */
#include "i960_host.h"
#include "model2_rom.h"

int i960_host_load_extracted(const char *maincpu_path, const char *main_data_path)
{
    if (!maincpu_path || !*maincpu_path || !main_data_path || !*main_data_path)
        return -1;
    return model2_rom_load(maincpu_path, main_data_path);
}
