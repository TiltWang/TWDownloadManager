//
//  TWDownloadHeader.h
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#ifndef TWDownloadHeader_h
#define TWDownloadHeader_h

/************************* 下载 *************************/
#define TWDownloadProgressNotification                   @"TWDownloadProgressNotification"
#define TWDownloadStateChangeNotification                @"TWDownloadStateChangeNotification"
#define TWDownloadMaxConcurrentCountKey                  @"TWDownloadMaxConcurrentCountKey"
#define TWDownloadMaxConcurrentCountChangeNotification   @"TWDownloadMaxConcurrentCountChangeNotification"
#define TWDownloadAllowsCellularAccessKey                @"TWDownloadAllowsCellularAccessKey"
#define TWDownloadAllowsCellularAccessChangeNotification @"TWDownloadAllowsCellularAccessChangeNotification"
#define TWDownloadConfigOnceKey                          @"TWDownloadConfigOnceKey"
#define TWDownloadDBFileSavePathName                     @"TWDownloadDBFileSavePathName"

/************************* 网络 *************************/
#define TWNetworkingReachabilityDidChangeNotification    @"TWNetworkingReachabilityDidChangeNotification"


///设置debug下打印
#ifdef DEBUG
#define TWDLog(format, ...) printf("\n[%s] %s [第%d行] %s\n", __TIME__, __FUNCTION__, __LINE__, [[NSString stringWithFormat:format, ## __VA_ARGS__] UTF8String]);
#else
#define TWDLog(format, ...)
#endif


///数据库更新状态
typedef NS_OPTIONS(NSUInteger, TWDBUpdateOption) {
    TWDBUpdateOptionState         = 1 << 0,  // 更新状态
    TWDBUpdateOptionLastStateTime = 1 << 1,  // 更新状态最后改变的时间
    TWDBUpdateOptionResumeData    = 1 << 2,  // 更新下载的数据
    TWDBUpdateOptionProgressData  = 1 << 3,  // 更新进度数据（包含tmpFileSize、totalFileSize、progress、intervalFileSize、lastSpeedTime）
    TWDBUpdateOptionAllParam      = 1 << 4   // 更新全部数据
};

///下载状态
typedef NS_ENUM(NSInteger, TWDownloadState) {
    TWDownloadStateDefault = 0,  // 默认
    TWDownloadStateDownloading,  // 正在下载
    TWDownloadStateWaiting,      // 等待
    TWDownloadStatePaused,       // 暂停
    TWDownloadStateFinish,       // 完成
    TWDownloadStateError,        // 错误
};

///缓存数据状态
typedef NS_ENUM(NSInteger, TWDBGetDateOption) {
    TWDBGetDateOptionAllCacheData = 0,      // 所有缓存数据
    TWDBGetDateOptionAllDownloadingData,    // 所有正在下载的数据
    TWDBGetDateOptionAllDownloadedData,     // 所有下载完成的数据
    TWDBGetDateOptionAllUnDownloadedData,   // 所有未下载完成的数据
    TWDBGetDateOptionAllWaitingData,        // 所有等待下载的数据
    TWDBGetDateOptionModelWithUrl,          // 通过url获取单条数据
    TWDBGetDateOptionWaitingModel,          // 第一条等待的数据
    TWDBGetDateOptionLastDownloadingModel,  // 最后一条正在下载的数据
};

///缓存数据文件类型
typedef NS_ENUM(NSInteger, TWDownloadFileType) {
    TWDownloadFileTypeVideo = 0,      // 视频
    TWDownloadFileTypeDocument,       // 文档
    TWDownloadFileTypePicture,        // 图片
    TWDownloadFileTypeOther,          // 其他
};

#endif /* TWDownloadHeader_h */
