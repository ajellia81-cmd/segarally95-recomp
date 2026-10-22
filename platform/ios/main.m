#import <UIKit/UIKit.h>
#import <GameController/GameController.h>
#import "PortRenderer.h"
#import "PortAudio.h"
#include "i960_host.h"
#include "model2_rom.h"
#include "model2_nvram.h"
#include "model2_snd.h"
#include "sys24_viewer.h"
#include "track_viewer.h"
#include <sys/stat.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>

@interface PortSession : NSObject
@property(nonatomic,copy) void (^statusChanged)(NSString *);
@property(nonatomic,copy) void (^parked)(void);
@property(nonatomic,strong) PortAudio *audio;
- (void)start;
- (void)setActive:(BOOL)active;
- (void)setInterrupted:(BOOL)interrupted;
- (void)togglePause;
- (void)stop;
- (void)setTouch:(port_input_t)input;
- (void)setPad:(port_input_t)input;
- (PortFrame *)frame;
- (int)poll;
- (void)publish:(PortFrame *)frame;
- (void)audioStart;
- (void)audioStop;
@end
static PortSession *sessionOwner;

@implementation PortSession {
    NSCondition *_gate;
    BOOL _active,_interrupted,_paused,_stop,_running,_everStarted;
    port_input_t _touch,_pad;
    unsigned _gear;
    PortFrame *_frame;
}
- (instancetype)init {
    if((self=[super init])){_gate=[NSCondition new];_active=YES;self.audio=[PortAudio new];}return self;
}
- (void)status:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(),^{if(self.statusChanged)self.statusChanged(text);});
}
- (void)setTouch:(port_input_t)input { [_gate lock];if(_active&&!_interrupted&&!_paused){if(input.gear!=_touch.gear)_gear=input.gear;_touch=input;}[_gate unlock]; }
- (void)setPad:(port_input_t)input { [_gate lock];if(_active&&!_interrupted&&!_paused){if(input.gear!=_pad.gear)_gear=input.gear;_pad=input;}[_gate unlock]; }
- (void)updateAudio {
    [_gate lock];BOOL play=_running&&_active&&!_interrupted&&!_paused&&!_stop;[_gate unlock];
    if(play){NSError *error=nil;if(![self.audio start:&error])[self status:[@"오디오: " stringByAppendingString:error.localizedDescription?:@"시작 실패"]];}
    else [self.audio stop];
}
- (void)changeGate {
    memset(&_touch,0,sizeof(_touch));memset(&_pad,0,sizeof(_pad));_gear=0;[_gate broadcast];
}
- (void)setActive:(BOOL)active { [_gate lock];_active=active;[self changeGate];[_gate unlock];[self updateAudio]; }
- (void)setInterrupted:(BOOL)value { [_gate lock];_interrupted=value;[self changeGate];[_gate unlock];[self updateAudio]; }
- (void)togglePause { [_gate lock];_paused=!_paused;_interrupted=NO;[self changeGate];BOOL p=_paused;[_gate unlock];[self status:p?@"일시정지":@"실행 중 — 실기기 검증 전"];[self updateAudio]; }
- (void)stop { [_gate lock];_stop=YES;[self changeGate];[_gate unlock];[self.audio stop]; }
- (PortFrame *)frame { [_gate lock];PortFrame *f=_frame;[_gate unlock];return f; }
- (void)publish:(PortFrame *)frame { [_gate lock];_frame=frame;[_gate unlock]; }
- (void)audioStart { dispatch_async(dispatch_get_main_queue(),^{[self updateAudio];}); }
- (void)audioStop { dispatch_async(dispatch_get_main_queue(),^{[self.audio stop];}); }
- (int)poll {
    [_gate lock];
    BOOL wait=!_active||_interrupted||_paused;
    if(wait&&!_stop) {
        [_gate unlock];
        port_input_release();model2_snd_set_paused(1);
        int saved=model2_nvram_save(NULL);
        if(saved)[self status:@"저장 실패 — 저장 공간과 파일 권한을 확인하세요"];
        dispatch_async(dispatch_get_main_queue(),^{if(self.parked)self.parked();});
        [_gate lock];
        while((!_active||_interrupted||_paused)&&!_stop)[_gate wait];
        BOOL ending=_stop;[_gate unlock];
        if(!ending)model2_snd_set_paused(0);
        [_gate lock];
    }
    BOOL end=_stop;port_input_t a=_touch,b=_pad;unsigned gear=_gear;[_gate unlock];
    if(end){port_input_release();return 1;}
    port_input_t mix={fabsf(a.steer)>0?a.steer:b.steer,fmaxf(a.throttle,b.throttle),fmaxf(a.brake,b.brake),a.coin||b.coin,a.start||b.start,a.view||b.view,gear};
    port_input_apply(&mix);return 0;
}
- (void)start {
    [_gate lock];
    if(_everStarted){[_gate unlock];[self status:@"다시 시작하려면 앱을 완전히 종료한 뒤 열어 주세요"];return;}
    [_gate unlock];
    NSFileManager *fm=NSFileManager.defaultManager;
    NSURL *documents=[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *roms=[documents URLByAppendingPathComponent:@"ROMs" isDirectory:YES];
    NSURL *support=[[fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject URLByAppendingPathComponent:@"SegaRally" isDirectory:YES];
    NSError *error=nil;
    if(![fm createDirectoryAtURL:roms withIntermediateDirectories:YES attributes:nil error:&error] ||
       ![fm createDirectoryAtURL:support withIntermediateDirectories:YES attributes:nil error:&error]) {
        [self status:error.localizedDescription];return;
    }
    NSString *cpu=[[roms URLByAppendingPathComponent:@"maincpu_deinterleaved.bin"] path];
    NSString *data=[[roms URLByAppendingPathComponent:@"main_data_deinterleaved.bin"] path];
    for(NSArray *item in @[@[cpu,@(0x100000)],@[data,@(0xc00000)]]) {
        NSDictionary *attr=[fm attributesOfItemAtPath:item[0] error:nil];
        if(![attr[NSFileType] isEqual:NSFileTypeRegular] || [attr fileSize]!=[item[1] unsignedLongLongValue]) {
            [self status:@"필요한 게임 파일이 없습니다. 파일 앱의 이 앱/ROMs 폴더에 개인 소유 파일을 준비하세요. 자세한 목록은 프로젝트 README에 있습니다."];return;
        }
    }
    [_gate lock];_running=_everStarted=YES;[_gate unlock];
    NSString *save=[[support URLByAppendingPathComponent:@"nvram.yaml"] path];
    [self status:@"코어 초기화 중…"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        @autoreleasepool {
            setenv("SEGAMOD2_ROM_DIR",roms.fileSystemRepresentation,1);
            setenv("I960_HOST_NVRAM",save.fileSystemRepresentation,1);
            setenv("I960_HOST_ASPECT","4:3",1);
            int result=-1;
            if(model2_romset_verify()==0 && i960_host_load_extracted(cpu.fileSystemRepresentation,data.fileSystemRepresentation)==0 &&
               i960_host_reset_checked(roms.fileSystemRepresentation)==0) {
                track_viewer_opts_t opts={0};opts.viewer_boot=1;opts.live_view=1;opts.aspect="4:3";
                [self status:@"실행 중 — 실기기 검증 전"];
                result=i960_lift_boot_screen_run(&opts);
                // Also closes partially allocated viewer state if viewer_open failed.
                sys24_viewer_shutdown();
            } else {
                model2_snd_reset();
                [self status:@"게임 파일 검증 또는 코어 초기화 실패. 앱을 다시 열기 전에 README의 파일 목록을 확인하세요."];
            }
            [_gate lock];_running=NO;[_gate unlock];
            [self audioStop];
            if(result==0)[self status:@"종료됨 — 다시 시작하려면 앱을 다시 열어 주세요"];
            dispatch_async(dispatch_get_main_queue(),^{if(self.parked)self.parked();});
        }
    });
}
@end
int port_host_poll(void){return [sessionOwner poll];}
void port_host_publish(const uint32_t *bottom,const uint32_t *priority,int opaque){
    @autoreleasepool {[sessionOwner publish:[PortFrame captureBottom:bottom priority:priority opaque:opaque]];}
}
void port_host_audio_start(void){[sessionOwner audioStart];}
void port_host_audio_stop(void){[sessionOwner audioStop];}

@interface PortViewController : UIViewController
@property(nonatomic,strong) MTKView *metalView;
@end
@implementation PortViewController {
    PortRenderer *_renderer;
    UILabel *_status;
    port_input_t _touch,_pad;
    GCController *_controller;
    BOOL _leftHeld,_rightHeld;
}
- (UIButton *)button:(NSString *)name tag:(NSInteger)tag {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.tag=tag;
    [b setTitle:name forState:UIControlStateNormal];b.backgroundColor=[UIColor colorWithWhite:0.12 alpha:0.8];b.tintColor=UIColor.whiteColor;
    [b addTarget:self action:@selector(down:) forControlEvents:UIControlEventTouchDown];
    [b addTarget:self action:@selector(up:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    return b;
}
- (void)viewDidLoad {
    [super viewDidLoad];self.view.backgroundColor=UIColor.blackColor;
    sessionOwner=[PortSession new];
    if([NSProcessInfo.processInfo.environment[@"PORT_RENDER_SMOKE"] isEqual:@"1"])
        [sessionOwner publish:[PortFrame syntheticTestFrame]];
    __weak PortViewController *weak=self;
    _status=[UILabel new];_status.textColor=UIColor.whiteColor;_status.numberOfLines=3;_status.font=[UIFont systemFontOfSize:13];
    _status.text=@"개인용 iOS 포트 — 실제 게임·기기 검증 전";
    sessionOwner.statusChanged=^(NSString *s){PortViewController *strong=weak;if(strong)strong->_status.text=s;};
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    if(device) {
        self.metalView=[[MTKView alloc] initWithFrame:CGRectZero device:device];
        NSError *error=nil;_renderer=[[PortRenderer alloc] initWithView:self.metalView error:&error];
        _renderer.frameProvider=^{return [sessionOwner frame];};
        if(!_renderer)_status.text=error.localizedDescription?:@"Metal 준비 실패";
        self.metalView.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:self.metalView];
        [NSLayoutConstraint activateConstraints:@[[self.metalView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],[self.metalView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],[self.metalView.topAnchor constraintEqualToAnchor:self.view.topAnchor],[self.metalView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];
    } else _status.text=@"Metal을 사용할 수 없는 기기입니다";
    UIStackView *top=[[UIStackView alloc] initWithArrangedSubviews:@[_status,[self button:@"시작" tag:20],[self button:@"일시정지" tag:21],[self button:@"종료" tag:22]]];
    top.spacing=12;top.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:top];
    NSMutableArray *controls=[NSMutableArray array];
    NSArray *names=@[@"◀",@"▶",@"가속",@"브레이크",@"코인",@"START",@"시점",@"기어"];
    for(NSUInteger i=0;i<names.count;i++)[controls addObject:[self button:names[i] tag:i]];
    UIStackView *bottom=[[UIStackView alloc] initWithArrangedSubviews:controls];bottom.spacing=6;bottom.distribution=UIStackViewDistributionFillEqually;bottom.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:bottom];
    [NSLayoutConstraint activateConstraints:@[[top.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],[top.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:10],[top.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-10],[bottom.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:10],[bottom.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-10],[bottom.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8],[bottom.heightAnchor constraintEqualToConstant:52]]];
    NSNotificationCenter *nc=NSNotificationCenter.defaultCenter;
    [nc addObserver:self selector:@selector(controllerChanged:) name:GCControllerDidConnectNotification object:nil];
    [nc addObserver:self selector:@selector(controllerChanged:) name:GCControllerDidDisconnectNotification object:nil];
    [nc addObserver:self selector:@selector(interruption:) name:AVAudioSessionInterruptionNotification object:nil];
    [nc addObserver:self selector:@selector(audioConfiguration:) name:AVAudioEngineConfigurationChangeNotification object:nil];
    [nc addObserver:self selector:@selector(inactive:) name:UIApplicationWillResignActiveNotification object:nil];
    [self controllerChanged:nil];
}
- (void)inactive:(NSNotification *)n { memset(&_touch,0,sizeof(_touch));memset(&_pad,0,sizeof(_pad));_leftHeld=_rightHeld=NO; }
- (void)down:(UIButton *)b {
    if(b.tag==20){if(_renderer)[sessionOwner start];return;}
    if(b.tag==21){[sessionOwner togglePause];[self inactive:nil];return;}
    if(b.tag==22){[sessionOwner stop];return;}
    switch(b.tag){case 0:_leftHeld=YES;break;case 1:_rightHeld=YES;break;case 2:_touch.throttle=1;break;case 3:_touch.brake=1;break;case 4:_touch.coin=1;break;case 5:_touch.start=1;break;case 6:_touch.view=1;break;case 7:_touch.gear=_touch.gear%4+1;break;}
    _touch.steer=(float)_rightHeld-(float)_leftHeld;
    [sessionOwner setTouch:_touch];
}
- (void)up:(UIButton *)b {
    switch(b.tag){case 0:_leftHeld=NO;break;case 1:_rightHeld=NO;break;case 2:_touch.throttle=0;break;case 3:_touch.brake=0;break;case 4:_touch.coin=0;break;case 5:_touch.start=0;break;case 6:_touch.view=0;break;}
    _touch.steer=(float)_rightHeld-(float)_leftHeld;
    [sessionOwner setTouch:_touch];
}
- (void)controllerChanged:(NSNotification *)note {
    _controller.extendedGamepad.valueChangedHandler=nil;
    _controller.extendedGamepad.leftShoulder.pressedChangedHandler=nil;
    _controller.extendedGamepad.rightShoulder.pressedChangedHandler=nil;
    _controller=nil;memset(&_pad,0,sizeof(_pad));[sessionOwner setPad:_pad];
    for(GCController *c in GCController.controllers)if(c.extendedGamepad){_controller=c;break;}
    if(!_controller)return;
    _controller.handlerQueue=dispatch_get_main_queue();_pad.gear=1;
    __weak PortViewController *weak=self;
    _controller.extendedGamepad.valueChangedHandler=^(GCExtendedGamepad *p,GCControllerElement *e){
        PortViewController *self=weak;if(!self)return;
        float x=p.leftThumbstick.xAxis.value;if(fabsf(x)<0.15)x=p.dpad.xAxis.value;
        self->_pad.steer=x;self->_pad.throttle=fmaxf(p.rightTrigger.value,p.buttonA.value);self->_pad.brake=fmaxf(p.leftTrigger.value,p.buttonB.value);
        self->_pad.start=p.buttonMenu.isPressed;self->_pad.coin=p.buttonY.isPressed;self->_pad.view=p.buttonX.isPressed;
        [sessionOwner setPad:self->_pad];
    };
    _controller.extendedGamepad.leftShoulder.pressedChangedHandler=^(GCControllerButtonInput *b,float value,BOOL pressed){PortViewController *s=weak;if(s&&pressed){s->_pad.gear=s->_pad.gear>1?s->_pad.gear-1:1;[sessionOwner setPad:s->_pad];}};
    _controller.extendedGamepad.rightShoulder.pressedChangedHandler=^(GCControllerButtonInput *b,float value,BOOL pressed){PortViewController *s=weak;if(s&&pressed){s->_pad.gear=s->_pad.gear<4?s->_pad.gear+1:4;[sessionOwner setPad:s->_pad];}};
}
- (void)interruption:(NSNotification *)n {
    BOOL began=[n.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue]==AVAudioSessionInterruptionTypeBegan;
    BOOL resume=[n.userInfo[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue]&AVAudioSessionInterruptionOptionShouldResume;
    [self inactive:nil];[sessionOwner setInterrupted:began||!resume];
}
- (void)audioConfiguration:(NSNotification *)n {
    dispatch_async(dispatch_get_main_queue(),^{[sessionOwner.audio stop];[sessionOwner audioStart];});
}
- (void)dealloc { [NSNotificationCenter.defaultCenter removeObserver:self]; }
@end

@interface PortAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) PortViewController *controller;
@end
@implementation PortAppDelegate {
    UIBackgroundTaskIdentifier _background;
}
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    _background=UIBackgroundTaskInvalid;
    self.controller=[PortViewController new];self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController=self.controller;[self.controller loadViewIfNeeded];[self.window makeKeyAndVisible];
    __weak PortAppDelegate *weak=self;
    sessionOwner.parked=^{PortAppDelegate *s=weak;if(s&&s->_background!=UIBackgroundTaskInvalid){[UIApplication.sharedApplication endBackgroundTask:s->_background];s->_background=UIBackgroundTaskInvalid;}};
    return YES;
}
- (void)applicationWillResignActive:(UIApplication *)app {
    if(_background==UIBackgroundTaskInvalid)_background=[app beginBackgroundTaskWithName:@"Pause core and save" expirationHandler:^{[sessionOwner stop];if(self->_background!=UIBackgroundTaskInvalid){[app endBackgroundTask:self->_background];self->_background=UIBackgroundTaskInvalid;}}];
    [sessionOwner setActive:NO];self.controller.metalView.paused=YES;
}
- (void)applicationDidBecomeActive:(UIApplication *)app {
    [sessionOwner setActive:YES];self.controller.metalView.paused=NO;
    if(_background!=UIBackgroundTaskInvalid){[app endBackgroundTask:_background];_background=UIBackgroundTaskInvalid;}
}
- (void)applicationWillTerminate:(UIApplication *)app { [sessionOwner stop]; }
@end
int main(int argc,char **argv) { @autoreleasepool {return UIApplicationMain(argc,argv,nil,NSStringFromClass(PortAppDelegate.class));} }
