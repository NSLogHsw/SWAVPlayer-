//
//  ViewController.m
//  SWAVPlayer
//
//  Created by  677676  on 16/10/24.
//  Copyright © 2016年 艾腾软件.SW. All rights reserved.
//

#import "ViewController.h"
#import "PlayView.h"
#import "Masonry.h"

#import <AVFoundation/AVFoundation.h>

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
#define PlayerWidth  MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
#define PlayerHeight (PlayerWidth * (9.0 / 16.0))

#define WS(weakSelf) __weak __typeof(&*self)weakSelf = self;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBarHidden = YES;
    NSString * filePath = @"http://192.168.1.150:8080/static/video/1455782903700jy.mp4";
    PlayView * view = [[PlayView alloc]initWithFrame:CGRectZero WithVideoStr:filePath];
    view.titleName = @"播放器";
    [self.view addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(0);
        make.right.offset(0);
        make.top.offset(64);
        make.height.offset(200);
    }];
   WS(weakSelf)
    view.goBackBlock = ^(){
        [weakSelf.navigationController popViewControllerAnimated:YES];
    };
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
