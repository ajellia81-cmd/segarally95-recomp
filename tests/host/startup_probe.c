/* Synthetic file IO only. No i960/68k execution or sound worker. */
#include "model2_rom.h"
#include "model2_rom_dir.h"
#include "model2_snd_rom.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static void file(const char *dir,const char *name,size_t size) {
    char path[4096];snprintf(path,sizeof(path),"%s/%s",dir,name);
    FILE *f=fopen(path,"wb");assert(f);
    unsigned char zeros[4096]={0};
    while(size){size_t n=size<sizeof(zeros)?size:sizeof(zeros);assert(fwrite(zeros,1,n,f)==n);size-=n;}
    assert(fclose(f)==0);
}
int main(int argc,char **argv) {
    assert(argc==2);const char *dir=argv[1];char error[512];
    assert(setenv("SEGAMOD2_ROM_DIR","/deliberately-wrong-environment",1)==0);
    char owned[4096];snprintf(owned,sizeof(owned),"%s",dir);
    assert(model2_set_rom_directory(owned)==0);owned[0]='X';
    assert(strcmp(model2_resolve_rom_dir(),dir)==0);
    assert(model2_romset_verify_at(dir,error,sizeof(error))==-1);
    assert(strstr(error,"Cannot read epr-17888b.12"));
    file(dir,"epr-17888b.12",1);
    assert(model2_romset_verify_at(dir,error,sizeof(error))==-1);
    assert(strstr(error,"epr-17888b.12: size=1 CRC="));
    assert(model2_snd_rom_load(dir)==-1);
    assert(strstr(model2_snd_rom_error(),"epr-17890.30: open"));
    file(dir,"epr-17890a.30",0x40000);
    file(dir,"mpr-17756.31",0x200000);file(dir,"mpr-17757.32",0x200000);
    file(dir,"mpr-17886.36",0x200000);file(dir,"mpr-17887.37",0x200000);
    assert(model2_snd_rom_load(dir)==0);assert(model2_snd_rom_loaded());
    assert(!*model2_snd_rom_error());model2_snd_rom_unload();
    file(dir,"mpr-17887.37",3);
    assert(model2_snd_rom_load(dir)==-1);
    assert(strstr(model2_snd_rom_error(),"mpr-17887.37: short read"));
    assert(!model2_snd_rom_loaded());
    assert(model2_set_rom_directory(NULL)==0);
    assert(strcmp(model2_resolve_rom_dir(),"/deliberately-wrong-environment")==0);
    char large[5000];memset(large,'a',sizeof(large)-1);large[sizeof(large)-1]=0;
    assert(model2_set_rom_directory(large)==-1);
    assert(!model2_explicit_rom_directory());
    puts("Explicit owned path, verifier diagnostics and sound file errors passed");
    return 0;
}
