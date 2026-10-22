#import <MetalKit/MetalKit.h>
#import <simd/simd.h>
#include "port_host.h"

@interface PortFrame : NSObject
@property(nonatomic, strong) NSData *bottom, *priority, *vertices, *materials;
@property(nonatomic, strong) NSArray<NSData *> *sheets;
@property(nonatomic) simd_float4 viewport, focalCenter;
@property(nonatomic) NSUInteger solidEnd, opaqueEnd, worldEnd, triangles;
+ (instancetype)captureBottom:(const uint32_t *)bottom priority:(const uint32_t *)priority opaque:(BOOL)opaque;
@end
@interface PortRenderer : NSObject <MTKViewDelegate>
@property(nonatomic, copy) PortFrame *(^frameProvider)(void);
- (instancetype)initWithView:(MTKView *)view error:(NSError **)error;
@end
