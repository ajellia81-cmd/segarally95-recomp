#import "PortROMPreparation.h"
#include "port_rom_import.h"
static NSURL *failure(NSError **error,NSString *message){
    if(error)*error=[NSError errorWithDomain:@"ROMPreparation" code:1 userInfo:@{NSLocalizedDescriptionKey:message}];return nil;
}
NSURL *PortPrepareROMs(NSURL *input,NSURL *support,NSError **error){
    NSFileManager *fm=NSFileManager.defaultManager;
    NSURL *archive=nil;
    for(NSURL *dir in @[input,input.URLByDeletingLastPathComponent]){
        NSArray<NSURL *> *files=[fm contentsOfDirectoryAtURL:dir includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];
        files=[files sortedArrayUsingComparator:^NSComparisonResult(NSURL *a,NSURL *b){return [a.lastPathComponent compare:b.lastPathComponent];}];
        for(NSURL *file in files)if([file.pathExtension.lowercaseString isEqual:@"zip"]&&[file.lastPathComponent.lowercaseString hasPrefix:@"srallyc"]){archive=file;break;}
        if(archive)break;
    }
    if(!archive){
        for(NSArray *item in @[@[@"maincpu_deinterleaved.bin",@(0x100000)],@[@"main_data_deinterleaved.bin",@(0xc00000)]]){
            NSDictionary *attr=[fm attributesOfItemAtPath:[input URLByAppendingPathComponent:item[0]].path error:nil];
            if(![attr[NSFileType] isEqual:NSFileTypeRegular]||[attr fileSize]!=[item[1] unsignedLongLongValue])
                return failure(error,@"파일 앱의 Sega Rally Championship/ROMs 폴더에 srallyc.zip을 넣고 시작하세요.");
        }
        // Legacy manually prepared B files remain accepted.
        return input;
    }
    NSURL *stage=[support URLByAppendingPathComponent:[@"Prepared-" stringByAppendingString:NSUUID.UUID.UUIDString] isDirectory:YES];
    if(![fm createDirectoryAtURL:stage withIntermediateDirectories:YES attributes:nil error:error])return nil;
    if(![stage setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:error]){[fm removeItemAtURL:stage error:nil];return nil;}
    char message[512]={0};
    if(port_rom_import_game_zip(archive.fileSystemRepresentation,stage.fileSystemRepresentation,message,sizeof(message))){
        [fm removeItemAtURL:stage error:nil];
        return failure(error,[@"ZIP 준비 실패: " stringByAppendingString:[NSString stringWithUTF8String:message]?:@"알 수 없는 오류"]);
    }
    // Activate only complete preparations, retaining any previous data on failure.
    for(NSURL *old in [fm contentsOfDirectoryAtURL:support includingPropertiesForKeys:nil options:0 error:nil])
        if([old.lastPathComponent hasPrefix:@"Prepared-"]&&![old isEqual:stage])[fm removeItemAtURL:old error:nil];
    return stage;
}
