#import <Foundation/Foundation.h>
#import "PortPreparedCleanup.h"
#include <stdlib.h>
static void require(BOOL ok,NSString *message) {
    if(!ok){NSLog(@"FAIL: %@",message);exit(1);}
}
int main(void) {
    @autoreleasepool {
        NSFileManager *fm=NSFileManager.defaultManager;
        NSURL *support=[[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES]
            URLByAppendingPathComponent:NSUUID.UUID.UUIDString isDirectory:YES];
        NSURL *active=[support URLByAppendingPathComponent:@"Prepared-current" isDirectory:YES];
        NSURL *old=[support URLByAppendingPathComponent:@"Prepared-previous" isDirectory:YES];
        NSURL *unrelated=[support URLByAppendingPathComponent:@"UserFiles" isDirectory:YES];
        for(NSURL *dir in @[active,old,unrelated])
            require([fm createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil],@"fixture directory");
        NSData *bytes=[@"synthetic fixture, no game data" dataUsingEncoding:NSUTF8StringEncoding];
        NSURL *bin=[active URLByAppendingPathComponent:@"maincpu_deinterleaved.bin"];
        require([bytes writeToURL:bin atomically:YES],@"fixture BIN");
        BOOL legacyWouldDelete=NO;
        for(NSURL *entry in [fm contentsOfDirectoryAtURL:support includingPropertiesForKeys:nil options:0 error:nil])
            if([entry.lastPathComponent isEqualToString:active.lastPathComponent])legacyWouldDelete=![entry isEqual:active];
        NSLog(@"Legacy NSURL equality would delete active directory: %@",legacyWouldDelete?@"YES":@"NO");
        PortCleanupPreparedDirectories(fm,support,active);
        require([fm fileExistsAtPath:active.path],@"active directory must survive enumeration URL mismatch");
        require([[NSData dataWithContentsOfURL:bin] isEqualToData:bytes],@"active BIN must survive cleanup");
        require(![fm fileExistsAtPath:old.path],@"old cache must be removed");
        require([fm fileExistsAtPath:unrelated.path],@"unrelated data must survive");
        NSURL *withoutSlash=[NSURL fileURLWithPath:active.path isDirectory:NO];
        PortCleanupPreparedDirectories(fm,support,withoutSlash);
        require([[NSData dataWithContentsOfURL:bin] isEqualToData:bytes],@"same path without directory URL slash must survive");
        require([fm removeItemAtURL:support error:nil],@"fixture cleanup");
        NSLog(@"Prepared directory retention regression passed (Foundation; synthetic data only)");
    }
    return 0;
}
