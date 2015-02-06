//
//  BackgroundTransferANE.m
//  BackgroundTransferANE
//
//  Created by Maciek Grzybowski on 08.05.2014.
//

#import "FlashRuntimeExtensions.h"
#import "BGT_InternalMessages.h"
#import "BGT_NSRULSessionController.h"
#import "NSString+ANE.h"

#define MAP_FUNCTION(fn, data) { (const uint8_t*)(#fn), (data), &(fn) }

@class SessionDelegate;

BGT_NSRULSessionController *_sessionController;
SessionDelegate *_sessionDelegate;

#pragma mark -
#pragma mark Actionscript -> ANE

void displayDebugAlert(NSString *title, NSString *message) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

FREObject BGT_initializeSession(FREContext context, void* functionData, uint32_t argc, FREObject argv[]) {
    uint32_t length = 0;
    const uint8_t *sessionIDParam = NULL;
    
    if (FREGetObjectAsUTF8(argv[0], &length, &sessionIDParam) == FRE_OK) {
        NSString *sessionID = [NSString stringWithUTF8String:(char*)sessionIDParam];
        [_sessionController initializeSession:sessionID];
    }
    
    return NULL;
}

FREObject BGT_createDownloadTask(FREContext context, void* functionData, uint32_t argc, FREObject argv[]) {
    uint32_t length = 0;
    const uint8_t *sessionIDParam = NULL;
    const uint8_t *remoteURLParam = NULL;
    const uint8_t *localPathParam = NULL;
    
    NSString *sessionID;
    NSString *remoteURL;
    NSString *localPath;
    
    if (FREGetObjectAsUTF8(argv[0], &length, &sessionIDParam) == FRE_OK) {
        sessionID = [NSString stringWithUTF8String:(char*)sessionIDParam];
    }
    
    if (FREGetObjectAsUTF8(argv[1], &length, &remoteURLParam) == FRE_OK) {
        remoteURL = [NSString stringWithUTF8String:(char*)remoteURLParam];
    }
    
    if (FREGetObjectAsUTF8(argv[2], &length, &localPathParam) == FRE_OK) {
        localPath = [NSString stringWithUTF8String:(char*)localPathParam];
    }
    
    BGT_DownloadTaskConfiguration *configuration = [[BGT_DownloadTaskConfiguration alloc] initWithSessionID:sessionID remoteURL:remoteURL localPath:localPath];
    [_sessionController createDownloadTask:configuration];
    
    return NULL;
}

FREObject BGT_resumeDownloadTask(FREContext context, void* functionData, uint32_t argc, FREObject argv[]) {
    uint32_t length = 0;
    const uint8_t *taskIDParam = NULL;
    
    if (FREGetObjectAsUTF8(argv[0], &length, &taskIDParam) == FRE_OK) {
        NSString *taskID = [NSString stringWithUTF8String:(char*)taskIDParam];
        [_sessionController resumeDownloadTask:taskID];
    }
    
    return NULL;
}

FREObject BGT_suspendDownloadTask(FREContext context, void* functionData, uint32_t argc, FREObject argv[]) {
    uint32_t length = 0;
    const uint8_t *taskIDParam = NULL;
    
    if (FREGetObjectAsUTF8(argv[0], &length, &taskIDParam) == FRE_OK) {
        NSString *taskID = [NSString stringWithUTF8String:(char*)taskIDParam];
        [_sessionController suspendDownloadTask:taskID];
    }
    
    return NULL;
}

FREObject BGT_cancelDownloadTask(FREContext context, void* functionData, uint32_t argc, FREObject argv[]) {
    uint32_t length = 0;
    const uint8_t *taskIDParam = NULL;
    
    if (FREGetObjectAsUTF8(argv[0], &length, &taskIDParam) == FRE_OK) {
        NSString *taskID = [NSString stringWithUTF8String:(char*)taskIDParam];
        [_sessionController cancelDownloadTask:taskID];
    }
    
    return NULL;
}

/**
 *  Array is used to pass properties to Actionscript instead of creating and filling BTDownloadTask object.
 *  In order to fill BTDownloadTask properties I would need to make them public. However, I wanted to keep
 *  those properties private (and readonly) to prevent extension users from modyfying BTDownloadTask object.
 */
FREObject BGT_getDownloadTaskPropertiesArray(FREContext context, void* functionData, uint32_t argc, FREObject argv[]) {
    uint32_t length = 0;
    const uint8_t *taskIDParam = NULL;
    
    if (FREGetObjectAsUTF8(argv[0], &length, &taskIDParam) == FRE_OK) {
        NSString *taskID = [NSString stringWithUTF8String:(char*)taskIDParam];
        BGT_DownloadTaskConfiguration *configuration = [_sessionController configurationForTask:taskID];

        if (configuration) {
            // Build array containing task properties
            FREObject properties = NULL;
            FRENewObject([@"Array" ANEString], 0, NULL, &properties, nil);
            FRESetArrayLength(properties, 3);
            
            FREObject sessionID;
            FRENewObjectFromUTF8((uint32_t)configuration.sessionID.length, [configuration.sessionID ANEString], &sessionID);
            FRESetArrayElementAt(properties, 0, sessionID);
            
            FREObject remoteURL;
            FRENewObjectFromUTF8((uint32_t)configuration.remoteURL.length, [configuration.remoteURL ANEString], &remoteURL);
            FRESetArrayElementAt(properties, 1, remoteURL);
            
            FREObject localPath;
            FRENewObjectFromUTF8((uint32_t)configuration.localPath.length, [configuration.localPath ANEString], &localPath);
            FRESetArrayElementAt(properties, 2, localPath);
        
            return properties;
        }
    }
    
    return NULL;
}

FREObject BGT___crashTheApp(FREContext context, void* functionData, uint32_t argc, FREObject argv[]) {
    NSLog(@"%@", @[][10]);
    return NULL;
}

#pragma mark -
#pragma mark ANE -> Actionscript

@interface SessionDelegate : NSObject <BGT_NSURLSessionControllerObjectiveCDelegate>
@property (assign, nonatomic) FREContext extensionContext;
@end

@implementation SessionDelegate

-(void)sessionDidInitialize:(NSString*)sessionID withRunningTasks:(NSArray*)runningTasks {
    NSString *data = sessionID;// data = <session id> <running task 1 url> ... <running task N url>
    for (BGT_DownloadTaskConfiguration *configuration in runningTasks) {
        NSString *escapedTaskID = [configuration.actionscriptTaskID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];// escape spaces
        data = [data stringByAppendingString:[NSString stringWithFormat:@" %@", escapedTaskID]];
    }

    FREDispatchStatusEventAsync(_extensionContext, [data ANEString], [kSessionInitialized ANEString]);
}

-(void)task:(NSString *)taskID didUpdateTotalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSString *escapedTaskID = [taskID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];// escape spaces
    NSString *data = [NSString stringWithFormat:@"%@ %lld %lld", escapedTaskID, totalBytesWritten, totalBytesExpectedToWrite];// data = <task id> <int for bytes written> <int for total bytes>
    FREDispatchStatusEventAsync(_extensionContext, [data ANEString], [kDownloadTaskProgress ANEString]);
}

-(void)taskDidFinishDownload:(NSString*)taskID {
    NSString *escapedTasID = [taskID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];// escape spaces
    FREDispatchStatusEventAsync(_extensionContext, [escapedTasID ANEString], [kDownloadTaskCompleted ANEString]);
}

-(void)task:(NSString*)taskID didFailDownloadWithErrorMessage:(NSString*)errorMessage {
    NSString *escapedTaskID = [taskID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];// escape spaces
    NSString *data = [NSString stringWithFormat:@"%@ %@", escapedTaskID, errorMessage];// data = <task id> <error message string>
    FREDispatchStatusEventAsync(_extensionContext, [data ANEString], [kDownloadTaskError ANEString]);
}

@end

#pragma mark -
#pragma mark ANE lifecycle

static

void CLBackgroundTransferANEContextInitializer(void *extData, const uint8_t *ctxType, FREContext ctx, uint32_t *numFunctionsToSet, const FRENamedFunction **functionsToSet) {
    
    static FRENamedFunction functionMap[] = {
        MAP_FUNCTION(BGT_initializeSession, NULL),
        MAP_FUNCTION(BGT_createDownloadTask, NULL),
        MAP_FUNCTION(BGT_resumeDownloadTask, NULL),
        MAP_FUNCTION(BGT_suspendDownloadTask, NULL),
        MAP_FUNCTION(BGT_cancelDownloadTask, NULL),
        MAP_FUNCTION(BGT_getDownloadTaskPropertiesArray, NULL),
        MAP_FUNCTION(BGT___crashTheApp, NULL)
    };
    
	*numFunctionsToSet = sizeof(functionMap) / sizeof(FRENamedFunction);
	*functionsToSet = functionMap;
    
    _sessionController = [BGT_NSRULSessionController new];
    _sessionDelegate = [SessionDelegate new];
    _sessionController.delegate = _sessionDelegate;
    _sessionDelegate.extensionContext = ctx;
}

void CLBackgroundTransferANEContextFinalizer(FREContext ctx) {
	return;
}

void CLBackgroundTransferANEFinalizer(void* extData) {
	return;
}

void CLBackgroundTransferANEInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet) {

	*extDataToSet = NULL;
	*ctxInitializerToSet = &CLBackgroundTransferANEContextInitializer;
	*ctxFinalizerToSet = &CLBackgroundTransferANEContextFinalizer;
}