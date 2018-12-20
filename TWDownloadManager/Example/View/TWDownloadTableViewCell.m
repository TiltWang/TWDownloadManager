//
//  TWDownloadTableViewCell.m
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import "TWDownloadTableViewCell.h"
#import "TWDownloadBtn.h"
#import <TWBaseTool.h>
#import <UIView+Frame.h>
#import "TWDownloadModel.h"
#import "TWDownloadUtil.h"

@interface TWDownloadTableViewCell ()

@property (nonatomic, weak) UILabel *titleLabel;            // 标题
@property (nonatomic, weak) UILabel *speedLabel;            // 进度标签
@property (nonatomic, weak) UILabel *fileSizeLabel;         // 文件大小标签
@property (nonatomic, weak) TWDownloadBtn *downloadBtn;  // 下载按钮

@end


@implementation TWDownloadTableViewCell

+ (CGFloat)rowHeight {
    return 80.0f;
}

//+ (instancetype)cellWithTableView:(UITableView *)tabelView
//{
////    static NSString *identifier = @"TWDownloadTableViewReuseCell";
//    
//    TWDownloadTableViewCell *cell = [tabelView dequeueReusableCellWithIdentifier:identifier];
//    if (!cell) {
//        cell = [[TWDownloadTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//        cell.backgroundColor = [UIColor whiteColor];
//    }
//    
//    return cell;
//}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        // 底图
        CGFloat margin = 10.f;
        CGFloat backViewH = 70.f;
        UIView *backView = [[UIView alloc] initWithFrame:CGRectMake(margin, margin, ScreenWidth - margin * 2, backViewH)];
        backView.backgroundColor = HEXCOLOR(0x00CDCD);//[UIColor colorWithHexString:@"#00CDCD"];
        [self.contentView addSubview:backView];
        
        // 下载按钮
        CGFloat btnW = 50.f;
        TWDownloadBtn *downloadBtn = [[TWDownloadBtn alloc] initWithFrame:CGRectMake(backView.width - btnW - margin, (backViewH - btnW) * 0.5, btnW, btnW)];
        [downloadBtn addTarget:self action:@selector(downBtnOnClick:)];
        [backView addSubview:downloadBtn];
        _downloadBtn = downloadBtn;
        
        // 标题
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, 0, backView.width - margin * 4 - btnW, backViewH * 0.6)];
        titleLabel.font = [UIFont boldSystemFontOfSize:18.f];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = backView.backgroundColor;
        titleLabel.layer.masksToBounds = YES;
        [backView addSubview:titleLabel];
        _titleLabel = titleLabel;
        
        // 进度标签
        UILabel *speedLable = [[UILabel alloc] initWithFrame:CGRectMake(margin, CGRectGetMaxY(titleLabel.frame), titleLabel.width * 0.4, backViewH * 0.4)];
        speedLable.font = [UIFont systemFontOfSize:14.f];
        speedLable.textColor = [UIColor whiteColor];
        speedLable.textAlignment = NSTextAlignmentRight;
        speedLable.backgroundColor = backView.backgroundColor;
        speedLable.layer.masksToBounds = YES;
        [backView addSubview:speedLable];
        _speedLabel = speedLable;
        
        // 文件大小标签
        UILabel *fileSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(speedLable.frame), CGRectGetMaxY(titleLabel.frame), titleLabel.width - speedLable.width, backViewH * 0.4)];
        fileSizeLabel.font = [UIFont systemFontOfSize:14.f];
        fileSizeLabel.textColor = [UIColor whiteColor];
        fileSizeLabel.textAlignment = NSTextAlignmentRight;
        fileSizeLabel.backgroundColor = backView.backgroundColor;
        fileSizeLabel.layer.masksToBounds = YES;
        [backView addSubview:fileSizeLabel];
        _fileSizeLabel = fileSizeLabel;
    }
    
    return self;
}

- (void)setModel:(TWDownloadModel *)model
{
    _model = model;
    
    _downloadBtn.model = model;
    _titleLabel.text = [NSString stringWithFormat:@"%@ : %@ : %@", model.fileName, model.detail, @(model.fileType)];// model.fileName;
    [self updateViewWithModel:model];
}

// 更新视图
- (void)updateViewWithModel:(TWDownloadModel *)model
{
    _downloadBtn.progress = model.progress;
    
    [self reloadLabelWithModel:model];
}

// 刷新标签
- (void)reloadLabelWithModel:(TWDownloadModel *)model
{
    NSString *totalSize = [TWDownloadUtil stringFromByteCount:model.totalFileSize];
    NSString *tmpSize = [TWDownloadUtil stringFromByteCount:model.tmpFileSize];
    
    if (model.state == TWDownloadStateFinish) {
        _fileSizeLabel.text = [NSString stringWithFormat:@"%@", totalSize];
        
    }else {
        _fileSizeLabel.text = [NSString stringWithFormat:@"%@ / %@", tmpSize, totalSize];
    }
    _fileSizeLabel.hidden = model.totalFileSize == 0;
    
    if (model.speed > 0) {
        _speedLabel.text = [NSString stringWithFormat:@"%@ / s", [TWDownloadUtil stringFromByteCount:model.speed]];
    }
    _speedLabel.hidden = !(model.state == TWDownloadStateDownloading && model.totalFileSize > 0);
}

- (void)downBtnOnClick:(TWDownloadBtn *)btn
{
    TWLog(@"下载: %@",  self.model.localPath);
    if (self.model.state == TWDownloadStateFinish) {
        TWLog(@"完成后去使用");//或者点击cell去使用
    }
    // do something...
}

@end
