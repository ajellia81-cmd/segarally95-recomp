#ifndef PORT_ZIP_H
#define PORT_ZIP_H
#include <stddef.h>
#include <stdint.h>
typedef struct port_zip port_zip_t;
port_zip_t *port_zip_open(const char *path,char *error,size_t cap);
void port_zip_close(port_zip_t *zip);
/* Exact basename + size + CRC selects a member inside merged ROM archives.
 * Returns 0 success, 1 absent, -1 malformed/mismatched. Caller frees *data. */
int port_zip_read(port_zip_t *zip,const char *name,size_t size,uint32_t crc,
                  unsigned char **data,char *error,size_t cap);
#endif
