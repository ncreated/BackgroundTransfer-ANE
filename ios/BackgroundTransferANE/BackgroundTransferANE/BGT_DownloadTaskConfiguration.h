//
//  BGT_DownloadTaskConfiguration.h
//  NSSessionPrototype
//
//  Created by Maciek Grzybowski on 10.05.2014.
//

extern NSString * const kBGT_DefaultSessionIdentifier;
extern NSString * const kBGT_TasksUserDefaultsKey;

@interface BGT_DownloadTaskConfiguration : NSObject

@property (readonly, nonatomic) NSString *sessionID;
@property (readonly, nonatomic) NSString *actionscriptTaskID;
@property (readonly, nonatomic) NSString *remoteURL;
@property (readonly, nonatomic) NSString *localPath;

/**
 * Reference to NSURLSessionDownloadTask associated with this configuration.
 * Its weak as NSURLSession manages strong reference to it.
 */
@property (weak, nonatomic) NSURLSessionDownloadTask *sessionTask;


-(instancetype)initWithSessionID:(NSString*)sessionID remoteURL:(NSString*)remoteURL localPath:(NSString*)localPath;


// Persistence management

+(instancetype)loadFromDefaultsWithRemoteURL:(NSString*)remoteURL;
-(void)saveToDefaults;
-(void)deleteFromDefaults;

@end
