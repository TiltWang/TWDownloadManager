//
//  TWDownloadTableView.m
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import "TWDownloadTableView.h"
#import "TWDownloadTableViewCell.h"
#import "TWDownloadModel.h"
#import "TWDataBaseManager.h"
#import <TWBaseTool.h>
#import "TWDownloadManager.h"

@interface TWDownloadTableView ()  <UITableViewDelegate, UITableViewDataSource>

@end

static NSString *DownloadTableViewReuseCell = @"DownloadTableViewReuseCell";

@implementation TWDownloadTableView

- (void)setDataList:(NSMutableArray<TWDownloadModel *> *)dataList {
    _dataList = dataList;
    [self getCacheData];
    [self reloadData];
}

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.delegate = self;
        self.dataSource = self;
        [self registerClass:[TWDownloadTableViewCell class] forCellReuseIdentifier:DownloadTableViewReuseCell];
        self.tableFooterView = [[UIView alloc] init];
        //分割线两端无间距
        self.separatorInset = UIEdgeInsetsZero;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        [self addNotification];
    }
    return self;
}


#pragma mark - UITableViewDelegate, UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TWDownloadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DownloadTableViewReuseCell forIndexPath:indexPath];
    TWDownloadModel *model = [self.dataList objectAtIndex:indexPath.row];
    cell.model = model;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [TWDownloadTableViewCell rowHeight];
}

#pragma mark - 侧滑删除
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
//    TWDownloadModel *model = [self.dataList objectAtIndex:indexPath.row];
//    if (model.state == TWDownloadStateFinish || model.state == TWDownloadStatePaused || model.state == TWDownloadStateError) {
//        return YES;
//    }
//    return NO;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    TWDownloadModel *model = [self.dataList objectAtIndex:indexPath.row];
    //只要实现这个方法，就实现了默认滑动删除！！！！！
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"您是否确定删除此下载?" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *delete = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            TWLog(@"删除动作");
            [[TWDownloadManager shareManager] deleteTaskAndCache:model];
            [self.dataList removeObject:model];
            [self reloadData];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:delete];
        [alert addAction:cancel];
        if (self.superVc) {
            [self.superVc presentViewController:alert animated:YES completion:nil];
        }
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

#pragma mark - TWDownloadNotification
// 正在下载，进度回调
- (void)downLoadProgress:(NSNotification *)notification {
    TWDownloadModel *downloadModel = notification.object;
    
    [self.dataList enumerateObjectsUsingBlock:^(TWDownloadModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.url isEqualToString:downloadModel.url]) {
            // 主线程更新cell进度
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                TWDownloadTableViewCell *cell = [weakSelf cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
                [cell updateViewWithModel:downloadModel];
            });
            
            *stop = YES;
        }
    }];
}

// 状态改变
- (void)downLoadStateChange:(NSNotification *)notification {
    TWDownloadModel *downloadModel = notification.object;
    
    [self.dataList enumerateObjectsUsingBlock:^(TWDownloadModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.url isEqualToString:downloadModel.url]) {
            // 更新数据源
            self.dataList[idx] = downloadModel;
            
            // 主线程刷新cell
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            });
            
            *stop = YES;
        }
    }];
}

- (void)getCacheData {
    // 获取已缓存数据
    NSArray *cacheData = [[TWDataBaseManager shareManager] getAllCacheData];
    
    // 这里是把本地缓存数据更新到网络请求的数据中，实际开发还是尽可能避免这样在两个地方取数据再整合
    for (int i = 0; i < self.dataList.count; i++) {
        TWDownloadModel *model = self.dataList[i];
        for (TWDownloadModel *downloadModel in cacheData) {
            if ([model.url isEqualToString:downloadModel.url]) {
                self.dataList[i] = downloadModel;
                break;
            }
        }
    }
    
    [self reloadData];
}

- (void)addNotification {
    // 进度通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downLoadProgress:) name:TWDownloadProgressNotification object:nil];
    // 状态改变通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downLoadStateChange:) name:TWDownloadStateChangeNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
