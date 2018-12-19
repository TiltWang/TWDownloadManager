//
//  TWDownloadBtn.h
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TWDownloadHeader.h"

@class TWDownloadModel;
@interface TWDownloadBtn : UIView
@property (nonatomic, strong) TWDownloadModel *model;  // 数据模型
@property (nonatomic, assign) TWDownloadState state;   // 下载状态
@property (nonatomic, assign) CGFloat progress;        // 下载进度

// 添加点击方法
- (void)addTarget:(id)target action:(SEL)action;
@end
