#import <Foundation/Foundation.h>

/* Directory enumeration and an explicitly constructed directory URL can differ
 * in their trailing slash/resource metadata. Identity here is the generated
 * basename within this one parent directory, never NSURL object equality. */
static inline void PortCleanupPreparedDirectories(NSFileManager *fm, NSURL *support, NSURL *active)
{
    NSString *keep=active.lastPathComponent;
    if(![keep hasPrefix:@"Prepared-"])return;
    for(NSURL *old in [fm contentsOfDirectoryAtURL:support includingPropertiesForKeys:nil options:0 error:nil]) {
        NSString *name=old.lastPathComponent;
        if([name hasPrefix:@"Prepared-"]&&![name isEqualToString:keep])
            [fm removeItemAtURL:old error:nil];
    }
}
