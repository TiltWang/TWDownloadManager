//
//  TWDataBaseManager.h
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TWDownloadUtil.h"

@class TWDownloadModel;
@interface TWDataBaseManager : NSObject

///存储的数据库名称  修改请使用 TWDownloadManager中 changeDBSaveFilePathName: 方法
@property (nonatomic, strong) NSString *dbFileName;

// 获取单例
+ (instancetype)shareManager;

// 插入数据
- (void)insertModel:(TWDownloadModel *)model;

// 获取数据
- (TWDownloadModel *)getModelWithUrl:(NSString *)url;    // 根据url获取数据
- (TWDownloadModel *)getWaitingModel;                    // 获取第一条等待的数据
- (TWDownloadModel *)getLastDownloadingModel;            // 获取最后一条正在下载的数据
- (NSArray<TWDownloadModel *> *)getAllCacheData;         // 获取所有数据
- (NSArray<TWDownloadModel *> *)getAllDownloadingData;   // 根据lastStateTime倒叙获取所有正在下载的数据
- (NSArray<TWDownloadModel *> *)getAllDownloadedData;    // 获取所有下载完成的数据
- (NSArray<TWDownloadModel *> *)getAllUnDownloadedData;  // 获取所有未下载完成的数据（包含正在下载、等待、暂停、错误）
- (NSArray<TWDownloadModel *> *)getAllWaitingData;       // 获取所有等待下载的数据

// 更新数据
- (void)updateWithModel:(TWDownloadModel *)model option:(TWDBUpdateOption)option;

// 删除数据
- (void)deleteModelWithUrl:(NSString *)url;
@end
