//
//  TWDownloadTableViewCell.h
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TWDownloadModel;
@interface TWDownloadTableViewCell : UITableViewCell

@property (nonatomic, strong) TWDownloadModel *model;

//+ (instancetype)cellWithTableView:(UITableView *)tabelView;
+ (CGFloat)rowHeight;
// 更新视图
- (void)updateViewWithModel:(TWDownloadModel *)model;
@end
