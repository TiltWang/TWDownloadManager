//
//  TWDownloadManager.h
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TWDownloadModel;
@interface TWDownloadManager : NSObject

@property (nonatomic, copy) void (^ backgroundSessionCompletionHandler)(void);  // 后台所有下载任务完成回调

// 获取单例 
+ (instancetype)shareManager;

// 一次性设置代码 放在APPdelegate.m的didFinishLaunchingWithOptions中
+ (void)appDownloadConfigOnceCode;

// 开始下载
- (void)startDownloadTask:(TWDownloadModel *)model;

// 暂停下载
- (void)pauseDownloadTask:(TWDownloadModel *)model;

// 删除下载任务及本地缓存
- (void)deleteTaskAndCache:(TWDownloadModel *)model;

// 下载时，杀死进程，更新所有正在下载的任务为等待
- (void)updateDownloadingTaskState;

// 重启时开启等待下载的任务
- (void)openDownloadTask;
@end
