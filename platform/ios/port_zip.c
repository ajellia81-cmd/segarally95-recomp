#include "port_zip.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <zlib.h>
struct port_zip { unsigned char *bytes; size_t size,offset,end; unsigned count; };
static unsigned u16(const unsigned char *p){return p[0]|p[1]<<8;}
static uint32_t u32(const unsigned char *p){return (uint32_t)u16(p)|(uint32_t)u16(p+2)<<16;}
static int fail(char *out,size_t cap,const char *fmt,...){
    if(out&&cap){va_list ap;va_start(ap,fmt);vsnprintf(out,cap,fmt,ap);va_end(ap);}return -1;
}
static int range(size_t offset,size_t length,size_t total){return offset<=total&&length<=total-offset;}
port_zip_t *port_zip_open(const char *path,char *error,size_t cap){
    FILE *f=fopen(path,"rb");port_zip_t *z=NULL;
    if(!f){fail(error,cap,"ZIP open failed");return NULL;}
    if(fseek(f,0,SEEK_END)||ftell(f)<22||ftell(f)>256L*1024*1024){fail(error,cap,"ZIP size unsupported (max 256 MiB)");goto out;}
    z=calloc(1,sizeof(*z));if(!z)goto out;
    z->size=(size_t)ftell(f);z->bytes=malloc(z->size);
    if(!z->bytes||fseek(f,0,SEEK_SET)||fread(z->bytes,1,z->size,f)!=z->size){fail(error,cap,"ZIP read failed");goto bad;}
    size_t e=z->size-22,lowest=z->size>65557?z->size-65557:0;
    for(;;){if(u32(z->bytes+e)==0x06054b50&&e+22+u16(z->bytes+e+20)==z->size)break;
        if(e==lowest){fail(error,cap,"ZIP central directory missing");goto bad;}--e;}
    const unsigned char *p=z->bytes+e;
    if(u16(p+4)||u16(p+6)||u16(p+8)!=u16(p+10)||u16(p+10)>4096||u32(p+12)==UINT32_MAX||u32(p+16)==UINT32_MAX){fail(error,cap,"ZIP64/multi-volume archives are unsupported");goto bad;}
    z->count=u16(p+10);z->offset=u32(p+16);
    if(!range(z->offset,u32(p+12),e)){fail(error,cap,"ZIP central directory out of bounds");goto bad;}
    z->end=z->offset+u32(p+12);size_t cursor=z->offset;
    for(unsigned i=0;i<z->count;i++){
        if(!range(cursor,46,z->end)||u32(z->bytes+cursor)!=0x02014b50){fail(error,cap,"ZIP member header invalid");goto bad;}
        p=z->bytes+cursor;size_t length=46u+u16(p+28)+u16(p+30)+u16(p+32);
        if(!u16(p+28)||u16(p+28)>512||!range(cursor,length,z->end)){fail(error,cap,"ZIP member bounds invalid");goto bad;}
        cursor+=length;
    }
    if(cursor!=z->end){fail(error,cap,"ZIP directory length mismatch");goto bad;}
    fclose(f);return z;
bad:port_zip_close(z);z=NULL;
out:fclose(f);return z;
}
void port_zip_close(port_zip_t *z){if(z){free(z->bytes);free(z);}}
int port_zip_read(port_zip_t *z,const char *name,size_t size,uint32_t crc,unsigned char **data,char *error,size_t cap){
    if(data)*data=NULL;
    if(!z||!name||!data||!size||size>4u*1024*1024)return fail(error,cap,"Invalid import request");
    size_t cursor=z->offset;int found=0;
    for(unsigned i=0;i<z->count;i++){
        const unsigned char *p=z->bytes+cursor;unsigned len=u16(p+28);char member[513];memcpy(member,p+46,len);member[len]=0;
        cursor+=46u+len+u16(p+30)+u16(p+32);
        if(memchr(member,0,len))continue;
        const char *base=strrchr(member,'/');base=base?base+1:member;
        if(strcmp(base,name))continue;found=1;
        if(u32(p+24)!=size||u32(p+16)!=crc)continue;
        if(member[0]=='/'||strchr(member,'\\')||strchr(member,':')||!strncmp(member,"../",3)||strstr(member,"/../")||u16(p+8)&1||u16(p+34)||((u32(p+38)>>16)&0170000)==0120000)
            return fail(error,cap,"Unsafe/encrypted ZIP member: %s",name);
        unsigned method=u16(p+10);size_t compressed=u32(p+20),local=u32(p+42);
        if((method!=0&&method!=8)||compressed>8u*1024*1024||!range(local,30,z->offset)||u32(z->bytes+local)!=0x04034b50)
            return fail(error,cap,"Unsupported ZIP member: %s",name);
        const unsigned char *l=z->bytes+local;
        if(u16(l+8)!=method||u16(l+6)!=u16(p+8)||u16(l+26)!=len||!range(local+30,len+u16(l+28),z->offset)||memcmp(l+30,member,len))
            return fail(error,cap,"ZIP local header mismatch: %s",name);
        size_t start=local+30+len+u16(l+28);
        if(!range(start,compressed,z->offset))return fail(error,cap,"ZIP compressed data truncated: %s",name);
        unsigned char *out=malloc(size+1);if(!out)return fail(error,cap,"Import allocation failed");
        int ok=0;
        if(method==0){if(compressed==size){memcpy(out,z->bytes+start,size);ok=1;}}
        else {
            z_stream stream={0};stream.next_in=z->bytes+start;stream.avail_in=(uInt)compressed;stream.next_out=out;stream.avail_out=(uInt)size+1;
            if(inflateInit2(&stream,-MAX_WBITS)==Z_OK){int result=inflate(&stream,Z_FINISH);ok=result==Z_STREAM_END&&stream.total_out==size&&stream.total_in==compressed;inflateEnd(&stream);}
        }
        if(!ok||(uint32_t)crc32(0,out,(uInt)size)!=crc){free(out);return fail(error,cap,"ZIP decompression/CRC failed: %s",name);}
        *data=out;return 0;
    }
    if(found)return fail(error,cap,"Wrong size/CRC: %s",name);
    if(error&&cap)snprintf(error,cap,"Missing in ZIP: %s",name);return 1;
}
