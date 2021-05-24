//
//  SJCNotificationHUD.h
//  Yehwang
//
//  Created by Yehwang on 2020/11/3.
//  Copyright © 2020 Yehwang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SJCNotificationHUD : UIView


/// showNotification
/// @param image image
/// @param title title
/// @param message message
/// @param duration duration
/// @param complete complete
+ (SJCNotificationHUD *)showNotificationWithImage:(NSString *)image
                                    title:(NSString *)title
                                  message:(NSString *)message
                                 duration:(NSTimeInterval)duration
                            completeBlock:(void(^)(BOOL didTap))complete;

/// Success
/// @param message message
+ (SJCNotificationHUD *)showNotificationSuccess:(NSString *)message;

/// Info
/// @param message message
+ (SJCNotificationHUD *)showNotificationInfo:(NSString *)message;

/// Error
/// @param message message
+ (SJCNotificationHUD *)showNotificationError:(NSString *)message;

/// showNotificationView
/// @param view view
/// @param duration duration
/// @param complete complete
+ (SJCNotificationHUD *)showNotificationView:(UIView *)view
                            duration:(NSTimeInterval)duration
                       completeBlock:(void(^)(BOOL didTap))complete;

@end

