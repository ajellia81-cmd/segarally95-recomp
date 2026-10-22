#include "port_rom_import.h"
#include "port_zip.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static int write_file(const char *dir,const char *name,const unsigned char *bytes,size_t size,char *error,size_t cap){
    char path[4096];if(snprintf(path,sizeof(path),"%s/%s",dir,name)>=(int)sizeof(path))return -1;
    FILE *f=fopen(path,"wb");if(!f){snprintf(error,cap,"Cannot write %s",name);return -1;}
    int ok=fwrite(bytes,1,size,f)==size;if(fclose(f))ok=0;
    if(!ok){remove(path);snprintf(error,cap,"Write failed: %s",name);}return ok?0:-1;
}
static int interleave(const char *dir,const char *out,const char *const *pairs,unsigned count,char *error,size_t cap){
    char path[4096];if(snprintf(path,sizeof(path),"%s/%s",dir,out)>=(int)sizeof(path))return -1;
    FILE *dest=fopen(path,"wb");if(!dest)return -1;int ok=1;
    for(unsigned pair=0;pair<count&&ok;pair++){
        FILE *a=NULL,*b=NULL;
        if(snprintf(path,sizeof(path),"%s/%s",dir,pairs[pair*2])<(int)sizeof(path))a=fopen(path,"rb");
        if(snprintf(path,sizeof(path),"%s/%s",dir,pairs[pair*2+1])<(int)sizeof(path))b=fopen(path,"rb");
        if(!a||!b)ok=0;
        while(ok){unsigned char lo[8192],hi[8192],bytes[16384];size_t na=fread(lo,1,sizeof(lo),a),nb=fread(hi,1,sizeof(hi),b);
            if(!na&&!nb){if(ferror(a)||ferror(b))ok=0;break;}
            if(na!=nb||(na&1)){ok=0;break;}
            for(size_t k=0;k<na;k+=2){bytes[k*2]=lo[k];bytes[k*2+1]=lo[k+1];bytes[k*2+2]=hi[k];bytes[k*2+3]=hi[k+1];}
            if(fwrite(bytes,1,na*2,dest)!=na*2){ok=0;break;}}
        if(a)fclose(a);if(b)fclose(b);
    }
    if(fclose(dest))ok=0;
    if(!ok)snprintf(error,cap,"BIN preparation failed: %s",out);
    return ok?0:-1;
}
int port_rom_import_zip(const char *archive,const char *dir,const model2_romset_entry_t *entries,unsigned count,char *error,size_t cap){
    port_zip_t *z=port_zip_open(archive,error,cap);if(!z)return -1;int result=-1;
    for(unsigned i=0;i<count;i++){
        unsigned char *data=NULL;const model2_romset_entry_t *e=entries+i;
        /* Output filenames are application metadata, never archive paths. */
        if(strchr(e->name,'/')||strchr(e->name,'\\'))goto end;
        int r=port_zip_read(z,e->name,e->size,e->crc,&data,error,cap);
        if(r==1&&e->alias)r=port_zip_read(z,e->alias,e->size,e->crc,&data,error,cap);
        if(r)goto end;
        r=write_file(dir,e->name,data,e->size,error,cap);free(data);if(r)goto end;
    }
    /* Optional copro heightmaps: accept only these published sizes/CRCs. */
    static const model2_romset_entry_t optional[]={
        {"mpr-17754.28","mpr-17754.29",2097152,0x81a84f67},
        {"mpr-17755.29","mpr-17755.28",2097152,0x2a6e7da4}};
    for(unsigned i=0;i<2;i++){
        const model2_romset_entry_t *e=optional+i;unsigned char *data=NULL;
        int r=port_zip_read(z,e->name,e->size,e->crc,&data,error,cap);
        if(r==1)r=port_zip_read(z,e->alias,e->size,e->crc,&data,error,cap);
        if(r<0)goto end;
        if(r==0){r=write_file(dir,e->name,data,e->size,error,cap);free(data);if(r)goto end;}
    }
    const char *cpu[]={entries[0].name,entries[1].name};
    static const char *main[]={"mpr-17746.10","mpr-17747.11","mpr-17744.8","mpr-17745.9","mpr-17884.6","mpr-17885.7"};
    if(interleave(dir,"maincpu_deinterleaved.bin",cpu,1,error,cap)||interleave(dir,"main_data_deinterleaved.bin",main,3,error,cap))goto end;
    result=0;if(error&&cap)error[0]=0;
end:port_zip_close(z);return result;
}

int port_rom_import_game_zip(const char *archive,const char *destination,char *error,size_t cap){
    unsigned count=0;const model2_romset_entry_t *entries=model2_romset_entries(&count);
    return port_rom_import_zip(archive,destination,entries,count,error,cap);
}
