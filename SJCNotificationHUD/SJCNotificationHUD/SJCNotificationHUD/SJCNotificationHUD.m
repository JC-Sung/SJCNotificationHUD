//
//  SJCNotificationHUD.m
//  Yehwang
//
//  Created by Yehwang on 2020/11/3.
//  Copyright © 2020 Yehwang. All rights reserved.
//

#import "SJCNotificationHUD.h"
#import <AudioToolbox/AudioToolbox.h>

#define NotiHasSDWebImage (__has_include(<SDWebImage/UIImageView+WebCache.h>) || __has_include("UIImageView+WebCache.h"))

#define NotiIsEmpty(_object) (_object == nil \
|| [_object isKindOfClass:[NSNull class]] \
|| ([_object respondsToSelector:@selector(length)] && [(NSData *)_object length] == 0) \
|| ([_object respondsToSelector:@selector(count)] && [(NSArray *)_object count] == 0))

//iPhone X适配

#define IS_iPhoneX ({\
    BOOL isBangsScreen = NO; \
    if (@available(iOS 11.0, *)) { \
    UIWindow *window = [[UIApplication sharedApplication].windows firstObject]; \
    isBangsScreen = window.safeAreaInsets.bottom > 0; \
    } \
    isBangsScreen; \
})

#define kStatusBarHeight      (IS_iPhoneX ? 44.f : 20.f)

#define bannerH 100
#define bannerPading 8
#define bannerW ((float)[[UIScreen mainScreen] bounds].size.width)-bannerPading*2
#define verticalbannerPadding 12
#define horizontalPadding 10
#define verticalPadding 4
#define imageSize CGSizeMake(20, 20)

@interface SJCNotificationHUD ()<UIGestureRecognizerDelegate>
@property (strong, nonatomic) UIView *maskView;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic,assign) CGPoint startPoint;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, copy) void (^completionBlock)(BOOL didTap);

@end

static SystemSoundID soundID = 0;

@implementation SJCNotificationHUD

+ (SJCNotificationHUD *)showNotificationWithImage:(NSString *)imageName
                                    title:(NSString *)title
                                  message:(NSString *)message
                                 duration:(NSTimeInterval)duration
                            completeBlock:(void(^)(BOOL didTap))complete {
    
    UIView *banner = [self bannerViewWithImage:imageName title:title message:message];
    return [self showNotificationView:banner duration:duration completeBlock:complete];
}

+ (SJCNotificationHUD *)showNotificationSuccess:(NSString *)message {
    UIView *banner = [self bannerViewWithImage:@"hud_success" title:@"" message:message];
    return [self showNotificationView:banner duration:3 completeBlock:nil];
}

+ (SJCNotificationHUD *)showNotificationInfo:(NSString *)message {
    UIView *banner = [self bannerViewWithImage:@"hud_info" title:@"" message:message];
    return [self showNotificationView:banner duration:3 completeBlock:nil];
}

+ (SJCNotificationHUD *)showNotificationError:(NSString *)message {
    UIView *banner = [self bannerViewWithImage:@"hud_error" title:@"" message:message];
    return [self showNotificationView:banner duration:3 completeBlock:nil];
}

+ (SJCNotificationHUD *)showNotificationView:(UIView *)view
                            duration:(NSTimeInterval)duration
                       completeBlock:(void(^)(BOOL didTap))complete {
    if (view==nil || CGSizeEqualToSize(CGSizeZero, view.bounds.size)) return nil;
    SJCNotificationHUD *banner = [[SJCNotificationHUD alloc] initWithFrame:[UIScreen mainScreen].bounds];
    banner.duration = duration;
    banner.completionBlock = complete;
    [banner addView:view];
    [[UIApplication sharedApplication].keyWindow addSubview:banner];
    [banner show];
    return banner;
}

+ (UIView *)bannerViewWithImage:(NSString *)imageName
                          title:(NSString *)title
                        message:(NSString *)message {
    // sanity
    if (NotiIsEmpty(imageName)&&NotiIsEmpty(title)&&NotiIsEmpty(message)) return nil;
    
    // dynamically build a banner view with any combination of message, title, & image
    UIImageView *imageView = nil;
    UILabel *titleLabel = nil;
    UILabel *messageLabel = nil;
    
    UILabel *notiLabel = nil;
    UILabel *timeLabel = nil;
    
    //view容器
    UIView *wrapperView = [[UIView alloc] init];
    wrapperView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    wrapperView.backgroundColor = [[UIColor colorWithRed:248/255.0 green:248/255.0 blue:248/255.0 alpha:1] colorWithAlphaComponent:0.5];
    wrapperView.clipsToBounds = YES;
    wrapperView.layer.cornerRadius = 12;
    wrapperView.layer.masksToBounds = YES;
    
    //毛玻璃效果
    UIBlurEffect *blurEffrct =[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *backView = [[UIVisualEffectView alloc]initWithEffect:blurEffrct];
    backView.userInteractionEnabled = false;
    [wrapperView insertSubview:backView atIndex:0];
    
    //image
    if(imageName != nil) {
        imageView = [[UIImageView alloc] init];
        imageView.layer.cornerRadius = 5;
        imageView.layer.masksToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.frame = CGRectMake(horizontalPadding, verticalbannerPadding, imageSize.width, imageSize.height);
        if ([imageName isKindOfClass:[NSString class]]) {
            if ([imageName hasPrefix:@"http"]) {
#if NotiHasSDWebImage
                [imageView sd_setImageWithURL:[NSURL URLWithString:imageName] placeholderImage:[UIImage imageNamed:@"user_header"]];
#endif
            } else {
                UIImage *image = [UIImage imageNamed:imageName];
                if (!image) {
                    image = [UIImage imageWithContentsOfFile:imageName];
                }
                if (!image) {
                    image = [UIImage imageNamed:@"user_header"];
                }
                imageView.image = image;
            }
        }else if ([imageName isKindOfClass:[UIImage class]]) {
            imageView.image = (UIImage *)imageName;
        }else if ([imageName isKindOfClass:[NSURL class]]) {
#if NotiHasSDWebImage
            [imageView sd_setImageWithURL:(NSURL *)imageName placeholderImage:[UIImage imageNamed:@"user_header"]];
#endif
        }
    }
    
    CGRect imageRect = CGRectZero;
    
    if(imageView != nil) {
        imageRect.origin.x = horizontalPadding;
        imageRect.origin.y = verticalbannerPadding;
        imageRect.size.width = imageView.bounds.size.width;
        imageRect.size.height = imageView.bounds.size.height;
    }else{
        imageRect.origin.x = horizontalPadding;
        imageRect.origin.y = verticalbannerPadding;
    }
    
    if(imageView != nil) {
        notiLabel = [[UILabel alloc] init];
        notiLabel.numberOfLines = 1;
        notiLabel.font = [UIFont systemFontOfSize:11];
        notiLabel.textAlignment = NSTextAlignmentLeft;
        notiLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        notiLabel.textColor = [UIColor grayColor];
        notiLabel.backgroundColor = [UIColor clearColor];
        notiLabel.alpha = 1.0;
        notiLabel.text = @"NOTIFICATION";
        notiLabel.frame = CGRectMake(imageRect.origin.x+imageRect.size.width+horizontalPadding, imageRect.origin.y, (bannerW-horizontalPadding*2-(imageRect.size.width+horizontalPadding))*0.5, imageRect.size.height);
        
        timeLabel = [[UILabel alloc] init];
        timeLabel.numberOfLines = 1;
        timeLabel.font = [UIFont systemFontOfSize:11];
        timeLabel.textAlignment = NSTextAlignmentRight;
        timeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        timeLabel.textColor = [UIColor grayColor];
        timeLabel.backgroundColor = [UIColor clearColor];
        timeLabel.alpha = 1.0;
        timeLabel.text = @"NOW";
        timeLabel.frame = CGRectMake(bannerW-horizontalPadding-((bannerW-horizontalPadding*2-(imageRect.size.width+horizontalPadding))*0.5), imageRect.origin.y, (bannerW-horizontalPadding*2-(imageRect.size.width+horizontalPadding))*0.5, imageRect.size.height);
    }
    
    if (title != nil) {
        titleLabel = [[UILabel alloc] init];
        titleLabel.numberOfLines = 2;
        titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.alpha = 1.0;
        titleLabel.text = title;
        
        // size the title label according to the length of the text
        CGSize maxSizeTitle = CGSizeMake(bannerW-horizontalPadding*2, CGFLOAT_MAX);
        CGSize expectedSizeTitle = [titleLabel sizeThatFits:maxSizeTitle];
        // UILabel can return a size larger than the max size when the number of lines is 1
        expectedSizeTitle = CGSizeMake(MIN(maxSizeTitle.width, expectedSizeTitle.width), MIN(maxSizeTitle.height, expectedSizeTitle.height));
        titleLabel.frame = CGRectMake(0.0, 0.0, expectedSizeTitle.width, expectedSizeTitle.height);
    }
    
    if (message != nil) {
        messageLabel = [[UILabel alloc] init];
        messageLabel.numberOfLines = 2;
        messageLabel.font = [UIFont systemFontOfSize:13];
        messageLabel.textAlignment = NSTextAlignmentLeft;
        messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.alpha = 1.0;
        messageLabel.text = message;
        
        CGSize maxSizeMessage = CGSizeMake(bannerW-horizontalPadding*2, CGFLOAT_MAX);
        CGSize expectedSizeMessage = [messageLabel sizeThatFits:maxSizeMessage];
        // UILabel can return a size larger than the max size when the number of lines is 1
        expectedSizeMessage = CGSizeMake(MIN(maxSizeMessage.width, expectedSizeMessage.width), MIN(maxSizeMessage.height, expectedSizeMessage.height));
        messageLabel.frame = CGRectMake(0.0, 0.0, expectedSizeMessage.width, expectedSizeMessage.height);
    }
    
    CGRect titleRect = imageRect;
    
    if(titleLabel != nil) {
        titleRect.origin.x = horizontalPadding;
        titleRect.origin.y = imageRect.origin.y + imageRect.size.height + verticalPadding;
        titleRect.size.width = titleLabel.bounds.size.width;
        titleRect.size.height = titleLabel.bounds.size.height;
    }
    
    CGRect messageRect = titleRect;
    
    if(messageLabel != nil) {
        messageRect.origin.x = horizontalPadding;
        messageRect.origin.y = titleRect.origin.y + titleRect.size.height+(titleLabel?1:(imageView?verticalPadding:0));
        messageRect.size.width = messageLabel.bounds.size.width;
        messageRect.size.height = messageLabel.bounds.size.height;
    }
    
    CGFloat longerWidth = MAX(titleRect.size.width, messageRect.size.width);
    CGFloat longerX = MAX(titleRect.origin.x, messageRect.origin.x);
    
    CGFloat wrapperWidth = MAX((imageRect.size.width + (horizontalPadding * 2.0)), (longerX + longerWidth + horizontalPadding));
    wrapperWidth = MAX(bannerW, wrapperWidth);
    CGFloat wrapperHeight = messageRect.origin.y + messageRect.size.height + verticalbannerPadding;
    
    if(imageView != nil) {
        [wrapperView addSubview:imageView];
        [wrapperView addSubview:notiLabel];
        [wrapperView addSubview:timeLabel];
    }
    
    if(titleLabel != nil) {
        titleLabel.frame = titleRect;
        [wrapperView addSubview:titleLabel];
    }
    
    if(messageLabel != nil) {
        messageLabel.frame = messageRect;
        [wrapperView addSubview:messageLabel];
    }
    
    backView.frame = CGRectMake(0.0, 0.0, wrapperWidth, wrapperHeight);
    wrapperView.frame = CGRectMake(0.0, 0.0, wrapperWidth, wrapperHeight);
    
    return wrapperView;
}

- (void)addView:(UIView *)view {
    CGFloat viewW = view.bounds.size.width;
    CGFloat viewH = view.bounds.size.height;
    
    UIControl *banner = [[UIControl alloc] initWithFrame:CGRectMake(MAX((self.bounds.size.width-viewW)*0.5, 0), kStatusBarHeight, viewW, viewH)];
    view.frame = CGRectMake(0, 0, viewW, viewH);
    view.userInteractionEnabled = NO;
    [banner addSubview:view];
    
    [banner addTarget:self action:@selector(bannerTap) forControlEvents:UIControlEventTouchUpInside];
    [banner addTarget:self action:@selector(scaleToSmall:)
     forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [banner addTarget:self action:@selector(scaleToDefault:)
     forControlEvents:UIControlEventTouchDragExit];

    self.contentView.frame = CGRectMake(0, 0, self.bounds.size.width, viewH+kStatusBarHeight);
    [self.contentView addSubview:banner];
}

- (void)scaleToSmall:(UIControl *)banner {
    [UIView animateWithDuration:1.0
                     delay:0.0
    usingSpringWithDamping:0.8
     initialSpringVelocity:8.0
                   options:UIViewAnimationOptionAllowUserInteraction
                animations:^{
        self.contentView.transform = CGAffineTransformMakeScale(0.95f, 0.95f);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)scaleToDefault:(UIControl *)banner {
    [UIView animateWithDuration:1.0
                     delay:0.0
    usingSpringWithDamping:0.8
     initialSpringVelocity:8.0
                   options:UIViewAnimationOptionAllowUserInteraction
                animations:^{
        self.contentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    } completion:^(BOOL finished) {
        
    }];
}


//banner的初始化
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureReconClick:)];
        self.panGesture.delegate = self;
        self.panGesture.cancelsTouchesInView = NO;
        [self.contentView addGestureRecognizer:self.panGesture];
        
        [self addSubview:self.maskView];
        [self addSubview:self.contentView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void)panGestureReconClick:(UIPanGestureRecognizer *)panGesture {
    CGPoint p = [panGesture translationInView:self.contentView];
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:
            [self invalidateTimer];
            //注意完成移动后，将translation重置为0十分重要。否则translation每次都会叠加
            [panGesture setTranslation:CGPointZero inView:self.maskView];
            //保存触摸起始点位置
            self.startPoint = [panGesture translationInView:self.contentView];
            break;
        case UIGestureRecognizerStateChanged: {
            
            CGFloat boundary = panGesture.view.bounds.size.height;
            if ((CGRectGetMinY(panGesture.view.frame) + panGesture.view.bounds.size.height + p.y) < boundary) {
                panGesture.view.center = CGPointMake(panGesture.view.center.x, panGesture.view.center.y + p.y);
            } else {
                //给他少量位移，给人弹性的效果，上限60
                CGFloat distance = p.y * 0.15;
                if (distance > 60) {
                    distance = 60;
                }
                
                //限制向下拖动最大距离，避免无限拖动,增大阻尼效果，也不是让他停止不动
                //后续在这个地方变换UI，类似于系统通知，下拉可以展示全部内容
                if (panGesture.view.frame.origin.y < self.contentView.bounds.size.height / 2) {
                    panGesture.view.center = CGPointMake(panGesture.view.center.x, panGesture.view.center.y + distance);
                }else{
                    panGesture.view.center = CGPointMake(panGesture.view.center.x, panGesture.view.center.y + p.y * 0.08);
                }
                //panGesture.view.center = self.finalCentr;
            }
            [panGesture setTranslation:CGPointZero inView:self.maskView];
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
            
            BOOL isDismissNeeded = - self.contentView.frame.origin.y > self.contentView.frame.size.height * 0.2;//拖动一半比例就消失
            if (isDismissNeeded) {
                [self dismiss];
            }else{
                [self setupTimer];
                [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.maskView.alpha = 1;
                    panGesture.view.center = self.finalCentr;
                } completion:NULL];
            }
    }
    
        case UIGestureRecognizerStatePossible:
            
            break;
    }
    
}

- (CGPoint)finalCentr {
    return CGPointMake(self.maskView.center.x,
                       self.contentView.bounds.size.height / 2);
}

- (void)deviceOrientationChanged:(NSNotification *)notify {
    [self dismiss];
}

- (void)show {
    [self sound];
    [self impact];
    CGRect frame = self.contentView.frame;
    frame.origin.y = -self.contentView.frame.size.height;
    self.contentView.frame = frame;
    [UIView animateWithDuration:1.0
                     delay:0.0
    usingSpringWithDamping:0.8
     initialSpringVelocity:8.0
                   options:UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionAllowUserInteraction
                animations:^{
        CGRect frame = self.contentView.frame;
        frame.origin.y = 0;
        self.contentView.frame = frame;
    } completion:^(BOOL finished) {
        [self setupTimer];
    }];
}


- (void)sound {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"yehwangsound.caf" withExtension:nil];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url), &soundID);
    AudioServicesPlayAlertSoundWithCompletion(soundID, ^{});
}

- (void)impact {
    if (@available(iOS 10.0, *)) {
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    } else {
        AudioServicesPlaySystemSound(1519);
    }
}

//瑕疵，会重新开始从3倒计时，不会保留之前已经倒过的时间
- (void)setupTimer {
    [self invalidateTimer];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.duration?:3 target:self selector:@selector(bannerTimerDidFinish:) userInfo:nil repeats:YES];
    _timer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)invalidateTimer {
    if (self.timer&&self.timer.isValid) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)bannerTap {
    [self dismissFromTap:YES];
}

- (void)bannerTimerDidFinish:(NSTimer *)timer {
    [self dismiss];
}

- (void)dismiss {
    [self dismissFromTap:NO];
}

- (void)dismissFromTap:(BOOL)tap {
    if (tap) {
        [UIView animateWithDuration:0.15
                              delay:0
                            options:(7 << 16)
                         animations:^{
            self.contentView.alpha = 0.0;
            self.contentView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                         } completion:^(BOOL finished) {
                             !_completionBlock ? : _completionBlock(tap);
                             [self invalidateTimer];
                             [self removeFromSuperview];
                         }];
    }else{
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            CGRect frame = self.contentView.frame;
            frame.origin.y = -self.contentView.frame.size.height;
            self.contentView.frame = frame;
        } completion:^(BOOL finished) {
            !_completionBlock ? : _completionBlock(tap);
            [self invalidateTimer];
            [self removeFromSuperview];
        }];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return ![touch.view isDescendantOfView:self.contentView];
    }
    return YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.bounds];
        _maskView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        tap.delegate = self;
        [_maskView addGestureRecognizer:tap];
    }
    return _maskView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, bannerH+kStatusBarHeight)];
    }
    return _contentView;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == _maskView) {
        return nil;//允许透明蒙版后面可以交互
    }
    return view;
}

- (void)dealloc {
    
}

@end

