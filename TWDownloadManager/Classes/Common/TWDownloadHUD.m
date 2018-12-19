//
//  TWDownloadHUD.m
//  TWDownloadManager
//
//  Created by Tilt on 2018/12/11.
//  Copyright © 2018年 tilt. All rights reserved.
//

#import "TWDownloadHUD.h"

#define KLabelMaxW 240.0f
#define KLabelMaxH 300.0f
#define KDefaultDuration 2.0f

@interface TWDownloadHUD ()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, weak) UILabel *label;
@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, weak) UIView *backView;

@end


@implementation TWDownloadHUD

- (UIWindow *)window {
    if (!_window) {
        _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    
    return _window;
}

+ (TWDownloadHUD *)sharedView {
    static TWDownloadHUD *progressHUD = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        progressHUD = [[TWDownloadHUD alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    });
    
    return progressHUD;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 背景
        UIView *backView = [[UIView alloc] init];
        backView.alpha = 0.f;
        backView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7f];
        backView.layer.cornerRadius = 3.f;
        backView.layer.masksToBounds = YES;
        [self addSubview:backView];
        _backView = backView;
        
        // 标签
        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:17.0f];
        label.layer.masksToBounds = YES;
        [backView addSubview:label];
        _label = label;
        
        // 图片
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.hidden = YES;
        imageView.layer.cornerRadius = 3.f;
        imageView.layer.masksToBounds = YES;
        [self addSubview:imageView];
        _imageView = imageView;
    }
    
    return self;
}

+ (void)show {
    [[TWDownloadHUD sharedView] showWithMessage:nil duration:KDefaultDuration pushing:NO view:nil];
}

+ (void)showInView:(UIView *)view {
    [[TWDownloadHUD sharedView] showWithMessage:nil duration:KDefaultDuration pushing:NO view:view];
}

+ (void)showWhilePushing {
    [[TWDownloadHUD sharedView] showWithMessage:nil duration:KDefaultDuration pushing:YES view:nil];
}

+ (void)showWhilePushing:(BOOL)pushing {
    [[TWDownloadHUD sharedView] showWithMessage:nil duration:KDefaultDuration pushing:pushing view:nil];
}

+ (void)showMessage:(NSString *)message {
    [[TWDownloadHUD sharedView] showWithMessage:message duration:KDefaultDuration pushing:nil view:nil];
}

+ (void)showMessage:(NSString *)message inView:(UIView *)view {
    [[TWDownloadHUD sharedView] showWithMessage:message duration:KDefaultDuration pushing:nil view:view];
}

+ (void)showMessage:(NSString *)message duration:(NSTimeInterval)duration {
    [[TWDownloadHUD sharedView] showWithMessage:message duration:duration pushing:nil view:nil];
}

+ (void)showMessage:(NSString *)message duration:(NSTimeInterval)duration inView:(UIView *)view {
    [[TWDownloadHUD sharedView] showWithMessage:message duration:duration pushing:nil view:view];
}

+ (void)dismiss {
    [[TWDownloadHUD sharedView] dismiss];
}

- (void)showWithMessage:(NSString *)message duration:(NSTimeInterval)duration pushing:(BOOL)pushing view:(UIView *)view {
    [self dismiss];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        CGRect frame;
        if (view) {
            [view addSubview:self];
            frame = view.frame;
        }else {
            if (!self.superview) [self.window addSubview:self];
            [self.window makeKeyAndVisible];
            frame = self.window.frame;
        }
        
        strongSelf.imageView.hidden = message;
        strongSelf.label.hidden = !message;
        
        if (message) {
            // 更新标签信息
            strongSelf.label.text = message;
            CGSize size = [message boundingRectWithSize:CGSizeMake(KLabelMaxW, KLabelMaxH) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:strongSelf.label.font} context:nil].size;
            strongSelf.label.frame = CGRectMake(15, 15, size.width, size.height);
            strongSelf.backView.frame = CGRectMake((frame.size.width - size.width) * 0.5 - 15, (frame.size.height - size.height) * 0.5 - 15, size.width + 30, size.height + 30);
            
            // 显示，隐藏动画
            strongSelf.backView.alpha = 0.0f;
            NSTimeInterval animateTimeInterval = 0.2f;
            [UIView animateWithDuration:animateTimeInterval animations:^{
                strongSelf.backView.alpha = 1.0f;
            } completion:^(BOOL finished) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((duration - animateTimeInterval * 2) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:animateTimeInterval animations:^{
                        strongSelf.backView.alpha = 0.0f;
                    } completion:^(BOOL finished) {
                        [self dismiss];
                    }];
                });
            }];
            
        }else {
            // 更新信息
            CGFloat imgViewW = pushing ? 200 : 50;
            strongSelf.imageView.backgroundColor = [UIColor clearColor];
            strongSelf.imageView.frame = CGRectMake((frame.size.width - imgViewW) * 0.5, (frame.size.height - imgViewW) * 0.5, imgViewW, imgViewW);
            
            // 开始动画
            if (pushing) {
                [self startPushingLoadingAnimation];
                
            }else {
                strongSelf.backView.alpha = 1.0f;
                strongSelf.backView.frame = CGRectMake((frame.size.width - strongSelf.imageView.frame.size.width) * 0.5 - 10, (frame.size.height - strongSelf.imageView.frame.size.height) * 0.5 - 10, strongSelf.imageView.frame.size.width + 20, strongSelf.imageView.frame.size.height + 20);
                [self startLoadingAnimation];
            }
        }
    });
}

// 转圈加载动画
- (void)startLoadingAnimation {
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 8; i++) {
        NSString *imageName = [NSString stringWithFormat:@"com_loading%02d", i + 1];
        UIImage *image = [UIImage imageNamed:imageName];
        [array addObject:image];
    }
    
    [_imageView setAnimationImages:array];
    [_imageView setAnimationDuration:0.6f];
    [_imageView startAnimating];
}

// 空页面加载动画
- (void)startPushingLoadingAnimation {
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 2; i++) {
        NSString *imageName = [NSString stringWithFormat:@"com_loading_emptyImg%02d.jpg", i + 1];
        UIImage *image = [UIImage imageNamed:imageName];
        [array addObject:image];
    }
    
    [_imageView setAnimationImages:array];
    [_imageView setAnimationDuration:0.4f];
    [_imageView startAnimating];
}

- (void)stopLoadingAnimation {
    if (_imageView.isAnimating) {
        [_imageView stopAnimating];
        [_imageView performSelector:@selector(setAnimationImages:) withObject:nil afterDelay:0];
    }
}

- (void)dismiss {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [self stopLoadingAnimation];
        
        [self removeFromSuperview];
        
        NSMutableArray *windows = [[NSMutableArray alloc] initWithArray:[UIApplication sharedApplication].windows];
        [windows removeObject:strongSelf.window];
        strongSelf.window = nil;
    });
}

@end
