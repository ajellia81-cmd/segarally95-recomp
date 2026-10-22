#import "PortAudio.h"
#include "model2_snd.h"
@implementation PortAudio {
    AVAudioEngine *_engine;
    AVAudioSourceNode *_source;
}
- (BOOL)start:(NSError **)error {
    NSAssert(NSThread.isMainThread,@"Audio engine lifecycle belongs to main thread");
    if(_engine.isRunning)return YES;
    AVAudioSession *session=AVAudioSession.sharedInstance;
    if(![session setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:0 error:error] ||
       ![session setActive:YES error:error])return NO;
    if(!_engine) {
        _engine=[AVAudioEngine new];
        AVAudioFormat *format=[[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:44100 channels:2 interleaved:NO];
        _source=[[AVAudioSourceNode alloc] initWithFormat:format renderBlock:^OSStatus(BOOL *silence,const AudioTimeStamp *timestamp,AVAudioFrameCount count,AudioBufferList *output) {
            (void)timestamp;
            if(output->mNumberBuffers!=2)return -50;
            for(unsigned ch=0;ch<2;ch++) if(!output->mBuffers[ch].mData || output->mBuffers[ch].mDataByteSize<count*sizeof(float))return -50;
            int16_t samples[512*2]; BOOL allSilent=YES;
            for(unsigned offset=0;offset<count;) {
                unsigned n=MIN(512u,count-offset);
                model2_snd_render_nonblocking(samples,n);
                for(unsigned i=0;i<n;i++)for(unsigned ch=0;ch<2;ch++) {
                    int16_t s=samples[i*2+ch]; if(s)allSilent=NO;
                    ((float *)output->mBuffers[ch].mData)[offset+i]=s/32768.f;
                }
                offset+=n;
            }
            *silence=allSilent; return noErr;
        }];
        [_engine attachNode:_source];
        [_engine connect:_source to:_engine.mainMixerNode format:format];
    }
    [_engine prepare];
    return [_engine startAndReturnError:error];
}
- (void)stop {
    NSAssert(NSThread.isMainThread,@"Audio engine lifecycle belongs to main thread");
    [_engine stop];
    [AVAudioSession.sharedInstance setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}
@end
