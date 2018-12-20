//
//  TWDownloadModel.m
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import "TWDownloadModel.h"
#import <FMDB/FMDB.h>

@implementation TWDownloadModel

- (NSString *)localPath {
    if (!_localPath) {
        NSString *fileName = [_url substringFromIndex:[_url rangeOfString:@"/" options:NSBackwardsSearch].location + 1];
        NSString *str = [NSString stringWithFormat:@"%@_%@", _vid, fileName];
        _localPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:str];
    }
    
    return _localPath;
}

- (instancetype)initWithFMResultSet:(FMResultSet *)resultSet {
    if (!resultSet) {
        return nil;
    } else {
        _vid = [NSString stringWithFormat:@"%@", [resultSet objectForColumn:@"vid"]];
        _url = [NSString stringWithFormat:@"%@", [resultSet objectForColumn:@"url"]];
        _fileName = [NSString stringWithFormat:@"%@", [resultSet objectForColumn:@"fileName"]];
        _detail = [NSString stringWithFormat:@"%@", [resultSet objectForColumn:@"detail"]];
        _fileType = [[resultSet objectForColumn:@"fileType"] integerValue];
        _totalFileSize = [[resultSet objectForColumn:@"totalFileSize"] integerValue];
        _tmpFileSize = [[resultSet objectForColumn:@"tmpFileSize"] integerValue];
        _progress = [[resultSet objectForColumn:@"progress"] floatValue];
        _state = [[resultSet objectForColumn:@"state"] integerValue];
        _lastSpeedTime = [[resultSet objectForColumn:@"lastSpeedTime"] integerValue];
        _intervalFileSize = [[resultSet objectForColumn:@"intervalFileSize"] integerValue];
        _lastStateTime = [[resultSet objectForColumn:@"lastStateTime"] integerValue];
        _resumeData = [resultSet dataForColumn:@"resumeData"];
        
        return self;
    }
}
@end
