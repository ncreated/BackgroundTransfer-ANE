//
//  BackgroundTransferAPI.h
//  NSSessionPrototype
//
//  Performs background transfers with NSURLSession API.
//
//  Created by Maciek Grzybowski on 10.05.2014.
//

#import "BGT_DownloadTaskConfiguration.h"
#import "FlashRuntimeExtensions.h"

#define USE_OBJC_DELEGATE 1

// Helper delegate to test BGT_NSRULSessionController in native iOS project.
@protocol BGT_NSURLSessionControllerObjectiveCDelegate <NSObject>
#if USE_OBJC_DELEGATE
-(void)sessionDidInitialize:(NSString*)sessionID withRunningTasks:(NSArray*)runningTasks;
-(void)task:(NSString*)taskID didUpdateTotalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
-(void)taskDidFinishDownload:(NSString*)taskID;
-(void)task:(NSString*)taskID didFailDownloadWithErrorMessage:(NSString*)errorMessage;
#endif
@end

@interface BGT_NSRULSessionController : NSObject

#if USE_OBJC_DELEGATE
@property (weak, nonatomic) id<BGT_NSURLSessionControllerObjectiveCDelegate>delegate;
#endif

@property (assign, nonatomic) FREContext *extensionContext;

-(void)initializeSession:(NSString*)sessionID;
-(void)createDownloadTask:(BGT_DownloadTaskConfiguration*)configuration;
-(void)resumeDownloadTask:(NSString*)taskID;
-(void)suspendDownloadTask:(NSString*)taskID;
-(void)cancelDownloadTask:(NSString*)taskID;

-(BGT_DownloadTaskConfiguration*)configurationForTask:(NSString*)taskID;

@end
