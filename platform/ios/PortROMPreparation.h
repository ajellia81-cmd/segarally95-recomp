#import <Foundation/Foundation.h>
/* Worker-thread only. Uses a fresh private directory; never changes the ZIP. */
NSURL *PortPrepareROMs(NSURL *input,NSURL *support,NSError **error);
