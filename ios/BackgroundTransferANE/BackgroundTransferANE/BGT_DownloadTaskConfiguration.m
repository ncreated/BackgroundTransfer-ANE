//
//  BGT_DownloadTaskConfiguration.m
//  NSSessionPrototype
//
//  Created by Maciek Grzybowski on 10.05.2014.
//

#import "BGT_DownloadTaskConfiguration.h"

NSString * const kBGT_DefaultSessionIdentifier = @"com.ncreated.BackgroundTransferANE.DefaultSession";
NSString * const kBGT_TasksUserDefaultsKey = @"com.ncreated.BackgroundTransferANE.DefaultSession";

@interface BGT_DownloadTaskConfiguration()
@property (strong, nonatomic) NSString *sessionID;
@property (strong, nonatomic) NSString *actionscriptTaskID;
@property (strong, nonatomic) NSString *remoteURL;
@property (strong, nonatomic) NSString *localPath;
@end

@implementation BGT_DownloadTaskConfiguration

-(instancetype)initWithSessionID:(NSString *)sessionID remoteURL:(NSString *)remoteURL localPath:(NSString *)localPath {
    if (self = [super init]) {
        self.sessionID = sessionID;
        self.localPath = localPath;
        self.remoteURL = remoteURL;
        self.actionscriptTaskID = [NSString stringWithFormat:@"%@:%@", sessionID, remoteURL];
    }
    return self;
}

+(instancetype)loadFromDefaultsWithRemoteURL:(NSString *)remoteURL {
    BGT_DownloadTaskConfiguration *me = nil;
    
    NSDictionary *tasks = [[NSUserDefaults standardUserDefaults] objectForKey:kBGT_TasksUserDefaultsKey];
    if (tasks) {
        NSDictionary *task = [tasks objectForKey:remoteURL];
        if (task) {
            me = [[BGT_DownloadTaskConfiguration alloc] initWithSessionID:task[@"sessionID"] remoteURL:task[@"remoteURL"] localPath:task[@"localPath"]];
        }
    }
    
    return me;
}

-(void)saveToDefaults {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kBGT_TasksUserDefaultsKey]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionary] forKey:kBGT_TasksUserDefaultsKey];
    }

    NSMutableDictionary *tasks = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kBGT_TasksUserDefaultsKey]];
    
    tasks[_remoteURL] = @{@"sessionID": _sessionID, @"remoteURL": _remoteURL, @"localPath": _localPath};
    
    [[NSUserDefaults standardUserDefaults] setObject:tasks forKey:kBGT_TasksUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)deleteFromDefaults {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kBGT_TasksUserDefaultsKey]) {
        NSMutableDictionary *tasks = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:kBGT_TasksUserDefaultsKey]];
        [tasks removeObjectForKey:_remoteURL];
        
        [[NSUserDefaults standardUserDefaults] setObject:tasks forKey:kBGT_TasksUserDefaultsKey];
    }
}

@end
