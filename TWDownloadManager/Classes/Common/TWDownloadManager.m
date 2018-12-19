//
//  TWDownloadManager.m
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import "TWDownloadManager.h"
#import "NSURLSession+CorrectedResumeData.h"
#import "TWDataBaseManager.h"
#import "TWDownloadUtil.h"
#import "TWDownloadModel.h"
#import "TWDownloadHUD.h"
 #import <AFNetworking/AFNetworking.h>
#import "TWNetworkReachability.h"

@interface TWDownloadManager ()<NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;             // NSURLSession
@property (nonatomic, strong) NSMutableDictionary *dataTaskDic;  // 同时下载多个文件，需要创建多个NSURLSessionDownloadTask，用该字典来存储
@property (nonatomic, assign) NSInteger currentCount;            // 当前正在下载的个数
@property (nonatomic, assign) NSInteger maxConcurrentCount;      // 最大同时下载数量
@property (nonatomic, assign) BOOL allowsCellularAccess;         // 是否允许蜂窝网络下载

@end

@implementation TWDownloadManager

+ (instancetype)shareManager {
    static TWDownloadManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}

// 一次性设置代码
+ (void)appDownloadConfigOnceCode {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:TWDownloadConfigOnceKey]) {
        // 初始化下载最大并发数为1
        [defaults setInteger:1 forKey:TWDownloadMaxConcurrentCountKey];
        // 初始化不允许蜂窝网络下载
        [defaults setBool:NO forKey:TWDownloadAllowsCellularAccessKey];
        [defaults setBool:YES forKey:TWDownloadConfigOnceKey];
    }
}

- (instancetype)init {
    if (self = [super init]) {
        // 初始化
        _currentCount = 0;
        _maxConcurrentCount = [[NSUserDefaults standardUserDefaults] integerForKey:TWDownloadMaxConcurrentCountKey];
        _allowsCellularAccess = [[NSUserDefaults standardUserDefaults] boolForKey:TWDownloadAllowsCellularAccessKey];
        _dataTaskDic = [NSMutableDictionary dictionary];
        
        // 单线程代理队列
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        
        // 后台下载标识
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"TWDownloadBackgroundSessionIdentifier"];
        // 允许蜂窝网络下载，默认为YES，这里开启，我们添加了一个变量去控制用户切换选择
        configuration.allowsCellularAccess = YES;
        
        // 创建NSURLSession，配置信息、代理、代理线程
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
        
        // 最大下载并发数变更通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadMaxConcurrentCountChange:) name:TWDownloadMaxConcurrentCountChangeNotification object:nil];
        // 是否允许蜂窝网络下载改变通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadAllowsCellularAccessChange:) name:TWDownloadAllowsCellularAccessChangeNotification object:nil];
        // 网路改变通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkingReachabilityDidChange:) name:TWNetworkingReachabilityDidChangeNotification object:nil];
    }
    
    return self;
}

// 加入准备下载任务
- (void)startDownloadTask:(TWDownloadModel *)model {
    // 取出数据库中模型数据，如果不存在，添加到数据空中
    TWDownloadModel *downloadModel = [[TWDataBaseManager shareManager] getModelWithUrl:model.url];
    if (!downloadModel) {
        downloadModel = model;
        [[TWDataBaseManager shareManager] insertModel:downloadModel];
    }
    
    // 更新状态为等待下载
    downloadModel.state = TWDownloadStateWaiting;
    [[TWDataBaseManager shareManager] updateWithModel:downloadModel option:TWDBUpdateOptionState | TWDBUpdateOptionLastStateTime];
    
    // 下载
    if (_currentCount < _maxConcurrentCount && [self networkingAllowsDownloadTask]) [self downloadwithModel:downloadModel];
}

// 开始下载
- (void)downloadwithModel:(TWDownloadModel *)model {
    // 更新状态为开始
    model.state = TWDownloadStateDownloading;
    [[TWDataBaseManager shareManager] updateWithModel:model option:TWDBUpdateOptionState];
    _currentCount++;
    
    // 创建NSURLSessionDownloadTask
    NSURLSessionDownloadTask *downloadTask;
    if (model.resumeData) {
        CGFloat version = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (version >= 10.0 && version < 10.2) {
            downloadTask = [_session downloadTaskWithCorrectResumeData:model.resumeData];
        }else {
            downloadTask = [_session downloadTaskWithResumeData:model.resumeData];
        }
        
    }else {
        downloadTask = [_session downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:model.url]]];
    }
    
    // 添加描述标签
    downloadTask.taskDescription = model.url;
    
    // 更新存储的NSURLSessionDownloadTask对象
    [_dataTaskDic setValue:downloadTask forKey:model.url];
    
    // 启动（继续下载）
    [downloadTask resume];
}

// 暂停下载
- (void)pauseDownloadTask:(TWDownloadModel *)model {
    // 取最新数据
    TWDownloadModel *downloadModel = [[TWDataBaseManager shareManager] getModelWithUrl:model.url];
    
    // 取消任务
    [self cancelTaskWithModel:downloadModel delete:NO];
    
    // 更新数据库状态为暂停
    downloadModel.state = TWDownloadStatePaused;
    [[TWDataBaseManager shareManager] updateWithModel:downloadModel option:TWDBUpdateOptionState];
}

// 删除下载任务及本地缓存
- (void)deleteTaskAndCache:(TWDownloadModel *)model {
    // 如果正在下载，取消任务
    [self cancelTaskWithModel:model delete:YES];
    
    // 删除本地缓存、数据库数据
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:model.localPath error:nil];
        [[TWDataBaseManager shareManager] deleteModelWithUrl:model.url];
    });
}

// 取消任务
- (void)cancelTaskWithModel:(TWDownloadModel *)model delete:(BOOL)delete {
    if (model.state == TWDownloadStateDownloading) {
        // 获取NSURLSessionDownloadTask
        NSURLSessionDownloadTask *downloadTask = [_dataTaskDic valueForKey:model.url];
        
        __weak typeof(self) weakSelf = self;
        // 取消任务
        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            // 更新下载数据
            model.resumeData = resumeData;
            [[TWDataBaseManager shareManager] updateWithModel:model option:TWDBUpdateOptionResumeData];
            
            // 更新当前正在下载的个数
            if (strongSelf.currentCount > 0) {
                strongSelf.currentCount--;
            }
            
            // 开启等待下载任务
            [self startDownloadWaitingTask];
        }];
        
        // 移除字典存储的对象
        if (delete) [_dataTaskDic removeObjectForKey:model.url];
    }
}

// 开启等待下载任务
- (void)startDownloadWaitingTask {
    if (_currentCount < _maxConcurrentCount && [self networkingAllowsDownloadTask]) {
        // 获取下一条等待的数据
        TWDownloadModel *model = [[TWDataBaseManager shareManager] getWaitingModel];
        
        if (model) {
            // 下载
            [self downloadwithModel:model];
            
            // 递归，开启下一个等待任务
            [self startDownloadWaitingTask];
        }
    }
}

// 下载时，杀死进程，更新所有正在下载的任务为等待
- (void)updateDownloadingTaskState {
    NSArray *downloadingData = [[TWDataBaseManager shareManager] getAllDownloadingData];
    for (TWDownloadModel *model in downloadingData) {
        model.state = TWDownloadStateWaiting;
        [[TWDataBaseManager shareManager] updateWithModel:model option:TWDBUpdateOptionState];
    }
}

// 重启时开启等待下载的任务
- (void)openDownloadTask {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startDownloadWaitingTask];
    });
}

// 停止正在下载任务为等待状态
- (void)pauseDownloadingTaskWithAll:(BOOL)all {
    // 获取正在下载的数据
    NSArray *downloadingData = [[TWDataBaseManager shareManager] getAllDownloadingData];
    NSInteger count = all ? downloadingData.count : downloadingData.count - _maxConcurrentCount;
    for (NSInteger i = 0; i < count; i++) {
        // 取消任务
        TWDownloadModel *model = downloadingData[i];
        [self cancelTaskWithModel:model delete:NO];
        
        // 更新状态为等待
        model.state = TWDownloadStateWaiting;
        [[TWDataBaseManager shareManager] updateWithModel:model option:TWDBUpdateOptionState];
    }
}

#pragma mark - NSURLSessionDownloadDelegate
// 接收到服务器返回数据，会被调用多次
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    // 获取模型
    TWDownloadModel *model = [[TWDataBaseManager shareManager] getModelWithUrl:downloadTask.taskDescription];
    
    // 更新当前下载大小
    model.tmpFileSize = totalBytesWritten;
    model.totalFileSize = totalBytesExpectedToWrite;
    
    // 计算速度时间内下载文件的大小
    model.intervalFileSize += bytesWritten;
    
    // 获取上次计算时间与当前时间间隔
    NSInteger intervals = [TWDownloadUtil getIntervalsWithTimeStamp:model.lastSpeedTime];
    if (intervals >= 1) {
        // 计算速度
        model.speed = model.intervalFileSize / intervals;
        
        // 重置变量
        model.intervalFileSize = 0;
        model.lastSpeedTime = [TWDownloadUtil getTimeStampWithDate:[NSDate date]];
    }
    
    // 计算进度
    model.progress = 1.0 * model.tmpFileSize / model.totalFileSize;
    
    // 更新数据库中数据
    [[TWDataBaseManager shareManager] updateWithModel:model option:TWDBUpdateOptionProgressData];
    
    // 进度通知
    [[NSNotificationCenter defaultCenter] postNotificationName:TWDownloadProgressNotification object:model];
}

// 下载完成
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    // 获取模型
    TWDownloadModel *model = [[TWDataBaseManager shareManager] getModelWithUrl:downloadTask.taskDescription];
    
    // 移动文件，原路径文件由系统自动删除
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:[location path] toPath:model.localPath error:&error];
    if (error) TWDLog(@"下载完成，移动文件发生错误：%@", error);
}

#pragma mark - NSURLSessionTaskDelegate
// 请求完成
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // 调用cancel方法直接返回，在相应操作是直接进行处理
    if (error && [error.localizedDescription isEqualToString:@"cancelled"]) return;
    
    // 获取模型
    TWDownloadModel *model = [[TWDataBaseManager shareManager] getModelWithUrl:task.taskDescription];
    
    // 下载时，进程杀死，重新启动，回调错误
    if (error && [error.userInfo objectForKey:NSURLErrorBackgroundTaskCancelledReasonKey]) {
        model.state = TWDownloadStateWaiting;
        model.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        [[TWDataBaseManager shareManager] updateWithModel:model option:TWDBUpdateOptionState | TWDBUpdateOptionResumeData];
        return;
    }
    
    // 更新下载数据、任务状态
    if (error) {
        model.state = TWDownloadStateError;
        model.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        [[TWDataBaseManager shareManager] updateWithModel:model option:TWDBUpdateOptionResumeData];
        
    }else {
        model.state = TWDownloadStateFinish;
    }
    
    // 更新数据
    if (_currentCount > 0) _currentCount--;
    [_dataTaskDic removeObjectForKey:model.url];
    
    // 更新数据库状态
    [[TWDataBaseManager shareManager] updateWithModel:model option:TWDBUpdateOptionState];
    
    // 开启等待下载任务
    [self startDownloadWaitingTask];
    TWDLog(@"\n    文件：%@，下载完成 \n    本地路径：%@ \n    错误：%@ \n", model.fileName, model.localPath, error);
}

#pragma mark - NSURLSessionDelegate
// 应用处于后台，所有下载任务完成及NSURLSession协议调用之后调用
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.backgroundSessionCompletionHandler) {
            void (^completionHandler)(void) = self.backgroundSessionCompletionHandler;
            self.backgroundSessionCompletionHandler = nil;
            TWDLog(@"执行block，系统后台生成快照，释放阻止应用挂起的断言");
            // 执行block，系统后台生成快照，释放阻止应用挂起的断言
            completionHandler();
        }
    });
}

#pragma mark - TWDownloadMaxConcurrentCountChangeNotification
- (void)downloadMaxConcurrentCountChange:(NSNotification *)notification {
    _maxConcurrentCount = [notification.object integerValue];
    
    if (_currentCount < _maxConcurrentCount) {
        // 当前下载数小于并发数，开启等待下载任务
        [self startDownloadWaitingTask];
        
    }else if (_currentCount > _maxConcurrentCount) {
        // 变更正在下载任务为等待下载
        [self pauseDownloadingTaskWithAll:NO];
    }
}

#pragma mark - TWDownloadAllowsCellularAccessChangeNotification
- (void)downloadAllowsCellularAccessChange:(NSNotification *)notification {
    _allowsCellularAccess = [notification.object boolValue];
    
    [self allowsCellularAccessOrNetworkingReachabilityDidChangeAction];
}

#pragma mark - TWNetworkingReachabilityDidChangeNotification
- (void)networkingReachabilityDidChange:(NSNotification *)notification {
    [self allowsCellularAccessOrNetworkingReachabilityDidChangeAction];
}

// 是否允许蜂窝网络下载或网络状态变更事件
- (void)allowsCellularAccessOrNetworkingReachabilityDidChangeAction {
    if ([[TWNetworkReachability shareManager] networkReachabilityStatus] == AFNetworkReachabilityStatusNotReachable) {
        // 无网络，暂停正在下载任务
        [self pauseDownloadingTaskWithAll:YES];
        
    }else {
        if ([self networkingAllowsDownloadTask]) {
            // 开启等待任务
            [self startDownloadWaitingTask];
            
        }else {
            // 增加一个友善的提示，蜂窝网络情况下如果有正在下载，提示已暂停
            if ([[TWDataBaseManager shareManager] getLastDownloadingModel]) {
                [TWDownloadHUD showMessage:@"当前为蜂窝网络，已停止下载任务，可在设置中开启" duration:4.f];
            }
            
            // 当前为蜂窝网络，不允许下载，暂停正在下载任务
            [self pauseDownloadingTaskWithAll:YES];
        }
    }
}

// 是否允许下载任务
- (BOOL)networkingAllowsDownloadTask {
    // 当前网络状态
    AFNetworkReachabilityStatus status = [[TWNetworkReachability shareManager] networkReachabilityStatus];
    
    // 无网络 或 （当前为蜂窝网络，且不允许蜂窝网络下载）
    if (status == AFNetworkReachabilityStatusNotReachable || (status == AFNetworkReachabilityStatusReachableViaWWAN && !_allowsCellularAccess)) {
        return NO;
    }
    
    return YES;
}

- (void)dealloc {
    [_session invalidateAndCancel];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
