/* Synthetic SRAM only. Tests atomic replacement and repeated default-path saves. */
#include "model2_nvram.h"
#include "model2_rom.h"
#include "i960_mem.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
static u8 sram[MODEL2_BACKUP_SRAM_SIZE];
u8 *model2_backup_sram_ptr(void){return sram;}
u32 i960_ld_u8(i960_space s,u32 a,u32 b){return 0;}
u32 i960_ld_u16(i960_space s,u32 a,u32 b){return 0;}
void i960_st_u8(i960_space s,u32 a,u32 b,u8 v){}
void i960_st_u16(i960_space s,u32 a,u32 b,u16 v){}
#define CHECK(x) do{if(!(x)){fprintf(stderr,"failed: %s\n",#x);return 1;}}while(0)
int main(void){
 char dir[]="/tmp/segarally-nvram-XXXXXX",path[512],temporary[520],bad[520];
 CHECK(mkdtemp(dir)!=NULL);
 snprintf(path,sizeof(path),"%s/nvram.yaml",dir);snprintf(temporary,sizeof(temporary),"%s.tmp",path);
 snprintf(bad,sizeof(bad),"%s/no-directory/nvram.yaml",dir);
 CHECK(setenv("I960_HOST_NVRAM",path,1)==0);
 sram[0]=0x42;sram[MODEL2_BACKUP_SRAM_SIZE-1]=0x71;
 CHECK(model2_nvram_save(path)==0);
 CHECK(model2_nvram_save(NULL)==0);
 CHECK(strcmp(model2_nvram_path(),path)==0);
 memset(sram,0,sizeof(sram));CHECK(model2_nvram_load(NULL)==0);
 CHECK(sram[0]==0x42&&sram[MODEL2_BACKUP_SRAM_SIZE-1]==0x71);
 CHECK(model2_nvram_save(NULL)==0);
 CHECK(access(temporary,F_OK)!=0);
 CHECK(model2_nvram_save(bad)==-1);
 CHECK(strcmp(model2_nvram_path(),path)==0);
 memset(sram,0,sizeof(sram));CHECK(model2_nvram_load(path)==0);
 CHECK(sram[0]==0x42&&sram[MODEL2_BACKUP_SRAM_SIZE-1]==0x71);
 CHECK(unlink(path)==0);CHECK(rmdir(dir)==0);return 0;
}
