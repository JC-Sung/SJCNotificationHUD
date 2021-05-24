//
//  ViewController.m
//  SJCNotificationHUD
//
//  Created by Yehwang on 2021/5/24.
//

#import "ViewController.h"
#import "SJCNotificationHUD.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)show:(id)sender {
    [SJCNotificationHUD showNotificationWithImage:@"header" title:@"老婆" message:@"晚上啥时候回来？记得买点酱油，家里的酱油用完了。我晚上做了好吃的😍" duration:5.5 completeBlock:^(BOOL didTap) {
        
    }];
}
- (IBAction)success:(id)sender {
    [SJCNotificationHUD showNotificationSuccess:@"设置头像成功"];
}
- (IBAction)error:(id)sender {
    [SJCNotificationHUD showNotificationError:@"设置头像失败！！！"];
}
- (IBAction)info:(id)sender {
    [SJCNotificationHUD showNotificationInfo:@"头像不能为空哟~~~"];
}

@end
