//
//  TWNetworkReachability.m
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import "TWNetworkReachability.h"
#import "TWDownloadUtil.h"

@interface TWNetworkReachability ()

@property (nonatomic, assign, readwrite) AFNetworkReachabilityStatus networkReachabilityStatus;

@end

@implementation TWNetworkReachability

+ (instancetype)shareManager {
    static TWNetworkReachability *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}

// 监听网络状态
- (void)monitorNetworkStatus {
    // 创建网络监听者
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    __weak typeof(self) weakSelf = self;
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                // 未知网络
                TWDLog(@"当前网络：未知网络");
                break;
                
            case AFNetworkReachabilityStatusNotReachable:
                // 无网络
                TWDLog(@"当前网络：无网络");
                break;
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
                // 蜂窝数据
                TWDLog(@"当前网络：蜂窝数据");
                break;
                
            case AFNetworkReachabilityStatusReachableViaWiFi:
                // 无线网络
                TWDLog(@"当前网络：无线网络");
                break;
                
            default:
                break;
        }
        if (weakSelf.networkReachabilityStatus != status) {
            weakSelf.networkReachabilityStatus = status;
            // 网络改变通知
            [[NSNotificationCenter defaultCenter] postNotificationName:TWNetworkingReachabilityDidChangeNotification object:[NSNumber numberWithInteger:status]];
        }
    }];
    
    // 开始监听
    [manager startMonitoring];
}
@end
