#include "port_rom_import.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>
/* Link the metadata/CRC module; no game or default-path loading is invoked. */
const char *model2_resolve_rom_dir(void){return ".";}
int main(int argc,char **argv){
    if(argc!=4)return 2;
    char error[512]={0};int result;
    if(strcmp(argv[3],"synthetic"))result=port_rom_import_game_zip(argv[1],argv[2],error,sizeof(error));
    else {
        const char *names[]={"epr-17888b.12","epr-17889b.13","mpr-17746.10","mpr-17747.11","mpr-17744.8","mpr-17745.9","mpr-17884.6","mpr-17885.7"};
        model2_romset_entry_t entries[8]={0};
        for(unsigned i=0;i<8;i++){unsigned char data[4]={(unsigned char)i,1,2,3};entries[i].name=names[i];entries[i].size=4;entries[i].crc=(unsigned)crc32(0,data,4);}
        result=port_rom_import_zip(argv[1],argv[2],entries,8,error,sizeof(error));
    }
    if(result)fprintf(stderr,"%s\n",error);return result?1:0;
}
