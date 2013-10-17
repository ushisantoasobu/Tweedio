//
//  MainViewController.m
//  Tweedio
//
//  Created by shunsuke sato on 2013/10/07.
//  Copyright (c) 2013年 shunsuke sato. All rights reserved.
//

#import "MainViewController.h"
#import "TweetUtil.h"
#import <AudioToolbox/AudioToolbox.h>

@interface MainViewController ()


//ツイート情報のリスト
@property (nonatomic, strong) NSMutableArray *tweedDataList;

//現在のインデックス
@property (nonatomic) NSInteger currentIndex;

//ページインデックス
@property (nonatomic) NSInteger pageIndex;

typedef enum TweetPlayPart:NSInteger {
    TWEET_PLAY_PART_USER,
    TWEET_PLAY_PART_BODY,
    TWEET_PLAY_EMPTY,
    TWEET_PLAY_EMPTY_NEXT_USER
} TweetPlayPart;

//現在のツイート読み上げ箇所
@property (nonatomic) TweetPlayPart currentTweetplayPart;



//設定データモデル
@property (nonatomic, strong) SettingData *settingData;


//読み上げモジュール
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;

//設定ビュー
@property (nonatomic, weak) SettingViewController *svc;

//サウンド
//@property (nonatomic, strong) SystemSoundID *sound;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *ai;

@property (weak, nonatomic) IBOutlet UISegmentedControl *psc;

@property (weak, nonatomic) IBOutlet UISlider *sl;




@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //test
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    self.settingData = [[SettingData alloc] init];
    [TwitterManager sharedManager].delegate = self;
    self.synthesizer.delegate = self;
    //test
    
    [self reset];
    
    [[TwitterManager sharedManager] isAuthenticated];
    [self showLoading];
    [[TwitterManager sharedManager] requestTimeline:0];
    
    SettingData *data = [SettingDataManager getData];
    self.settingData = data;
    if (data.rate == AVSpeechUtteranceMaximumSpeechRate) {
        [self.psc setSelectedSegmentIndex:2];
    } else if (data.rate == AVSpeechUtteranceDefaultSpeechRate) {
        [self.psc setSelectedSegmentIndex:1];
    } else {
        [self.psc setSelectedSegmentIndex:0];
    }
    
    self.sl.value = data.pitchMultiplier;
    
    return;
    
    BOOL isAuthenticated = [[TwitterManager sharedManager] isAuthenticated];
    if (isAuthenticated == NO) {
        //アラート画面表示
    } else {
        
        [self reset];
        
        SettingData *data = [SettingDataManager getData];
        if(data == nil){
            self.settingData = [[SettingData alloc] init];
        }
        
//        [[TwitterManager sharedManager] requestTimeline:0];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - IBAction

- (IBAction)respondToBtnUpdate:(id)sender {
    
    //もし音が鳴っていたら止める
    [self stop];
    
    //各種データ初期化
    [self reset];
    
    //test
    
//    [[TwitterManager sharedManager] isAuthenticated];
    [self showLoading];
    [[TwitterManager sharedManager] requestTimeline:0];
}

- (IBAction)respondToBtnBack:(id)sender {
    [self back];
}

- (IBAction)respondToBtnNext:(id)sender {
    if([self.tweedDataList count] == 0){
        return;
    }
    
    if(self.currentIndex == [self.tweedDataList count] - 1){
        return;
    }
    
    self.currentIndex++;
    self.currentTweetplayPart = TWEET_PLAY_EMPTY_NEXT_USER;
    
    //なんかとまらなかったので強引な方法？？記事も見つからず・・・
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:nil];
    [utterance setRate              :self.settingData.rate];
    [utterance setPitchMultiplier   :self.settingData.pitchMultiplier];
    AVSpeechSynthesisVoice *voice = [[AVSpeechSynthesisVoice alloc] init];
    [utterance setVoice:voice];
    [self.synthesizer speakUtterance:utterance];
    //
    
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

- (IBAction)respondToBtnFavorite:(id)sender {
    [self favorite];
}

- (IBAction)respondToBtnStop:(id)sender {
    [self stop];
}

- (IBAction)respondToBtnPlay:(id)sender {
    [self play];
}


#pragma mark - data

- (void)reset {
    self.tweedDataList = [NSMutableArray array];
    self.currentIndex = 0;
    self.currentTweetplayPart = TWEET_PLAY_PART_USER;
}

#pragma mark - sound

- (void)ring {
    
    SystemSoundID sound;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Warp1" ofType:@"caf"];
    NSURL *url = [NSURL fileURLWithPath:path];
    
    //以下なにやってるの？？　＞＜
    AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain(url), &sound);
    
    // サウンドの再生
    AudioServicesPlaySystemSound(sound);
}

- (void)ringComplte {
    
    SystemSoundID sound;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"voice_of_light" ofType:@"caf"];
    NSURL *url = [NSURL fileURLWithPath:path];
    
    //以下なにやってるの？？　＞＜
    AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain(url), &sound);
    
    // サウンドの再生
    AudioServicesPlaySystemSound(sound);
}

#pragma mark - operation

//再生する
- (void)play {
    
    if (self.tweedDataList == nil || [self.tweedDataList count] == 0) {
        return;
    }
    
    TweetData *data = [self.tweedDataList objectAtIndex:self.currentIndex];
    
    NSString *str = self.currentTweetplayPart == TWEET_PLAY_PART_USER ? data.username : data.body;
    NSString *generatedTweet = [TweetUtil replaceForHearing:str];
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:generatedTweet];

    //各種設定
    [utterance setRate              :self.settingData.rate];
    [utterance setPitchMultiplier   :self.settingData.pitchMultiplier];
    
    AVSpeechSynthesisVoice *voice = [[AVSpeechSynthesisVoice alloc] init];
    [utterance setVoice:voice];
    
    [self.synthesizer speakUtterance:utterance];
}

//停止する
- (void)stop {
    if([self.synthesizer isSpeaking]) {
        
        self.currentTweetplayPart = TWEET_PLAY_EMPTY;
        
        //なんかとまらなかったので強引な方法？？記事も見つからず・・・
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:nil];
        [utterance setRate              :self.settingData.rate];
        [utterance setPitchMultiplier   :self.settingData.pitchMultiplier];
        AVSpeechSynthesisVoice *voice = [[AVSpeechSynthesisVoice alloc] init];
        [utterance setVoice:voice];
        [self.synthesizer speakUtterance:utterance];
        //
        
        [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
}

//前へ
- (void)back {
    
    if([self.tweedDataList count] == 0){
        return;
    }
    
    if(self.currentIndex == 0){
        return;
    }
    
    [self stop];
    self.currentIndex--;
    
    [NSThread sleepForTimeInterval:0.4f];
    [self ring];
    [NSThread sleepForTimeInterval:1.4f];
    
    self.currentTweetplayPart = TWEET_PLAY_PART_USER;
    [self play];
}

//次へ
- (void)next {
    
    if([self.tweedDataList count] == 0){
        return;
    }
    
    if(self.currentIndex == [self.tweedDataList count] - 1){
        return;
    }
    
    self.currentIndex++;
    [self stop];
    
    [NSThread sleepForTimeInterval:0.4f];
    [self ring];
    [NSThread sleepForTimeInterval:1.4f];
    
    self.currentTweetplayPart = TWEET_PLAY_PART_USER;
    [self play];
}


- (IBAction)changeSpeed:(id)sender {
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    NSInteger index = seg.selectedSegmentIndex;
    if (index == 0) {
        self.settingData.rate = AVSpeechUtteranceMinimumSpeechRate;
    } else if(index == 1){
        self.settingData.rate =AVSpeechUtteranceDefaultSpeechRate;
    } else {
        self.settingData.rate =AVSpeechUtteranceMaximumSpeechRate;
    }
    [SettingDataManager setRate:self.settingData.rate];
}


- (IBAction)changePitch:(id)sender {
    UISlider *slider = (UISlider *)sender;
//    NSLog(@"%f", slider.value);
    self.settingData.pitchMultiplier = slider.value;
    [SettingDataManager setPitch:self.settingData.pitchMultiplier];
}

#pragma mark - loading

- (void)showLoading {
    self.ai.hidden = NO;
    [self.ai startAnimating];
}

- (void)hideLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.ai stopAnimating];
        self.ai.hidden = YES;
    });
}

#pragma mark - twitterAPI

//新しいツイートを読み込む
//ツイートの情報を更新する
- (void)update {
    [self reset];
    
    [TwitterManager update];
}

//古いツイートをさらに読み込む
- (void)loadOldTweets {
    [TwitterManager loadOldTweets];
}

//現在のツイートをお気に入りに登録する
- (void)favorite {
    if(self.tweedDataList == nil){
        NSLog(@"データがないのでお気に入りできないっす");
        return;
    }
    
    [self stop];
    
    TweetData *data = [self.tweedDataList objectAtIndex:self.currentIndex];
    [self showLoading];
    [[TwitterManager sharedManager] requestCreateFavorite:data.serialId];
}

#pragma mark - AVSpeechSynthesizerDelegate

//指定した読み上げが完了したときの処理
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    
    NSLog(@"didFinishSpeechUtterance");
    
    if (self.currentTweetplayPart == TWEET_PLAY_PART_USER) {
        //ユーザ名を読み終わった
        [NSThread sleepForTimeInterval:0.5f];
        self.currentTweetplayPart = TWEET_PLAY_PART_BODY;
        [self play];
    } else if (self.currentTweetplayPart == TWEET_PLAY_PART_BODY) {
        [self next];
    } else if (self.currentTweetplayPart == TWEET_PLAY_EMPTY) {
        self.currentTweetplayPart = TWEET_PLAY_PART_USER;
    } else if (self.currentTweetplayPart == TWEET_PLAY_EMPTY_NEXT_USER) {
        self.currentTweetplayPart = TWEET_PLAY_PART_USER;
        [NSThread sleepForTimeInterval:0.4f];
        [self ring];
        [NSThread sleepForTimeInterval:1.4f];
        
        self.currentTweetplayPart = TWEET_PLAY_PART_USER;
        [self play];
    }
}

#pragma mark - TwitterManagerDelegate

//
- (void)twitterManagerDidUpdate:(NSMutableArray *)list {
    [self hideLoading];
    [self ringComplte];
    [NSThread sleepForTimeInterval:0.8f];
    self.tweedDataList = list;
    [self play];
}

- (void)twitterManagerDidLoad:(NSMutableArray *)list {
    [self hideLoading];
    [self ringComplte];
    [self.tweedDataList addObjectsFromArray:list];
    [self next];
}

- (void)twitterManagerDidFavorite {
    [self hideLoading];
    [self ringComplte];
    [NSThread sleepForTimeInterval:0.8f];
    NSLog(@"favorite success");
    [self next];
}

@end
