#import <AVFoundation/AVFoundation.h>
@interface PortAudio : NSObject
- (BOOL)start:(NSError **)error;
- (void)stop;
@end
