//
//  TWDataBaseManager.m
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import "TWDataBaseManager.h"
#import "TWDownloadModel.h"
#import <FMDB/FMDB.h>

@interface TWDataBaseManager ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation TWDataBaseManager

- (void)setDbFileName:(NSString *)dbFileName {
    _dbFileName = dbFileName;
    if (dbFileName && dbFileName.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:dbFileName forKey:TWDownloadDBFileSavePathName];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [_dbQueue close];
        [self creatVideoCachesTable];
    }
}

+ (instancetype)shareManager {
    static TWDataBaseManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        [self creatVideoCachesTable];
    }
    
    return self;
}

// 创表
- (void)creatVideoCachesTable {
    NSString *fileName = [[NSUserDefaults standardUserDefaults] objectForKey:TWDownloadDBFileSavePathName];
    [self creatVideoCachesTableWithDbFileName:fileName];
}

- (void)creatVideoCachesTableWithDbFileName:(NSString *)dbFileName {
    NSString *tailPath = [NSString stringWithFormat:@"%@.sqlite", dbFileName];
    // 数据库文件路径
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:tailPath];
    
    // 创建队列对象，内部会自动创建一个数据库, 并且自动打开
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        // 创表
        BOOL result = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_videoCaches (id integer PRIMARY KEY AUTOINCREMENT, vid text, fileName text, detail text, url text, fileType integer, resumeData blob, totalFileSize integer, tmpFileSize integer, state integer, progress float, lastSpeedTime integer, intervalFileSize integer, lastStateTime integer)"];
        if (result) {
            //            HWLog(@"视频缓存数据表创建成功");
        }else {
            TWDLog(@"视频缓存数据表创建失败");
        }
    }];
}

// 插入数据
- (void)insertModel:(TWDownloadModel *)model {
    [_dbQueue inDatabase:^(FMDatabase *db) {
        BOOL result = [db executeUpdate:@"INSERT INTO t_videoCaches (vid, fileName, detail, url, fileType, resumeData, totalFileSize, tmpFileSize, state, progress, lastSpeedTime, intervalFileSize, lastStateTime) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", model.vid, model.fileName, model.detail, model.url, [NSNumber numberWithInteger:model.fileType], model.resumeData, [NSNumber numberWithInteger:model.totalFileSize], [NSNumber numberWithInteger:model.tmpFileSize], [NSNumber numberWithInteger:model.state], [NSNumber numberWithFloat:model.progress], [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:0]];
        if (result) {
            //            TWDLog(@"插入成功：%@", model.fileName);
        }else {
            TWDLog(@"插入失败：%@", model.fileName);
        }
    }];
}

// 获取单条数据
- (TWDownloadModel *)getModelWithUrl:(NSString *)url {
    return [self getModelWithOption:TWDBGetDateOptionModelWithUrl url:url];
}

// 获取第一条等待的数据
- (TWDownloadModel *)getWaitingModel {
    return [self getModelWithOption:TWDBGetDateOptionWaitingModel url:nil];
}

// 获取最后一条正在下载的数据
- (TWDownloadModel *)getLastDownloadingModel {
    return [self getModelWithOption:TWDBGetDateOptionLastDownloadingModel url:nil];
}

// 获取所有数据
- (NSArray<TWDownloadModel *> *)getAllCacheData {
    return [self getDateWithOption:TWDBGetDateOptionAllCacheData];
}

// 根据lastStateTime倒叙获取所有正在下载的数据
- (NSArray<TWDownloadModel *> *)getAllDownloadingData {
    return [self getDateWithOption:TWDBGetDateOptionAllDownloadingData];
}

// 获取所有下载完成的数据
- (NSArray<TWDownloadModel *> *)getAllDownloadedData {
    return [self getDateWithOption:TWDBGetDateOptionAllDownloadedData];
}

// 获取所有未下载完成的数据
- (NSArray<TWDownloadModel *> *)getAllUnDownloadedData {
    return [self getDateWithOption:TWDBGetDateOptionAllUnDownloadedData];
}

// 获取所有等待下载的数据
- (NSArray<TWDownloadModel *> *)getAllWaitingData {
    return [self getDateWithOption:TWDBGetDateOptionAllWaitingData];
}

// 获取单条数据
- (TWDownloadModel *)getModelWithOption:(TWDBGetDateOption)option url:(NSString *)url {
    __block TWDownloadModel *model = nil;
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet;
        switch (option) {
            case TWDBGetDateOptionModelWithUrl:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE url = ?", url];
                break;
                
            case TWDBGetDateOptionWaitingModel:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ? order by lastStateTime asc limit 0,1", [NSNumber numberWithInteger:TWDownloadStateWaiting]];
                break;
                
            case TWDBGetDateOptionLastDownloadingModel:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ? order by lastStateTime desc limit 0,1", [NSNumber numberWithInteger:TWDownloadStateDownloading]];
                break;
                
            default:
                break;
        }
        
        while ([resultSet next]) {
            model = [[TWDownloadModel alloc] initWithFMResultSet:resultSet];
        }
    }];
    
    return model;
}

// 获取数据集合
- (NSArray<TWDownloadModel *> *)getDateWithOption:(TWDBGetDateOption)option {
    __block NSArray<TWDownloadModel *> *array = nil;
    
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet;
        switch (option) {
            case TWDBGetDateOptionAllCacheData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches"];
                break;
                
            case TWDBGetDateOptionAllDownloadingData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ? order by lastStateTime desc", [NSNumber numberWithInteger:TWDownloadStateDownloading]];
                break;
                
            case TWDBGetDateOptionAllDownloadedData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ?", [NSNumber numberWithInteger:TWDownloadStateFinish]];
                break;
                
            case TWDBGetDateOptionAllUnDownloadedData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state != ?", [NSNumber numberWithInteger:TWDownloadStateFinish]];
                break;
                
            case TWDBGetDateOptionAllWaitingData:
                resultSet = [db executeQuery:@"SELECT * FROM t_videoCaches WHERE state = ?", [NSNumber numberWithInteger:TWDownloadStateWaiting]];
                break;
                
            default:
                break;
        }
        
        NSMutableArray *tmpArr = [NSMutableArray array];
        while ([resultSet next]) {
            [tmpArr addObject:[[TWDownloadModel alloc] initWithFMResultSet:resultSet]];
        }
        array = tmpArr;
    }];
    
    return array;
}

// 更新数据
- (void)updateWithModel:(TWDownloadModel *)model option:(TWDBUpdateOption)option {
    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (option & TWDBUpdateOptionState) {
            [self postStateChangeNotificationWithFMDatabase:db model:model];
            [db executeUpdate:@"UPDATE t_videoCaches SET state = ? WHERE url = ?", [NSNumber numberWithInteger:model.state], model.url];
        }
        if (option & TWDBUpdateOptionLastStateTime) {
            [db executeUpdate:@"UPDATE t_videoCaches SET lastStateTime = ? WHERE url = ?", [NSNumber numberWithInteger:[TWDownloadUtil getTimeStampWithDate:[NSDate date]]], model.url];
        }
        if (option & TWDBUpdateOptionResumeData) {
            [db executeUpdate:@"UPDATE t_videoCaches SET resumeData = ? WHERE url = ?", model.resumeData, model.url];
        }
        if (option & TWDBUpdateOptionProgressData) {
            [db executeUpdate:@"UPDATE t_videoCaches SET tmpFileSize = ?, totalFileSize = ?, progress = ?, lastSpeedTime = ?, intervalFileSize = ? WHERE url = ?", [NSNumber numberWithInteger:model.tmpFileSize], [NSNumber numberWithFloat:model.totalFileSize], [NSNumber numberWithFloat:model.progress], [NSNumber numberWithInteger:model.lastSpeedTime], [NSNumber numberWithInteger:model.intervalFileSize], model.url];
        }
        if (option & TWDBUpdateOptionAllParam) {
            [self postStateChangeNotificationWithFMDatabase:db model:model];
            [db executeUpdate:@"UPDATE t_videoCaches SET resumeData = ?, totalFileSize = ?, tmpFileSize = ?, progress = ?, state = ?, lastSpeedTime = ?, intervalFileSize = ?, lastStateTime = ? WHERE url = ?", model.resumeData, [NSNumber numberWithInteger:model.totalFileSize], [NSNumber numberWithInteger:model.tmpFileSize], [NSNumber numberWithFloat:model.progress], [NSNumber numberWithInteger:model.state], [NSNumber numberWithInteger:model.lastSpeedTime], [NSNumber numberWithInteger:model.intervalFileSize], [NSNumber numberWithInteger:[TWDownloadUtil getTimeStampWithDate:[NSDate date]]], model.url];
        }
    }];
}

// 状态变更通知
- (void)postStateChangeNotificationWithFMDatabase:(FMDatabase *)db model:(TWDownloadModel *)model {
    // 原状态
    NSInteger oldState = [db intForQuery:@"SELECT state FROM t_videoCaches WHERE url = ?", model.url];
    if (oldState != model.state) {
        // 状态变更通知
        [[NSNotificationCenter defaultCenter] postNotificationName:TWDownloadStateChangeNotification object:model];
    }
}

// 删除数据
- (void)deleteModelWithUrl:(NSString *)url {
    [_dbQueue inDatabase:^(FMDatabase *db) {
        BOOL result = [db executeUpdate:@"DELETE FROM t_videoCaches WHERE url = ?", url];
        if (result) {
            TWDLog(@"删除成功：%@", url);
        }else {
            TWDLog(@"删除失败：%@", url);
        }
    }];
}

@end
