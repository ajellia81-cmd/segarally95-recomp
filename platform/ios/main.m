#import <UIKit/UIKit.h>
#import <GameController/GameController.h>
#import "PortRenderer.h"
#import "PortAudio.h"
#import "PortROMPreparation.h"
#include "i960_host.h"
#include "model2_rom.h"
#include "model2_rom_dir.h"
#include <errno.h>
#include "model2_nvram.h"
#include "model2_snd.h"
#include "sys24_viewer.h"
#include "track_viewer.h"
#include <sys/stat.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include "port_display.h"

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
- (void)reportError:(NSString *)message;
- (void)audioStart;
- (void)audioStop;
@end
static PortSession *sessionOwner;

@implementation PortSession {
    NSCondition *_gate;
    BOOL _active,_interrupted,_paused,_stop,_running,_everStarted,_hadError,_preparing;
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
- (void)reportError:(NSString *)message { [_gate lock];_hadError=YES;[_gate unlock];[self status:message]; }
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
- (void)togglePause { [_gate lock];_paused=_interrupted?NO:!_paused;_interrupted=NO;[self changeGate];BOOL p=_paused;[_gate unlock];[self status:p?@"일시정지":@"실행 중 — 실기기 검증 전"];[self updateAudio]; }
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
        if(saved)[self reportError:@"저장 실패 — 저장 공간과 파일 권한을 확인하세요"];
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
    if(_preparing){[_gate unlock];return;}
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
    if(![roms setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error]) {
        [self status:error.localizedDescription];return;
    }
    [_gate lock];_preparing=YES;_stop=NO;[_gate unlock];
    NSString *save=[[support URLByAppendingPathComponent:@"nvram.yaml"] path];
    [self status:@"ZIP 확인 및 게임 파일 준비 중…"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        @autoreleasepool {
            NSError *prepareError=nil;
            NSURL *ready=PortPrepareROMs(roms,support,&prepareError);
            [_gate lock];_preparing=NO;BOOL cancelled=_stop;
            if(ready&&!cancelled){_running=_everStarted=YES;_hadError=NO;[self changeGate];}
            [_gate unlock];
            if(!ready){[self status:prepareError.localizedDescription?:@"게임 파일 준비 실패"];
                dispatch_async(dispatch_get_main_queue(),^{if(self.parked)self.parked();});return;}
            if(cancelled){[self status:@"파일 준비가 취소되었습니다"];
                dispatch_async(dispatch_get_main_queue(),^{if(self.parked)self.parked();});return;}
            NSString *cpu=[ready URLByAppendingPathComponent:@"maincpu_deinterleaved.bin"].path;
            NSString *data=[ready URLByAppendingPathComponent:@"main_data_deinterleaved.bin"].path;
            // Embedded hosts can virtualize getenv/setenv. All lazy board loaders
            // must use the same owned path as verification and BIN/sound loading.
            int directoryResult=model2_set_rom_directory(ready.fileSystemRepresentation);
            setenv("SEGAMOD2_ROM_DIR",ready.fileSystemRepresentation,1);
            setenv("I960_HOST_NVRAM",save.fileSystemRepresentation,1);
            setenv("I960_HOST_ASPECT","4:3",1);
            [self status:@"코어 초기화 중…"];
            NSMutableString *diagnostics=[NSMutableString stringWithFormat:@"Sega Rally Championship %@ (%@)\nPrepared directory: %@\nExplicit directory result: %d\n",
                NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
                NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"],ready.path,directoryResult];
            for(NSString *path in @[cpu,data]) {
                struct stat st;int rc=stat(path.fileSystemRepresentation,&st);int code=rc?errno:0;
                [diagnostics appendFormat:@"%@: stat=%d errno=%d size=%lld\n",path.lastPathComponent,rc,code,rc?-1LL:(long long)st.st_size];
            }
            char validation[512]={0};
            NSString *failure=nil,*stage=@"경로 설정";
            if(directoryResult)failure=@"준비 디렉터리 경로를 설정할 수 없습니다";
            if(!failure) {
                stage=@"ROM 검증";
                int rc=model2_romset_verify_at(ready.fileSystemRepresentation,validation,sizeof(validation));
                [diagnostics appendFormat:@"ROM verification: %d %s\n",rc,validation];
                if(rc)failure=[NSString stringWithUTF8String:validation];
            }
            if(!failure) {
                stage=@"BIN 로딩";
                errno=0;int rc=i960_host_load_extracted(cpu.fileSystemRepresentation,data.fileSystemRepresentation);int code=errno;
                [diagnostics appendFormat:@"BIN loading: %d errno=%d\n",rc,code];
                if(rc)failure=[NSString stringWithFormat:@"maincpu/main_data BIN 읽기 실패 (errno=%d)",code];
            }
            if(!failure) {
                stage=@"사운드/코어 초기화";
                int rc=i960_host_reset_checked(ready.fileSystemRepresentation);
                [diagnostics appendFormat:@"Core reset: %d %s\n",rc,model2_snd_last_error()];
                if(rc)failure=[NSString stringWithUTF8String:model2_snd_last_error()];
            }
            [diagnostics writeToURL:[documents URLByAppendingPathComponent:@"startup-diagnostics.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
            int result=-1;
            if(!failure) {
                track_viewer_opts_t opts={0};opts.viewer_boot=1;opts.live_view=1;opts.aspect="4:3";
                [self status:@"실행 중 — 실기기 검증 전"];
                result=i960_lift_boot_screen_run(&opts);
                // Also closes partially allocated viewer state if viewer_open failed.
                if(result!=0)sys24_viewer_shutdown();
            } else {
                model2_snd_reset();
                [self reportError:[NSString stringWithFormat:@"시작 실패 [%@]\n%@\n파일 앱의 startup-diagnostics.txt에 기록했습니다.",stage,failure.length?failure:@"오류 상세 없음"]];
            }
            [_gate lock];_running=NO;BOOL hadError=_hadError;[_gate unlock];
            [self audioStop];
            if(result==0&&!hadError)[self status:@"종료됨 — 다시 시작하려면 앱을 다시 열어 주세요"];
            else if(result>0&&!hadError)[self reportError:@"화면 초기화 또는 코어 실행에 실패했습니다"];
            dispatch_async(dispatch_get_main_queue(),^{if(self.parked)self.parked();});
        }
    });
}
@end
int port_host_poll(void){return [sessionOwner poll];}
void port_host_publish(const uint32_t *bottom,const uint32_t *priority,int opaque){
    @autoreleasepool {[sessionOwner publish:[PortFrame captureBottom:bottom priority:priority opaque:opaque]];}
}
void port_host_report_error(const char *message){[sessionOwner reportError:[NSString stringWithUTF8String:message]];}
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
    UIStackView *_leftRail,*_rightRail;
    NSArray<UIView *> *_touchControls;
    BOOL _smokePolicyValid;
}
- (UIButton *)button:(NSString *)name tag:(NSInteger)tag {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.tag=tag;
    [b setTitle:name forState:UIControlStateNormal];b.backgroundColor=[UIColor colorWithWhite:0.12 alpha:0.8];b.tintColor=UIColor.whiteColor;
    [b addTarget:self action:@selector(down:) forControlEvents:UIControlEventTouchDown];
    [b addTarget:self action:@selector(up:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    b.titleLabel.adjustsFontSizeToFitWidth=YES;b.titleLabel.minimumScaleFactor=0.7;
    b.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    b.layer.cornerRadius=8;
    NSLayoutConstraint *height=[b.heightAnchor constraintGreaterThanOrEqualToConstant:44];
    height.priority=999;height.active=YES;
    return b;
}
- (void)viewDidLoad {
    [super viewDidLoad];self.view.backgroundColor=UIColor.blackColor;
    sessionOwner=[PortSession new];
    if([NSProcessInfo.processInfo.environment[@"PORT_RENDER_SMOKE"] isEqual:@"1"])
        [sessionOwner publish:[PortFrame syntheticTestFrame]];
    __weak PortViewController *weak=self;
    _status=[UILabel new];_status.textColor=UIColor.whiteColor;_status.numberOfLines=3;_status.font=[UIFont systemFontOfSize:13];
    _status.text=@"SEGA RALLY\nROMs에 ZIP을 넣고 시작하세요";
    sessionOwner.statusChanged=^(NSString *s){
        PortViewController *strong=weak;if(!strong)return;strong->_status.text=s;
        if([s hasPrefix:@"시작 실패 ["]&&!strong.presentedViewController) {
            UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"시작 오류" message:s preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault handler:nil]];
            [strong presentViewController:alert animated:YES completion:nil];
        }
    };
    id<MTLDevice> device=MTLCreateSystemDefaultDevice();
    if(device) {
        self.metalView=[[MTKView alloc] initWithFrame:CGRectZero device:device];
        NSError *error=nil;_renderer=[[PortRenderer alloc] initWithView:self.metalView error:&error];
        _renderer.frameProvider=^{return [sessionOwner frame];};
        if(!_renderer)_status.text=error.localizedDescription?:@"Metal 준비 실패";
        self.metalView.autoResizeDrawable=NO;
        self.metalView.preferredFramesPerSecond=60;
    } else _status.text=@"Metal을 사용할 수 없는 기기입니다";
    // Keep controls outside the game canvas, inside the notch/home safe area.
    UIStackView *(^row)(NSArray *)=^UIStackView *(NSArray *buttons){
        UIStackView *r=[[UIStackView alloc] initWithArrangedSubviews:buttons];
        r.spacing=6;r.distribution=UIStackViewDistributionFillEqually;return r;
    };
    UIView *leftSpace=[UIView new],*rightSpace=[UIView new];
    UIStackView *steer=row(@[[self button:@"◀" tag:0],[self button:@"▶" tag:1]]);
    UIStackView *coinStart=row(@[[self button:@"코인" tag:4],[self button:@"START" tag:5]]);
    UIStackView *viewGear=row(@[[self button:@"시점" tag:6],[self button:@"기어" tag:7]]);
    _leftRail=[[UIStackView alloc] initWithArrangedSubviews:@[_status,leftSpace,steer,coinStart,viewGear]];
    UIButton *gas=[self button:@"가속" tag:2],*brake=[self button:@"브레이크" tag:3];
    for(UIButton *pedal in @[gas,brake]) {
        NSLayoutConstraint *height=[pedal.heightAnchor constraintEqualToConstant:68];
        height.priority=999;height.active=YES;
    }
    _touchControls=@[steer,coinStart,viewGear,gas,brake];
    _rightRail=[[UIStackView alloc] initWithArrangedSubviews:@[
        [self button:@"시작" tag:20],[self button:@"일시정지" tag:21],
        [self button:@"종료" tag:22],rightSpace,gas,brake]];
    for(UIStackView *rail in @[_leftRail,_rightRail]) {
        rail.axis=UILayoutConstraintAxisVertical;rail.spacing=6;
        [rail.widthAnchor constraintEqualToConstant:112].active=YES;
    }
    [leftSpace setContentHuggingPriority:1 forAxis:UILayoutConstraintAxisVertical];
    [rightSpace setContentHuggingPriority:1 forAxis:UILayoutConstraintAxisVertical];
    [_status setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    if(self.metalView){
        self.metalView.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:self.metalView];
        [NSLayoutConstraint activateConstraints:@[
            [self.metalView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [self.metalView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
            [self.metalView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [self.metalView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]]];
    }
    // Game renders edge-to-edge. Touch/menu overlays alone honor safe areas.
    UILayoutGuide *safe=self.view.safeAreaLayoutGuide;
    for(UIStackView *rail in @[_leftRail,_rightRail]){
        rail.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:rail];
        [NSLayoutConstraint activateConstraints:@[
            [rail.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
            [rail.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor constant:-8]]];
    }
    [_leftRail.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:8].active=YES;
    [_rightRail.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-8].active=YES;
    NSNotificationCenter *nc=NSNotificationCenter.defaultCenter;
    [nc addObserver:self selector:@selector(controllerChanged:) name:GCControllerDidConnectNotification object:nil];
    [nc addObserver:self selector:@selector(controllerChanged:) name:GCControllerDidDisconnectNotification object:nil];
    [nc addObserver:self selector:@selector(interruption:) name:AVAudioSessionInterruptionNotification object:nil];
    [nc addObserver:self selector:@selector(audioConfiguration:) name:AVAudioEngineConfigurationChangeNotification object:nil];
    [nc addObserver:self selector:@selector(inactive:) name:UIApplicationWillResignActiveNotification object:nil];
    [self controllerChanged:nil];
    if([NSProcessInfo.processInfo.environment[@"PORT_RENDER_SMOKE"] isEqual:@"1"]) {
        // Exercise presentation policy only; this does not emulate a real controller.
        [self setTouchControlsConnected:NO];
        BOOL before=[self touchControlsHidden:NO];
        _touch.throttle=1;_leftHeld=YES;[sessionOwner setTouch:_touch];
        [self setTouchControlsConnected:YES];
        BOOL hidden=[self touchControlsHidden:YES]&&_touch.throttle==0&&!_leftHeld;
        [self setTouchControlsConnected:NO];
        _smokePolicyValid=before&&hidden&&[self touchControlsHidden:NO];
        [self setTouchControlsConnected:_controller!=nil];
    }
}
- (BOOL)prefersStatusBarHidden { return YES; }
- (BOOL)prefersHomeIndicatorAutoHidden { return YES; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskLandscape; }
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if(!self.metalView || !self.view.window)return;
    // Use the actual screen scale, including on the 2868 x 1320 Pro Max panel.
    CGFloat scale=self.view.window.screen.nativeScale;
    self.metalView.contentScaleFactor=scale;
    CGSize size=self.metalView.bounds.size;
    self.metalView.drawableSize=CGSizeMake(round(size.width*scale),round(size.height*scale));
    if(![NSProcessInfo.processInfo.environment[@"PORT_RENDER_SMOKE"] isEqual:@"1"])return;
    CGRect canvas=[self.metalView convertRect:self.metalView.bounds toView:self.view];
    CGRect left=[_leftRail convertRect:_leftRail.bounds toView:self.view];
    CGRect right=[_rightRail convertRect:_rightRail.bounds toView:self.view];
    CGRect safe=CGRectInset(self.view.safeAreaLayoutGuide.layoutFrame,-0.5,-0.5);
    BOOL valid=CGRectEqualToRect(canvas,self.view.bounds)&&CGRectContainsRect(safe,left)&&CGRectContainsRect(safe,right);
    CGFloat w=canvas.size.width,h=canvas.size.height;
    NSDictionary *report=@{@"valid":@(valid),@"controllerPolicy":@(_smokePolicyValid),@"bounds":@[@(self.view.bounds.size.width),@(self.view.bounds.size.height)],
        @"viewport":@[@(canvas.origin.x+(canvas.size.width-w)/2),@(canvas.origin.y+(canvas.size.height-h)/2),@(w),@(h)],
        @"drawable":@[@(self.metalView.drawableSize.width),@(self.metalView.drawableSize.height)],@"scale":@(scale),@"projectionWidth":@(port_wide_window(496,w,h))};
    NSURL *dir=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSData *json=[NSJSONSerialization dataWithJSONObject:report options:0 error:nil];
    [json writeToURL:[dir URLByAppendingPathComponent:@"port-layout-smoke.json"] atomically:YES];
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
- (BOOL)touchControlsHidden:(BOOL)hidden {
    for(UIView *control in _touchControls)if(control.hidden!=hidden)return NO;
    return YES;
}
- (void)setTouchControlsConnected:(BOOL)connected {
    // Clear pressed touch buttons before hiding or restoring the overlay.
    memset(&_touch,0,sizeof(_touch));_leftHeld=_rightHeld=NO;
    [sessionOwner setTouch:_touch];
    for(UIView *control in _touchControls)control.hidden=connected;
}
- (void)controllerChanged:(NSNotification *)note {
    if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{[self controllerChanged:nil];});return;}
    _controller.extendedGamepad.valueChangedHandler=nil;
    _controller.extendedGamepad.leftShoulder.pressedChangedHandler=nil;
    _controller.extendedGamepad.rightShoulder.pressedChangedHandler=nil;
    _controller=nil;memset(&_pad,0,sizeof(_pad));[sessionOwner setPad:_pad];
    for(GCController *c in GCController.controllers)if(c.extendedGamepad){_controller=c;break;}
    [self setTouchControlsConnected:_controller!=nil];
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
