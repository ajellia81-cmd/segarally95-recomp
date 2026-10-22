#include <metal_stdlib>
using namespace metal;
struct Material { float4 patch; uint4 meta; uint lut[16]; };
struct Projection { float4 viewport; float4 focalCenter; };
struct Raster { float4 position [[position]]; float2 uv; uint material [[flat]]; };
vertex Raster geo_vertex(uint id [[vertex_id]], device const float *v [[buffer(0)]],
                         constant Projection &p [[buffer(2)]]) {
    float3 xyz=float3(v[id*5],v[id*5+1],v[id*5+2]);
    float w=p.viewport.z-p.viewport.x, h=p.viewport.w-p.viewport.y;
    float ox=2*(p.focalCenter.x-p.viewport.x)/w-1;
    float oy=1-2*(p.viewport.w-p.focalCenter.y)/h;
    Raster r;
    // Same positive-Z infinite projection as desktop, with Metal's 0..1 depth.
    r.position=float4(2*xyz.x/w+ox*xyz.z,2*xyz.y/h+oy*xyz.z,xyz.z-0.01,xyz.z);
    r.uv=float2(v[id*5+3],v[id*5+4]); r.material=id/3;
    return r;
}
float wrap_coord(float x,float size,bool mirror) {
    float s=max(size,1.0), cell=floor(x/s), local=x-cell*s;
    if (mirror && fmod(cell,2.0)>=1.0) local=s-1-local;
    return floor(local-floor(local/s)*s);
}
fragment float4 geo_fragment(Raster in [[stage_in]], device const Material *mats [[buffer(1)]],
                            texture2d<float> sheet0 [[texture(0)]], texture2d<float> sheet1 [[texture(1)]]) {
    Material m=mats[in.material]; uint index=0;
    if (m.meta.x & 4u) {
        float u=wrap_coord(in.uv.x,m.patch.z,(m.meta.x&32u)!=0);
        float v=wrap_coord(in.uv.y,m.patch.w,(m.meta.x&64u)!=0);
        uint2 coord=min(uint2(m.patch.xy+float2(u,v)),uint2(2047,1023));
        float texel=(m.meta.y&1u)?sheet1.read(coord).r:sheet0.read(coord).r;
        index=min(uint(round(texel*255)),15u);
    }
    uint c=m.lut[index];
    float4 rgba=float4(float(c&255),float((c>>8)&255),float((c>>16)&255),float(c>>24))/255;
    if ((m.meta.x&1u) && rgba.a<0.5) discard_fragment();
    return float4(rgba.rgb,1);
}
struct TileRaster { float4 position [[position]]; float2 uv; };
vertex TileRaster tile_vertex(uint id [[vertex_id]]) {
    const float2 pos[6]={float2(-1,1),float2(-1,-1),float2(1,1),float2(1,1),float2(-1,-1),float2(1,-1)};
    TileRaster r; r.position=float4(pos[id],0,1); r.uv=float2((pos[id].x+1)/2,(1-pos[id].y)/2); return r;
}
fragment float4 tile_fragment(TileRaster in [[stage_in]],texture2d<float> tiles [[texture(0)]]) {
    constexpr sampler nearest(coord::normalized,filter::nearest,address::clamp_to_edge);
    return tiles.sample(nearest,in.uv);
}
