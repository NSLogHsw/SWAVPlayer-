//
//  PlayView.m
//  AVplayer_self
//
//  Created by vicnic on 16/6/5.
//  Copyright © 2016年 vicnic. All rights reserved.
//

#import "PlayView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#define PlayerWidth  MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
#define PlayerHeight (PlayerWidth * (11.0 / 16.0))

@interface PlayView()
{
    AVPlayerLayer * playerLayer;
    UIButton * _fullScreenBtn , *_playBtn,*_backBtn;
}
@property(nonatomic,retain)PlayView * view;
@property(nonatomic , strong)AVPlayer * player;
@property(nonatomic , strong)UIView * bottom;
@property(nonatomic,retain)UIView * headView;
@property(nonatomic , strong)AVPlayerItem * playerItem;
@property(nonatomic , strong)UISlider * slider;
@property(nonatomic,retain)AVPlayerLayer * playerLayer;
@property(nonatomic,retain)UIProgressView * progressView;
//是否是用户按了暂停播放按钮
@property(nonatomic,assign)BOOL isPauseByUser;
//菊花
@property(nonatomic,retain)UIActivityIndicatorView * activity;
//快进快退显示进度
@property(nonatomic,retain)UILabel * notificationLabel;
//是否在调节音量
@property (nonatomic, assign) BOOL isVolume;
@property (nonatomic, strong) UISlider * volumeViewSlider;
//是否横向滑动
@property (nonatomic, assign) BOOL isHorizon;
//是否纵向滑动
@property (nonatomic, assign) BOOL isVertical;
//是否全屏
@property (nonatomic,assign) BOOL isFullScreen;
//标题标签
@property(nonatomic,retain)UILabel * titleLabel;
//时长标签
@property(nonatomic,retain)UILabel * timeLabel;

@end
@implementation PlayView

-(id)initWithFrame:(CGRect)frame WithVideoStr:(NSString *)videoStr
{
    self = [super init];
    if(self)
    {
        self.frame = frame;
        NSURL * sourceMoveUrl = [NSURL URLWithString:videoStr];
        //AVAsset：主要用于获取多媒体信息，是一个抽象类，不能直接使用。AVURLAsset：AVAsset的子类，可以根据一个URL路径创建一个包含媒体信息的AVURLAsset对象。
        AVAsset * movieAsset = [AVURLAsset URLAssetWithURL:sourceMoveUrl options:nil];
        //AVPlayerItem：一个媒体资源管理对象，管理视频的一些基本信息和状态，一个AVPlayerItem对应着一个视频资源
        self.playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.frame = self.layer.bounds;
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.layer addSublayer:self.playerLayer];
        [self.player play];
//        播放栏
        self.bottom = [[UIView alloc]init];
        self.bottom.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        [self addSubview:self.bottom];
//        headView
        self.headView = [[UIView alloc]init];
        self.headView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        [self addSubview:self.headView];
        _backBtn = [[UIButton alloc]initWithFrame:CGRectMake(5, 5, 50, 30)];
        [_backBtn setImage:[UIImage imageNamed:@"Player_后退"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [self.headView addSubview:_backBtn];
        
        self.titleLabel = [[UILabel alloc]init];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [self.headView addSubview:self.titleLabel];
        
        _playBtn = [[UIButton alloc]initWithFrame:CGRectMake(5, 5, 30, 30)];
        [_playBtn addTarget:self action:@selector(PlayOrPause) forControlEvents:UIControlEventTouchUpInside];
        [_playBtn setImage:[UIImage imageNamed:@"MoviePlayer_Play_Big"] forState:UIControlStateNormal];
        [self.bottom addSubview:_playBtn];
        
        self.slider = [[UISlider alloc]init];
        self.slider.minimumValue = 0.0;
        self.slider.maximumValue = CMTimeGetSeconds(movieAsset.duration);
        self.slider.value = 0.0;
        self.slider.minimumTrackTintColor = [UIColor whiteColor];
        self.slider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        [self.slider setThumbImage:[UIImage imageNamed:@"MoviePlayer_Slider"] forState:UIControlStateNormal];
        [self.slider addTarget:self action:@selector(updateValue:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottom addSubview:self.slider];
        
        self.progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.progressView.progressTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        self.progressView.trackTintColor = [UIColor clearColor];
        [self.bottom addSubview:self.progressView];
        
        self.timeLabel = [[UILabel alloc]init];
        self.timeLabel.textColor = [UIColor whiteColor];
        self.timeLabel.font = [UIFont systemFontOfSize:12.0];
        [self.bottom addSubview:self.timeLabel];
        
        _fullScreenBtn = [[UIButton alloc]init];
        [_fullScreenBtn setImage:[UIImage imageNamed:@"MoviePlayer_Full"] forState:UIControlStateNormal];
        [_fullScreenBtn addTarget:self action:@selector(fullScreenClick:) forControlEvents:UIControlEventTouchUpInside];
        _fullScreenBtn.selected = NO;
        [self.bottom addSubview:_fullScreenBtn];
//        手势区域
        UITapGestureRecognizer * singleRecongnizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleSingleTapFrom)];
        singleRecongnizer.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleRecongnizer];
        
        UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panClick:)];
        [self addGestureRecognizer:pan];
        
        // 获取系统音量
        [self configureVolume];
        //播放是否结束监测
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
//        缓冲区空了，需要等待数据
        [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
//        缓冲区有足够数据可以播放了
        [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
//        监听设备旋转
        [[UIDevice currentDevice]beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
        // app退到后台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
        // app进入前台
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
        [self initScrubberTimer];
        [self performSelector:@selector(setBottomToClearColor) withObject:nil afterDelay:5];
        _isFullScreen = NO;//初始化默认竖屏
    }
    return self;
}
-(void)layoutSubviews
{
    [super layoutSubviews];
    //self的frame也要适配，否则按钮就会因为超出self范围而失效
    self.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.width*9/16.0);
    self.playerLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.width*9/16.0);
    self.bottom.frame = CGRectMake(0, self.bounds.size.width*9/16.0-40, self.bounds.size.width, 40);
    self.headView.frame = CGRectMake(0, 0, self.bounds.size.width, 40);
    self.titleLabel.text = self.titleName;
    self.slider.frame = CGRectMake(_playBtn.frame.origin.x +_playBtn.frame.size.width, _playBtn.frame.origin.y, self.frame.size.width-2*(_playBtn.frame.origin.x +_playBtn.frame.size.width)-80, _playBtn.frame.size.height);
    self.titleLabel.frame = CGRectMake(_backBtn.frame.origin.x+_backBtn.frame.size.width, _backBtn.frame.origin.y, self.bounds.size.width/2-_backBtn.frame.origin.x-_backBtn.frame.size.width, _backBtn.frame.size.height);
    //progressView这些数字是微调的结果，是为了让其覆盖slider，单纯匹配坐标没有用，减80是因为显示播放时长的timeLabel的宽度是80
    self.progressView.frame = CGRectMake(self.slider.frame.origin.x+2, _playBtn.frame.origin.y+self.slider.frame.size.height/2-1, self.frame.size.width-2*(_playBtn.frame.origin.x +_playBtn.frame.size.width)-4-80, _playBtn.frame.size.height);
    self.timeLabel.frame = CGRectMake(self.progressView.frame.origin.x+self.progressView.frame.size.width, self.slider.frame.origin.y,80, _playBtn.frame.size.height);
    _fullScreenBtn.frame = CGRectMake(self.timeLabel.frame.origin.x+self.timeLabel.frame.size.width+5, self.slider.frame.origin.y, _playBtn.frame.size.width-5, _playBtn.frame.size.height);
    self.notificationLabel.frame = CGRectMake(self.center.x -50, self.center.y-30, 100, 60);
}

-(double)duration
{
    AVPlayerItem * playerItem = [self.player currentItem];
    if([playerItem status]==AVPlayerItemStatusReadyToPlay)
    {
        //CMTimeGetSeconds函数获取时间的秒数
        return  CMTimeGetSeconds([[playerItem asset]duration]);
    }
    else
        return 0.f;
}

-(double)currentTime
{
    return CMTimeGetSeconds([self.player currentTime]);
}

-(void)setCurrentTime:(double)time
{
    //CMTimeMakeWithSeconds(timeBySecond, 10);CMTime是表示电影时间信息的结构体,第一个参数表示是视频第几秒,第二个参数表示每秒帧数
    [[self player]seekToTime:CMTimeMakeWithSeconds(time, 1)];
}
- (UIActivityIndicatorView *)activity
{
    if (!_activity) {
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activity.frame = CGRectMake(self.center.x-15, self.center.y-15, 30, 30);
    }
    return _activity;
}
-(UILabel*)notificationLabel
{
    if (!_notificationLabel) {
        _notificationLabel = [[UILabel alloc]init];
        _notificationLabel.textColor = [UIColor whiteColor];
        _notificationLabel.font = [UIFont systemFontOfSize:14.0];
        _notificationLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _notificationLabel;
}
#pragma mark - 手势方法&按钮集群
-(void)handleSingleTapFrom
{
    [UIView animateWithDuration:0.5 animations:^{
        if (self.bottom.alpha == 0.0) {
            self.bottom.alpha = 1.0;
            self.headView.alpha = 1.0;
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }else{
            self.bottom.alpha = 0.0;
            self.headView.alpha = 0.0;
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }
    } completion:^(BOOL finish){
         [self performSelector:@selector(setBottomToClearColor) withObject:nil afterDelay:5];
    }];
}
-(void)panClick:(UIPanGestureRecognizer*)pan
{
    CGPoint veloctyPoint = [pan velocityInView:self];
    CGPoint locationPoint = [pan locationInView:self];
    if (pan.state == UIGestureRecognizerStateBegan) {
        CGFloat x = fabs(veloctyPoint.x);
        CGFloat y = fabs(veloctyPoint.y);
        if (x>y) {
            [[self player]pause];
            self.isHorizon = YES;
            self.isVertical = NO;
        }
        else if (x<y)
        {
            self.isHorizon = NO;
            self.isVertical = YES;
            if (locationPoint.x>self.bounds.size.width/2) {
                //右侧垂直手势，调节音量
                self.isVolume = YES;
            }
            else//左侧垂直手势，调节亮度
            {
                self.isVolume = NO;
            }
        }
    }
    if (pan.state == UIGestureRecognizerStateChanged) {
        if (_isHorizon) {//水平滑动,快进快退
            self.slider.value = self.slider.value + veloctyPoint.x/200;
            [self updateValue:self.slider];
            if (_playerItem.duration.timescale != 0) {
                //当前分钟
                NSInteger proMin = (NSInteger)CMTimeGetSeconds([self.player currentTime])/60;
                //当前秒
                NSInteger proSec = (NSInteger)CMTimeGetSeconds([self.player currentTime])%60;
                //duration 总时长
                NSInteger durMin = (NSInteger)_playerItem.duration.value / _playerItem.duration.timescale / 60;//总分钟
                NSInteger durSec = (NSInteger)_playerItem.duration.value / _playerItem.duration.timescale % 60;//总秒
                [self addSubview:self.notificationLabel];
                self.notificationLabel.text = [NSString stringWithFormat:@"%02zd:%02zd/%02zd:%02zd", proMin, proSec,durMin, durSec];
            }
        }
        else if (_isVertical)//垂直移动，改变音量和亮度
        {
            [self verticalMoved:veloctyPoint.y];
        }
    }
    if (pan.state == UIGestureRecognizerStateEnded) {
        if (_isPauseByUser == NO) {
            [[self player]play];
        }
        [self.notificationLabel removeFromSuperview];
    }
}

-(void)setBottomToClearColor
{
    [UIView animateWithDuration:0.5 animations:^{
        self.bottom.alpha = 0.0;
        self.headView.alpha = 0.0;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    } completion:^(BOOL finish){
    }];
}

-(void)fullScreenClick:(UIButton*)sender
{
    sender.selected = !sender.selected;
    if (sender.selected == YES) {
//        全屏
        if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
            SEL selector = NSSelectorFromString(@"setOrientation:");
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:[UIDevice currentDevice]];
            int val = UIInterfaceOrientationLandscapeRight;
            [invocation setArgument:&val atIndex:2];
            [invocation invoke];
            UIDeviceOrientation orientation = self.getDeviceOrientation;
            switch (orientation) {
                case UIDeviceOrientationPortrait: {
//                    NSLog(@"home键在 下");
                    [self restoreOriginalScreen];
                }
                    break;
                case UIDeviceOrientationPortraitUpsideDown: {
//                    NSLog(@"home键在 上");
                }
                    break;
                case UIDeviceOrientationLandscapeLeft: {
//                    NSLog(@"home键在 右");
                    [self changeToFullScreenForOrientation:UIDeviceOrientationLandscapeLeft];
                }
                    break;
                case UIDeviceOrientationLandscapeRight: {    
//                    NSLog(@"home键在 左");
                    [self changeToFullScreenForOrientation:UIDeviceOrientationLandscapeRight];
                }
                    break;
                    
                default:
                    break;
            }
        }
    }
    else
    {
        [self fullScreenToPortraid];        
    }
}
- (UIDeviceOrientation)getDeviceOrientation
{
    return [UIDevice currentDevice].orientation;
}
// 切换到竖屏模式
- (void)restoreOriginalScreen
{
    self.frame = CGRectMake(0, 0, PlayerWidth, PlayerHeight);
}
//横屏模式
- (void)changeToFullScreenForOrientation:(UIDeviceOrientation)orientation
{
    self.playerLayer.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, PlayerWidth);
}
-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self.playerLayer setFrame:frame];
}
-(void)PlayOrPause
{
    //1.0表示正在播放，0.0表示暂停
    if([[self player]rate]!=1.f)
    {
        //如果当前时间等于已经播放的时间，就继续播放
        if([self currentTime]==[self duration])
        {
            [self setCurrentTime:0.f];
        }
        [[self player]play];
        [_playBtn setImage:[UIImage imageNamed:@"MoviePlayer_Play_Big"] forState:UIControlStateNormal];
        _isPauseByUser = NO;
    }
    else
    {
        [[self player]pause];
        [_playBtn setImage:[UIImage imageNamed:@"MoviePlayer_Stop_Big"] forState:UIControlStateNormal];
        _isPauseByUser = YES;
    }
    //    CMTime time = [self.player currentTime];
    //    NSLog(@"%lld",self.playerItem.duration.value/self.playerItem.duration.timescale);
    //    NSLog(@"%lld",time.value/time.timescale);
}
- (void)configureVolume
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    self.volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            self.volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) { /* handle the error in setCategoryError */ }
    
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}
// 耳机插入、拔出事件
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机插入
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            // 耳机拔掉继续播放
            [[self player]play];
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
//            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}
- (void)verticalMoved:(CGFloat)value
{
    if (self.isVolume) {
        self.volumeViewSlider.value -= value / 10000;
    }
    else
    {
        [UIScreen mainScreen].brightness -= value / 10000;
    }
}
- (void)moviePlayDidEnd:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self player]pause];
    self.slider.value = 0.0;
    [_playBtn setImage:[UIImage imageNamed:@"MoviePlayer_Stop_Big"] forState:UIControlStateNormal];
}
-(void)backBtnClick
{
    if (_isFullScreen) {
        //全屏
        [_playBtn setImage:[UIImage imageNamed:@"MoviePlayer_Stop_Big"] forState:UIControlStateNormal];
        
        [[self player]pause];
        [self fullScreenToPortraid];
    }
    else
    {
        if (self.goBackBlock) {
            [[self player]pause];
            [self.playerLayer removeFromSuperlayer];
            [self.player replaceCurrentItemWithPlayerItem:nil];
            self.player = nil;
            [self removeFromSuperview];
            self.goBackBlock();
        }
    }
}
-(void)fullScreenToPortraid
{
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = UIInterfaceOrientationPortrait;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

//监听设备选择后调用的方法
-(void)onDeviceOrientationChange
{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown://home键在上
            _isFullScreen = NO;
            break;
        case UIInterfaceOrientationPortrait://home键在下
            _isFullScreen = NO;
            break;
        case UIInterfaceOrientationLandscapeLeft://home键在右
            _isFullScreen = YES;
            break;
        case UIInterfaceOrientationLandscapeRight://home键在左
            _isFullScreen = YES;
            break;
            
        default:
            break;
    }
    _isFullScreen ? [_fullScreenBtn setImage:[UIImage imageNamed:@"MoviePlayer_小屏"] forState:UIControlStateNormal]:[_fullScreenBtn setImage:[UIImage imageNamed:@"MoviePlayer_Full"] forState:UIControlStateNormal];
}
//应用进入后台
- (void)appDidEnterBackground
{
    [[self player]pause];
    [_playBtn setImage:[UIImage imageNamed:@"MoviePlayer_Stop_Big"] forState:UIControlStateNormal];
}
//应用进入前台
- (void)appDidEnterPlayGround
{
    [[self player]play];
    [_playBtn setImage:[UIImage imageNamed:@"MoviePlayer_Play_Big"] forState:UIControlStateNormal];
}

#pragma mark - slider
-(void)updateValue:(UISlider*)slider
{
    //跳到某个时间，即根据slider更新视频的进度，转换成CMTime才能给player来控制播放进度
    [self.player seekToTime:CMTimeMakeWithSeconds(slider.value, 1)];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    //AVPlayerItem "status" 属性值观察者
    if (object == self.player.currentItem) {
        if ([keyPath isEqualToString:@"status"]) {
            if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
                [self initScrubberTimer];
            }
            else if (self.player.currentItem.status == AVPlayerItemStatusFailed)
            {
                //加载失败
                [UIView animateWithDuration:2 animations:^{
                    self.notificationLabel.text = @"加载失败";
                } completion:^(BOOL finished) {
                    [self.notificationLabel removeFromSuperview];
                }];
            }
        }
        else if ([keyPath isEqualToString:@"loadedTimeRanges"])
        {
            //计算缓冲进度
            NSTimeInterval timeInterval = [self availableDuration];
            CMTime duration             = self.playerItem.duration;
            CGFloat totalDuration       = CMTimeGetSeconds(duration);
            [self.progressView setProgress:timeInterval/totalDuration animated:NO];
            // 如果缓冲和当前slider的差值超过0.1,自动播放，解决弱网情况下不会自动播放问题
            if (self.progressView.progress - self.slider.value >0.05) {
                [[self player]play];
            }
        }
        else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
        {
            //当缓冲为空
            if (self.playerItem.playbackBufferEmpty) {
                [self addSubview:self.activity];
                [self.activity startAnimating];
                [self bufferingSomeSecond];
            }
        }
        else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
        {
            //缓冲好的时候
            [self.activity stopAnimating];
            [self.activity removeFromSuperview];
        }
    }
}
#pragma  mark - 监听
-(void)initScrubberTimer
{
    double interval = .1f;
    //得到播放过程的所经历的时间
    CMTime playerDuration = [self playerItemDuration];
    if(CMTIME_IS_INVALID(playerDuration))
    {
        return;
    }
    //将时间转化为秒
    double duration = CMTimeGetSeconds(playerDuration);
    if(isfinite(duration))//如果时间是有界的，若无界即表示视频没开始或结束
    {
        CGFloat width = CGRectGetWidth([self.slider bounds]);
        interval = 0.5f * duration/width;//不明白为什么要改变取样间隔
    }
//    NSLog(@"interva === %f",interval);
    __weak typeof (self) weakSelf = self;
    //在正常的playback跟新scrubber（刷子）,如果是NULL，主线程会被使用
    [weakSelf.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        [self syncScrubber];
    }];
}
//设置scrubber（刷新）基于player当前时间
-(void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if(CMTIME_IS_INVALID(playerDuration))
    {
        self.slider.minimumValue = 0.0;
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        float minValue = [self.slider minimumValue];
        float maxValue = [self.slider maximumValue];
        double time = CMTimeGetSeconds([self.player currentTime]);
        //设置slider的进度，随时更新
        [self.slider setValue:(maxValue - minValue) * time / duration + minValue];
        //当前分钟
        NSInteger proMin = (NSInteger)CMTimeGetSeconds([self.player currentTime])/60;
        //当前秒
        NSInteger proSec = (NSInteger)CMTimeGetSeconds([self.player currentTime])%60;
        //duration 总时长
        NSInteger durMin = (NSInteger)self.playerItem.duration.value / self.playerItem.duration.timescale / 60;//总分钟
        NSInteger durSec = (NSInteger)self.playerItem.duration.value / self.playerItem.duration.timescale % 60;//总秒
        self.timeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd/%02zd:%02zd", proMin, proSec,durMin, durSec];
    }
}

- (CMTime)playerItemDuration
{
    AVPlayerItem *playerItem = [self.player currentItem];
//    NSLog(@"%ld",playerItem.status);
    if (playerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        return([playerItem duration]);
    }
    return(kCMTimeInvalid);
}

#pragma mark 缓冲区
// 计算缓冲进度
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}
//缓冲较差时候回调这里
- (void)bufferingSomeSecond
{
    __block BOOL isBuffing = YES;
    [[self player]pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (self.isPauseByUser) {
            isBuffing = NO;
            return ;
        }
        [[self player]play];
        isBuffing = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
    });
}

@end
