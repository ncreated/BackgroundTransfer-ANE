//
//  BackgroundTransferAPI.m
//  NSSessionPrototype
//
//  Created by Maciek Grzybowski on 10.05.2014.
//

#import "BGT_NSRULSessionController.h"
#import "NSObject+AssociatedObject.h"
#import <objc/runtime.h>

// TypeEncodingDummyClass definition is used to get correct type encoding definition for Obj-C runtime method swizzling
@interface TypeEncodingDummyClass : NSObject
-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;
@end

@implementation TypeEncodingDummyClass
-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {}
@end

// Background tasks completion handler passed to AppDelegate object by iOS.
typedef void (^CompletionHandler)();

@interface BGT_NSRULSessionController() <NSURLSessionDownloadDelegate>

@end

@implementation BGT_NSRULSessionController {
    NSMutableDictionary *_sessions;                             // sessionID -> NSURLSession map
    NSMutableDictionary *_taskConfigurationsByID;               // actionscriptTaskID -> BGT_DownloadTaskConfiguration map
    NSMutableDictionary *_taskConfigurationsBySessionTask;      // NSURLSessionDownloadTask -> BGT_DownloadTaskConfiguration map
}

-(id)init {
    if (self = [super init]) {
        // setup application delegate
        [self configureApplicationBackgroundURLSessionHandler];
        
        // init
        _sessions = [NSMutableDictionary dictionary];
        _taskConfigurationsByID = [NSMutableDictionary dictionary];
        _taskConfigurationsBySessionTask = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark -
#pragma mark Actionscript -> Objective-C API

-(void)initializeSession:(NSString *)sessionID {
    NSURLSession *session = [self getBackgroundSessionInstance:sessionID];
    
    // Check if there are pending tasks for this session
    // - there will be some if scheduled before app went into background and they didn't finish yet.
    [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        NSMutableArray *runningTasks = [NSMutableArray array];
        
        for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            NSString *dtRemoteURL = downloadTask.originalRequest.URL.absoluteString;
        
            // Restore configuration for this pending download
            BGT_DownloadTaskConfiguration *configuration = [BGT_DownloadTaskConfiguration loadFromDefaultsWithRemoteURL:dtRemoteURL];
            if (configuration) {
                configuration.sessionTask = downloadTask;// associate configuration with pending download task
                _taskConfigurationsByID[configuration.actionscriptTaskID] = configuration;
                _taskConfigurationsBySessionTask[configuration.sessionTask] = configuration;
                [runningTasks addObject:configuration];
                
                NSLog(@"Configuration restored: %@", configuration.actionscriptTaskID);
            }
            else {
                // This shouldn't happen but if for some reason configuration wasn't persisted cancel this task and forget about it
                [downloadTask cancel];
                
                NSLog(@"Download task without configuration cancelled: %@", configuration.actionscriptTaskID);
            }
        }
        
        [self dispatchSessionInitialized:sessionID withRunningTasks:runningTasks];
    }];
}

-(void)createDownloadTask:(BGT_DownloadTaskConfiguration*)configuration {
    if (!_taskConfigurationsByID[configuration.actionscriptTaskID]) {// if there's no configuration for this download
        NSURLSession *session = [self getBackgroundSessionInstance:configuration.sessionID];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:configuration.remoteURL]];
        configuration.sessionTask = [session downloadTaskWithRequest:request];
        [configuration saveToDefaults];
    
        _taskConfigurationsByID[configuration.actionscriptTaskID] = configuration;
        _taskConfigurationsBySessionTask[configuration.sessionTask] = configuration;
    }
}

-(void)resumeDownloadTask:(NSString*)taskID {
    [[self configurationWithTaskID:taskID].sessionTask resume];
}

-(void)suspendDownloadTask:(NSString*)taskID {
    [[self configurationWithTaskID:taskID].sessionTask suspend];
}

-(void)cancelDownloadTask:(NSString*)taskID {
    BGT_DownloadTaskConfiguration *configuration = [self configurationWithTaskID:taskID];
    [configuration.sessionTask cancel];
}

-(BGT_DownloadTaskConfiguration *)configurationForTask:(NSString *)taskID {
    if (_taskConfigurationsByID || [_taskConfigurationsByID count] > 0) {
        return _taskConfigurationsByID[taskID];
    }
    return nil;
}

#pragma mark -
#pragma mark Objective-C -> Actionscript API

-(void)dispatchTotalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite forTask:(BGT_DownloadTaskConfiguration*)configuration {
    //NSLog(@"progress %.1f: %@", progress, configuration.taskID);
    dispatch_async(dispatch_get_main_queue(), ^{
#if USE_OBJC_DELEGATE
        if (_delegate) {
            [_delegate task:configuration.actionscriptTaskID didUpdateTotalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }
#endif
    });
}

-(void)dispatchDownloadFinishForTask:(BGT_DownloadTaskConfiguration*)configuration {
    //NSLog(@"download finished: %@", configuration.taskID);
    dispatch_async(dispatch_get_main_queue(), ^{
#if USE_OBJC_DELEGATE
        if (_delegate) {
            [_delegate taskDidFinishDownload:configuration.actionscriptTaskID];
        }
#endif
    });
}

-(void)dispatchError:(NSError*)error forTask:(BGT_DownloadTaskConfiguration*)configuration {
    //NSLog(@"download error: %@", configuration.taskID);
    dispatch_async(dispatch_get_main_queue(), ^{
#if USE_OBJC_DELEGATE
        if (_delegate) {
            [_delegate task:configuration.actionscriptTaskID didFailDownloadWithErrorMessage:[error localizedDescription]];
        }
#endif
    });
}

-(void)dispatchSessionInitialized:(NSString*)sessionID withRunningTasks:(NSArray*)runningTasks {
    dispatch_async(dispatch_get_main_queue(), ^{
#if USE_OBJC_DELEGATE
        if (_delegate) {
            [_delegate sessionDidInitialize:sessionID withRunningTasks:runningTasks];
        }
#endif
    });
}

#pragma mark -
#pragma mark Downloads handling

-(NSURLSession*)getBackgroundSessionInstance:(NSString*)sessionID {
    if (_sessions[sessionID]) {
        return _sessions[sessionID];
    }
    
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionID];
        session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    });
    
    _sessions[sessionID] = session;
    return session;
}

-(BGT_DownloadTaskConfiguration*)configurationWithTaskID:(NSString*)taskID {
    return _taskConfigurationsByID[taskID] ? : nil;
}

-(BGT_DownloadTaskConfiguration*)configurationForDownloadTask:(NSURLSessionDownloadTask*)task {
    return _taskConfigurationsBySessionTask[task] ? : nil;
}

// Moves downloaded file from iOS temp location to target location.
-(void)moveDownloadToPersistentLocation:(BGT_DownloadTaskConfiguration*)task fromTemporaryLocation:(NSURL*)location {
    NSURL *destinationURL = [NSURL fileURLWithPath:task.localPath];
    
    NSError *mkDirError = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:[task.localPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&mkDirError];
    
    if (mkDirError) {
        NSLog(@"[BackgroundTransfer] Error when creating directory: %@", mkDirError.localizedDescription);
    }

    NSError *cpError = nil;
    [[NSFileManager defaultManager] copyItemAtURL:location toURL:destinationURL error:&cpError];
    
    if (cpError) {
        NSLog(@"[BackgroundTransfer] Error when copying item at url: %@ to url: %@, description: %@", location, destinationURL, cpError.localizedDescription);
    }
}

#pragma mark -
#pragma mark NSURLSessionDelegate

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    BGT_DownloadTaskConfiguration *configuration = [self configurationForDownloadTask:downloadTask];
    if (configuration) {
        [self dispatchTotalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite forTask:configuration];
    }
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    BGT_DownloadTaskConfiguration *configuration = [self configurationForDownloadTask:downloadTask];
    if (configuration) {
        [self moveDownloadToPersistentLocation:configuration fromTemporaryLocation:location];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    BGT_DownloadTaskConfiguration *configuration = [self configurationForDownloadTask:(NSURLSessionDownloadTask*)task];
    if (configuration) {
        if (error) {
            [self dispatchError:error forTask:configuration];
        }
        else {
            [self dispatchDownloadFinishForTask:configuration];
        }
        
        // Dispose download task configuration
        [configuration deleteFromDefaults];
        [_taskConfigurationsByID removeObjectForKey:configuration.actionscriptTaskID];
        [_taskConfigurationsBySessionTask removeObjectForKey:configuration.sessionTask];
    }
}

-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSObject *appDelegate = [UIApplication sharedApplication].delegate;
    NSMutableDictionary *completionCallbacks = appDelegate.associatedObject;
    
    if (completionCallbacks) {
        CompletionHandler completionHandler = completionCallbacks[session.configuration.identifier];
        completionHandler();
        [completionCallbacks removeObjectForKey:session.configuration.identifier];
        [appDelegate setAssociatedObject:completionCallbacks];
    }
}

#pragma mark -
#pragma Adobe AIR tweaks

static void Swizzled_AppDelegateBackgroundURLSessionHandler(id self, SEL _cmd, UIApplication* application, NSString* identifier, CompletionHandler completionHandler) {
    // Call original implementation
    SEL aSelector = NSSelectorFromString(@"swizzled_application:handleEventsForBackgroundURLSession:completionHandler:");
    if ([self respondsToSelector:aSelector]) {
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:aSelector]];
        [inv setSelector:aSelector];
        [inv setTarget:self];
        
        [inv setArgument:&(application) atIndex:2];
        [inv setArgument:&(identifier) atIndex:3];
        [inv setArgument:&(completionHandler) atIndex:4];
        
        [inv invoke];
    }
    
    // Store completion handler to be called when all download work is finished
    NSMutableDictionary *completionCallbacks = [self associatedObject] ? : [NSMutableDictionary dictionary];
    completionCallbacks[identifier] = completionHandler;
    [self setAssociatedObject:completionCallbacks];
}

-(void)configureApplicationBackgroundURLSessionHandler {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIApplication *application = [UIApplication sharedApplication];
        Class class = object_getClass(application.delegate);
        
        // Get correct type encoding for custom method
        Method twinMethod = class_getInstanceMethod([TypeEncodingDummyClass class], @selector(application:handleEventsForBackgroundURLSession:completionHandler:));
        const char *typeEncoding = method_getTypeEncoding(twinMethod);
        
        SEL originalSelector = @selector(application:handleEventsForBackgroundURLSession:completionHandler:);
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        
        if (originalMethod) {
            // Original method is already implemented by Adobe AIR (and points to original implementation in runtime dispatch table).
            // Create custom method with different selector and swizzle implementations:
            SEL customSelector = NSSelectorFromString(@"swizzled_application:handleEventsForBackgroundURLSession:completionHandler:");
            
            // 1. Add custom implementation in separate method.
            class_addMethod(class, customSelector, (IMP)Swizzled_AppDelegateBackgroundURLSessionHandler, typeEncoding);
            
            // 2. Swizzle both methods.
            method_exchangeImplementations(originalMethod, class_getInstanceMethod(class, customSelector));
        }
        else {
            // Original method is not implemented by Adobe AIR.
            // Create it and point to custom implementation.
            class_addMethod(class, originalSelector, (IMP)Swizzled_AppDelegateBackgroundURLSessionHandler, typeEncoding);
        }
    });
}

@end
