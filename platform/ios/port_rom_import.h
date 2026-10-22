#ifndef PORT_ROM_IMPORT_H
#define PORT_ROM_IMPORT_H
#include "model2_rom.h"
#include <stddef.h>
/* Destination must be a new, private directory. No paths from ZIP are used. */
int port_rom_import_zip(const char *archive,const char *destination,
 const model2_romset_entry_t *entries,unsigned count,char *error,size_t cap);
int port_rom_import_game_zip(const char *archive,const char *destination,char *error,size_t cap);
#endif
