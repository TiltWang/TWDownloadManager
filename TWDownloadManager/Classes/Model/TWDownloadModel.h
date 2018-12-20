//
//  TWDownloadModel.h
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TWDownloadUtil.h"

@class FMResultSet;
@interface TWDownloadModel : NSObject

@property (nonatomic, copy) NSString *localPath;            // 下载完成路径
@property (nonatomic, copy) NSString *vid;                  // 唯一id标识
@property (nonatomic, copy) NSString *fileName;             // 文件名
@property (nonatomic, copy) NSString *detail;               // 描述
@property (nonatomic, copy) NSString *url;                  // url
@property (nonatomic, assign) TWDownloadFileType fileType;  //文件类型
@property (nonatomic, strong) NSData *resumeData;           // 下载的数据
@property (nonatomic, assign) CGFloat progress;             // 下载进度
@property (nonatomic, assign) TWDownloadState state;        // 下载状态
@property (nonatomic, assign) NSUInteger totalFileSize;     // 文件总大小
@property (nonatomic, assign) NSUInteger tmpFileSize;       // 下载大小
@property (nonatomic, assign) NSUInteger speed;             // 下载速度
@property (nonatomic, assign) NSUInteger lastSpeedTime;     // 上次计算速度时的时间戳
@property (nonatomic, assign) NSUInteger intervalFileSize;  // 计算速度时间内下载文件的大小
@property (nonatomic, assign) NSUInteger lastStateTime;     // 记录任务加入准备下载的时间（点击默认、暂停、失败状态），用于计算开始、停止任务的先后顺序

// 根据数据库查询结果初始化
- (instancetype)initWithFMResultSet:(FMResultSet *)resultSet;

@end
