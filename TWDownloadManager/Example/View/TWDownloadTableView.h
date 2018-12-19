//
//  TWDownloadTableView.h
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWDownloadModel;
@interface TWDownloadTableView : UITableView

@property (nonatomic, strong) NSMutableArray<TWDownloadModel *> *dataList;

@property (nonatomic, strong) UIViewController *superVc;
@end
