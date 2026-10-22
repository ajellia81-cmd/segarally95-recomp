#import "PortRenderer.h"
#include "model2_geo_tex.h"
#include "sys24_tile.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

typedef struct { simd_float4 patch; simd_uint4 meta; uint32_t lut[16]; } PortMaterial;
typedef struct { simd_float4 viewport, focalCenter; } PortProjection;
_Static_assert(sizeof(PortMaterial)==96, "Metal material layout");
static const model2_geo_tri_mat_t *sortMaterials; // Core owner thread only.
static unsigned depthBucket(float f) {
    uint32_t bits; memcpy(&bits,&f,4);
    int32_t exponent=(int32_t)((bits>>23)&255);
    uint32_t mantissa=(bits&0x7fffff)+0x400;
    if(mantissa>0x7fffff){exponent++;mantissa=(mantissa&0x7fffff)>>1;}
    mantissa>>=11;
    if(bits>>31) return 0;
    if(exponent<15) return ((unsigned)(exponent+1)<<12)|mantissa;
    return 0xffff;
}
static int orderCompare(const void *a,const void *b) {
    unsigned ia=*(const unsigned *)a, ib=*(const unsigned *)b;
    const model2_geo_tri_mat_t *ma=&sortMaterials[ia],*mb=&sortMaterials[ib];
    int ha=ma->pad&1,hb=mb->pad&1;
    if(ha!=hb) return ha<hb?-1:1;
    int ka=(ma->flags&4)?((ma->flags&1)?2:1):0;
    int kb=(mb->flags&4)?((mb->flags&1)?2:1):0;
    if(ka!=kb) return ka<kb?-1:1;
    unsigned za=depthBucket(ma->z_sort),zb=depthBucket(mb->z_sort);
    if(za!=zb) return za<zb?-1:1;
    if(za==0xffff && ma->z_sort!=mb->z_sort) return ma->z_sort<mb->z_sort?-1:1;
    return ia==ib?0:ia>ib?-1:1;
}
static NSData *tilePixels(const uint32_t *pixels,BOOL opaque) {
    if(!pixels) return nil;
    NSMutableData *data=[NSMutableData dataWithLength:SYS24_FB_WIDTH*SYS24_FB_HEIGHT*4];
    uint32_t *out=data.mutableBytes;
    for(unsigned i=0;i<SYS24_FB_WIDTH*SYS24_FB_HEIGHT;i++)
        out[i]=opaque || (pixels[i]&0xffffff)?pixels[i]|0xff000000u:0;
    return data;
}
@implementation PortFrame
+ (instancetype)captureBottom:(const uint32_t *)bottom priority:(const uint32_t *)priority opaque:(BOOL)opaque {
    PortFrame *f=[PortFrame new]; f.bottom=tilePixels(bottom,opaque); f.priority=tilePixels(priority,NO);
    if(opaque) return f;
    model2_geo_projection_t p;
    if(!model2_geo_projection(&p) || !p.valid || p.viewport[2]<=p.viewport[0] || p.viewport[3]<=p.viewport[1]) return f;
    f.viewport=(simd_float4){p.viewport[0],p.viewport[1],p.viewport[2],p.viewport[3]};
    f.focalCenter=(simd_float4){p.center[0],p.center[1],0,0};
    float *xyz=NULL; model2_geo_tri_mat_t *mats=NULL; unsigned nv=0,nt=0;
    if(model2_geo_copy_textured(&xyz,&nv,&mats,&nt)!=0 || !xyz || !mats || nt>nv/3 || nt>1000000) {
        free(xyz); free(mats); return f;
    }
    unsigned *order=malloc((size_t)nt*sizeof(unsigned));
    if(!order && nt){free(xyz);free(mats);return f;}
    for(unsigned t=0;t<nt;t++) order[t]=t;
    sortMaterials=mats; qsort(order,nt,sizeof(unsigned),orderCompare); sortMaterials=NULL;
    NSMutableData *vertices=[NSMutableData dataWithLength:(NSUInteger)nt*15*sizeof(float)];
    NSMutableData *materials=[NSMutableData dataWithLength:(NSUInteger)nt*sizeof(PortMaterial)];
    float *v=vertices.mutableBytes; PortMaterial *mm=materials.mutableBytes;
    for(unsigned t=0;t<nt;t++) {
        const model2_geo_tri_mat_t *m=&mats[order[t]];
        memcpy(v+t*15,xyz+order[t]*15,15*sizeof(float));
        mm[t].patch=(simd_float4){m->patch_x,m->patch_y,m->patch_w?m->patch_w:32,m->patch_h?m->patch_h:32};
        mm[t].meta=(simd_uint4){m->flags,m->sheet,0,0};
        if(m->flags&MODEL2_GEO_TEX_TEXTURED)
            model2_palette_build_texel_lut(m->colorbase,m->lumabase,m->luma,!!(m->flags&1),(u8 *)mm[t].lut);
        else {
            u8 rgb[3]; model2_palette_lookup_solid(m->colorbase,m->luma,rgb);
            for(int k=0;k<16;k++) mm[t].lut[k]=rgb[0]|(rgb[1]<<8)|(rgb[2]<<16)|0xff000000u;
        }
        if(!(m->pad&1)) {
            f.worldEnd=t+1;
            if(!(m->flags&4)) f.solidEnd=t+1;
            if(!(m->flags&4) || !(m->flags&1)) f.opaqueEnd=t+1;
        }
    }
    free(order); free(xyz); free(mats);
    static NSArray<NSData *> *cachedSheets; static u32 generation;
    u32 gen=model2_tex_sheets_dirty_gen();
    if(!cachedSheets || generation!=gen) {
        NSMutableArray *sheets=[NSMutableArray array];
        for(unsigned bank=0;bank<2;bank++) {
            NSMutableData *s=[NSMutableData dataWithLength:2048*1024];
            const u32 *source=model2_tex_sheet_bank(bank);
            if(source) model2_decode_sheet_indices(source,s.mutableBytes);
            [sheets addObject:s];
        }
        cachedSheets=[sheets copy]; generation=gen;
    }
    f.sheets=cachedSheets; f.vertices=vertices; f.materials=materials; f.triangles=nt;
    return f;
}
@end

@implementation PortRenderer {
    id<MTLCommandQueue> _queue;
    id<MTLRenderPipelineState> _tilePipeline,_geoPipeline;
    id<MTLDepthStencilState> _tileDepth,_solidDepth,_opaqueDepth,_cutoutDepth;
    id<MTLTexture> _bottom,_priority,_sheet[2];
    NSArray<NSData *> *_uploadedSheets;
    dispatch_semaphore_t _inFlight;
}
- (instancetype)initWithView:(MTKView *)view error:(NSError **)error {
    if(!(self=[super init])) return nil;
    view.colorPixelFormat=MTLPixelFormatBGRA8Unorm;
    view.depthStencilPixelFormat=MTLPixelFormatDepth32Float_Stencil8;
    view.clearColor=MTLClearColorMake(0,0,0,1); view.clearDepth=1; view.clearStencil=0;
    _queue=[view.device newCommandQueue]; _inFlight=dispatch_semaphore_create(1);
    NSURL *url=[NSBundle.mainBundle URLForResource:@"PortShaders" withExtension:@"metallib"];
    if(!url){if(error)*error=[NSError errorWithDomain:@"PortRenderer" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Metal shader library is missing"}];return nil;}
    id<MTLLibrary> library=[view.device newLibraryWithURL:url error:error]; if(!library) return nil;
    for(int k=0;k<2;k++) {
        MTLRenderPipelineDescriptor *d=[MTLRenderPipelineDescriptor new];
        d.vertexFunction=[library newFunctionWithName:k?@"geo_vertex":@"tile_vertex"];
        d.fragmentFunction=[library newFunctionWithName:k?@"geo_fragment":@"tile_fragment"];
        d.colorAttachments[0].pixelFormat=view.colorPixelFormat;
        d.depthAttachmentPixelFormat=d.stencilAttachmentPixelFormat=view.depthStencilPixelFormat;
        d.colorAttachments[0].blendingEnabled=!k;
        d.colorAttachments[0].sourceRGBBlendFactor=MTLBlendFactorSourceAlpha;
        d.colorAttachments[0].destinationRGBBlendFactor=MTLBlendFactorOneMinusSourceAlpha;
        d.colorAttachments[0].sourceAlphaBlendFactor=MTLBlendFactorOne;
        d.colorAttachments[0].destinationAlphaBlendFactor=MTLBlendFactorOneMinusSourceAlpha;
        id<MTLRenderPipelineState> pipeline=[view.device newRenderPipelineStateWithDescriptor:d error:error];
        if(!pipeline)return nil; if(k)_geoPipeline=pipeline;else _tilePipeline=pipeline;
    }
    for(int k=0;k<4;k++) {
        MTLDepthStencilDescriptor *d=[MTLDepthStencilDescriptor new];
        d.depthCompareFunction=k==0?MTLCompareFunctionAlways:k==1?MTLCompareFunctionLess:MTLCompareFunctionLessEqual;
        d.depthWriteEnabled=k==1 || k==2;
        if(k>=2) {
            MTLStencilDescriptor *st=[MTLStencilDescriptor new];
            st.stencilCompareFunction=MTLCompareFunctionEqual;
            st.depthStencilPassOperation=MTLStencilOperationIncrementClamp;
            st.readMask=st.writeMask=255; d.frontFaceStencil=d.backFaceStencil=st;
        }
        id<MTLDepthStencilState> state=[view.device newDepthStencilStateWithDescriptor:d];
        if(k==0)_tileDepth=state;else if(k==1)_solidDepth=state;else if(k==2)_opaqueDepth=state;else _cutoutDepth=state;
    }
    MTLTextureDescriptor *t=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:SYS24_FB_WIDTH height:SYS24_FB_HEIGHT mipmapped:NO];
    t.usage=MTLTextureUsageShaderRead; _bottom=[view.device newTextureWithDescriptor:t]; _priority=[view.device newTextureWithDescriptor:t];
    t.pixelFormat=MTLPixelFormatR8Unorm; t.width=2048;t.height=1024;
    _sheet[0]=[view.device newTextureWithDescriptor:t]; _sheet[1]=[view.device newTextureWithDescriptor:t];
    if(!_queue || !_bottom || !_priority || !_sheet[0] || !_sheet[1])return nil;
    view.delegate=self; return self;
}
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size { (void)view;(void)size; }
- (void)drawInMTKView:(MTKView *)view {
    if(dispatch_semaphore_wait(_inFlight,DISPATCH_TIME_NOW)!=0)return;
    PortFrame *f=self.frameProvider?self.frameProvider():nil;
    MTLRenderPassDescriptor *pass=view.currentRenderPassDescriptor;
    id<CAMetalDrawable> drawable=view.currentDrawable;
    if(!pass || !drawable){dispatch_semaphore_signal(_inFlight);return;}
    id<MTLCommandBuffer> cb=[_queue commandBuffer];
    if(!cb){dispatch_semaphore_signal(_inFlight);return;}
    dispatch_semaphore_t semaphore=_inFlight;
    [cb addCompletedHandler:^(id<MTLCommandBuffer> result){dispatch_semaphore_signal(semaphore);}];
    double width=view.drawableSize.width,height=view.drawableSize.height;
    double w=fmin(width,height*4/3), h=w*3/4;
    MTLViewport vp={(width-w)/2,(height-h)/2,w,h,0,1};
    pass.depthAttachment.storeAction=MTLStoreActionStore;
    pass.stencilAttachment.storeAction=MTLStoreActionStore;
    pass.colorAttachments[0].storeAction=MTLStoreActionStore;
    id<MTLRenderCommandEncoder> e=[cb renderCommandEncoderWithDescriptor:pass];
    [e setViewport:vp]; [e setCullMode:MTLCullModeNone];
    if(f.bottom) {
        [_bottom replaceRegion:MTLRegionMake2D(0,0,SYS24_FB_WIDTH,SYS24_FB_HEIGHT) mipmapLevel:0 withBytes:f.bottom.bytes bytesPerRow:SYS24_FB_WIDTH*4];
        [e setRenderPipelineState:_tilePipeline];[e setDepthStencilState:_tileDepth];[e setFragmentTexture:_bottom atIndex:0];
        [e drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    }
    id<MTLBuffer> vertices=nil,materials=nil;
    if(f.triangles) {
        if(_uploadedSheets!=f.sheets) {
            for(int k=0;k<2;k++) [_sheet[k] replaceRegion:MTLRegionMake2D(0,0,2048,1024) mipmapLevel:0 withBytes:f.sheets[k].bytes bytesPerRow:2048];
            _uploadedSheets=f.sheets;
        }
        vertices=[view.device newBufferWithBytes:f.vertices.bytes length:f.vertices.length options:MTLResourceStorageModeShared];
        materials=[view.device newBufferWithBytes:f.materials.bytes length:f.materials.length options:MTLResourceStorageModeShared];
    }
    PortProjection p={0};if(f){p.viewport=f.viewport;p.focalCenter=f.focalCenter;}
    if(vertices && materials) {
        [e setRenderPipelineState:_geoPipeline];[e setVertexBuffer:vertices offset:0 atIndex:0];[e setVertexBytes:&p length:sizeof(p) atIndex:2];
        [e setFragmentBuffer:materials offset:0 atIndex:1];[e setFragmentTexture:_sheet[0] atIndex:0];[e setFragmentTexture:_sheet[1] atIndex:1];
        [e setDepthStencilState:_solidDepth];[e drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:f.solidEnd*3];
        [e setDepthStencilState:_opaqueDepth];[e setStencilReferenceValue:0];
        [e drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:f.solidEnd*3 vertexCount:(f.opaqueEnd-f.solidEnd)*3];
    }
    [e endEncoding];
    // A fresh fillmap for cutouts, while retaining opaque depth and tile colors.
    MTLRenderPassDescriptor *top=[pass copy];
    top.colorAttachments[0].loadAction=MTLLoadActionLoad;top.depthAttachment.loadAction=MTLLoadActionLoad;top.stencilAttachment.loadAction=MTLLoadActionClear;
    e=[cb renderCommandEncoderWithDescriptor:top]; [e setViewport:vp];[e setCullMode:MTLCullModeNone];
    if(vertices && materials) {
        [e setRenderPipelineState:_geoPipeline];[e setVertexBuffer:vertices offset:0 atIndex:0];[e setVertexBytes:&p length:sizeof(p) atIndex:2];
        [e setFragmentBuffer:materials offset:0 atIndex:1];[e setFragmentTexture:_sheet[0] atIndex:0];[e setFragmentTexture:_sheet[1] atIndex:1];
        [e setDepthStencilState:_cutoutDepth];[e setStencilReferenceValue:0];
        [e drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:f.opaqueEnd*3 vertexCount:(f.worldEnd-f.opaqueEnd)*3];
        [e setDepthStencilState:_tileDepth];[e drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:f.worldEnd*3 vertexCount:(f.triangles-f.worldEnd)*3];
    }
    if(f.priority) {
        [_priority replaceRegion:MTLRegionMake2D(0,0,SYS24_FB_WIDTH,SYS24_FB_HEIGHT) mipmapLevel:0 withBytes:f.priority.bytes bytesPerRow:SYS24_FB_WIDTH*4];
        [e setRenderPipelineState:_tilePipeline];[e setDepthStencilState:_tileDepth];[e setFragmentTexture:_priority atIndex:0];
        [e drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    }
    [e endEncoding];[cb presentDrawable:drawable];[cb commit];
}
@end
