//
//  TestViewController.m
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/14.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import "TestViewController.h"
#import <TWBaseTool.h>
#import "TWDownloadModel.h"
#import "TWDownloadTableView.h"
#import "TWDownloadManager.h"

@interface TestViewController ()
@property (nonatomic, strong) TWDownloadTableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataList;
@end

@implementation TestViewController

- (void)btnClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)btnChangeClick {
    [[TWDownloadManager shareManager] changeDBSaveFilePathName:@"test123"];
    self.dataList = nil;
    [self.tableView reloadData];
//    [twd shareManager].dbFileName = @"test123";
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    self.tableView.dataList = self.dataList;
    self.view.backgroundColor = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 500, 80, 40)];
    btn.backgroundColor = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
    [btn setTitle:@"返回" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(0, 560, 180, 40)];
    btn2.backgroundColor = [UIColor colorWithRed:((float)arc4random_uniform(256) / 255.0) green:((float)arc4random_uniform(256) / 255.0) blue:((float)arc4random_uniform(256) / 255.0) alpha:1.0];
    [btn2 setTitle:@"改变存储表路径" forState:UIControlStateNormal];
    [self.view addSubview:btn2];
    [btn2 addTarget:self action:@selector(btnChangeClick) forControlEvents:UIControlEventTouchUpInside];
}

- (NSMutableArray *)dataList {
    if (!_dataList) {
        TWDownloadModel *model1 = [[TWDownloadModel alloc] init];
        model1.vid = @"1";
        model1.url = @"https://www.apple.com/105/media/cn/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-cn-20170912_1280x720h.mp4";
        model1.fileName = @"网络视频文件 01";
        model1.detail = @"描述";
        model1.fileType = TWDownloadFileTypeVideo;
        TWDownloadModel *model2 = [[TWDownloadModel alloc] init];
        model2.vid = @"2";
        model2.url = @"https://images.apple.com/media/cn/macbook-pro/2016/b4a9efaa_6fe5_4075_a9d0_8e4592d6146c/films/design/macbook-pro-design-tft-cn-20161026_1536x640h.mp4";
        model2.fileName = @"网络视频文件 03";
        model2.detail = @"desc";
        model2.fileType = TWDownloadFileTypeVideo;
        _dataList = [NSMutableArray arrayWithArray:@[model1, model2]];
    }
    return _dataList;
}

- (TWDownloadTableView *)tableView {
    if (!_tableView) {
        _tableView = [[TWDownloadTableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
        _tableView.superVc = self;
    }
    return _tableView;
}


@end
