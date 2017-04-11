//
//  PlayView.h
//  AVplayer_self
//
//  Created by vicnic on 16/6/5.
//  Copyright © 2016年 vicnic. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^MyGoBackBlock) (void);
@interface PlayView : UIView
//传入的视频标题
@property(nonatomic,copy)NSString * titleName;
//返回按钮Block
@property (nonatomic,copy) MyGoBackBlock  goBackBlock;

-(id)initWithFrame:(CGRect)frame WithVideoStr:(NSString*)videoStr;
@end
