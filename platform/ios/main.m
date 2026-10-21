// Asset-free integration scaffold; no game/core is linked or executed.
#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>

@interface PortViewController : UIViewController <MTKViewDelegate>
@property(nonatomic, strong) MTKView *metalView;
@property(nonatomic, strong) id<MTLCommandQueue> queue;
@end

@implementation PortViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    UILabel *status = [[UILabel alloc] init];
    status.text = device ? @"iOS scaffold — game integration pending"
                         : @"Metal device unavailable — game not started";
    status.textColor = UIColor.whiteColor;
    status.textAlignment = NSTextAlignmentCenter;
    status.numberOfLines = 0;
    status.translatesAutoresizingMaskIntoConstraints = NO;
    if (device) {
        self.queue = [device newCommandQueue];
        self.metalView = [[MTKView alloc] initWithFrame:CGRectZero device:device];
        self.metalView.translatesAutoresizingMaskIntoConstraints = NO;
        self.metalView.clearColor = MTLClearColorMake(0.02, 0.03, 0.06, 1);
        self.metalView.delegate = self;
        self.metalView.paused = YES;
        [self.view addSubview:self.metalView];
        [NSLayoutConstraint activateConstraints:@[
            [self.metalView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.metalView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [self.metalView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [self.metalView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];
    }
    [self.view addSubview:status];
    [NSLayoutConstraint activateConstraints:@[
        [status.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:16],
        [status.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-16],
        [status.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]]];
}
- (void)drawInMTKView:(MTKView *)view {
    MTLRenderPassDescriptor *pass = view.currentRenderPassDescriptor;
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!pass || !drawable || !self.queue) return;
    id<MTLCommandBuffer> buffer = [self.queue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:pass];
    [encoder endEncoding];
    [buffer presentDrawable:drawable];
    [buffer commit];
}
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    // Future: recalculate letterbox viewport; do not alter game projection.
}
@end

@interface PortAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, strong) PortViewController *controller;
@end

@implementation PortAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.controller = [[PortViewController alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = self.controller;
    [self.window makeKeyAndVisible];
    return YES;
}
- (void)applicationWillResignActive:(UIApplication *)application {
    self.controller.metalView.paused = YES;
    // Future: pause core, clear held inputs, stop audio and persist NVRAM.
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    self.controller.metalView.paused = NO;
    // Future: resume core/audio only after session and asset validation.
}
@end

int main(int argc, char **argv) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(PortAppDelegate.class));
    }
}
