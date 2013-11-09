//
//  MainViewController.m
//  Tweedio
//
//  Created by shunsuke sato on 2013/10/07.
//  Copyright (c) 2013年 shunsuke sato. All rights reserved.
//

#import "MainViewController.h"
#import "TweetUtil.h"
#import <AudioToolbox/AudioServices.h>

@interface MainViewController ()


//ツイート情報のリスト
@property (nonatomic, strong) NSMutableArray *tweedDataList;

//現在のインデックス
@property (nonatomic) NSInteger currentIndex;

//ページインデックス
@property (nonatomic) NSInteger pageIndex;

typedef enum CurrentPlayPart:NSInteger {
    CURRENT_PLAY_PART_USER_NAME,
    CURRENT_PLAY_PART_BODY,
    CURRENT_PLAY_PART_STOP,
    CURRENT_PLAY_PART_NEXT,
    CURRENT_PLAY_PART_BACK,
} CurrentPlayPart;

//次のアクション
@property (nonatomic) enum CurrentPlayPart currentPlayPart;


//次のアクション
@property (nonatomic, strong) NSArray *accounts;

//設定データモデル
@property (nonatomic, strong) SettingData *settingData;


//読み上げモジュール
@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;


//サウンド
//@property (nonatomic, strong) SystemSoundID *sound;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *ai;

@property (weak, nonatomic) IBOutlet UISegmentedControl *psc;

@property (weak, nonatomic) IBOutlet UISlider *sl;

@property (weak, nonatomic) IBOutlet UIView *grayView;



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
    
    [self showLoading];
    [TwitterManager sharedManager].delegate = self;
    [[TwitterManager sharedManager] isAuthenticated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - initialSetting

- (void)initialSetting {
    
    [self reset];
    
    //synthesizerの設定
    self.synthesizer = [[AVSpeechSynthesizer alloc] init];
    self.synthesizer.delegate = self;
    
    //設定準備
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
    
    [self setHeader];
    
    //タイムラインの情報取得
    [[TwitterManager sharedManager] requestTimeline];
}

/**
 * ヘッダの設定
 */
- (void)setHeader {
    if ([self.accounts count] > 1) {
        NSLog(@"アカウント複数");
    }
}


#pragma mark - IBAction

- (IBAction)respondToBtnUpdate:(id)sender {
    [self stopWithNextAction:CURRENT_PLAY_PART_STOP];
    [self update];
}

- (IBAction)respondToBtnBack:(id)sender {
    [self back];
}

- (IBAction)respondToBtnNext:(id)sender {
    [self next];
}

- (IBAction)respondToBtnFavorite:(id)sender {
    [self favorite];
}

- (IBAction)respondToBtnStop:(id)sender {
    [self stopWithRing];
}

- (IBAction)respondToBtnPlay:(id)sender {
    
    [self play];
}


#pragma mark - data

- (void)reset {
    self.tweedDataList = [NSMutableArray array];
    self.currentIndex = 0;
    self.currentPlayPart = CURRENT_PLAY_PART_USER_NAME;
}

#pragma mark - sound

- (void)ringDeviceSound:(NSInteger)soundId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        AudioServicesPlaySystemSound(soundId);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //
        });
    });
}

- (void)ring {
    [self ringDeviceSound:1109];
}

- (void)ringComplte {
    [self ringDeviceSound:1154];
}

- (void)ringStop {
    [self ringDeviceSound:1257];
}

#pragma mark - operation

//再生する
- (void)play {
    
    if (self.tweedDataList == nil || [self.tweedDataList count] == 0) {
        return;
    }
    
    if([self.synthesizer isSpeaking]) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        TweetData *data = [self.tweedDataList objectAtIndex:self.currentIndex];
        
        NSString *str;
        if(self.currentPlayPart == CURRENT_PLAY_PART_USER_NAME){
            str = data.username;
            [self ring];
//            [NSThread sleepForTimeInterval:1.0f];
        } else if(self.currentPlayPart == CURRENT_PLAY_PART_BODY){
            str = data.body;
        } else {
            NSLog(@"ここのログでてたらまずい");
        }
        NSString *generatedTweet = [TweetUtil replaceForHearing:str];
        
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:generatedTweet];
        
        //各種設定
        [utterance setRate              :self.settingData.rate];
        [utterance setPitchMultiplier   :self.settingData.pitchMultiplier];
//        [utterance setVolume:0.80];
        
        AVSpeechSynthesisVoice *voice = [[AVSpeechSynthesisVoice alloc] init];
        [utterance setVoice:voice];
        
        [self.synthesizer speakUtterance:utterance];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //
            
        });
        
    });
    
}

/**
 * 停止する
 */
- (void)stopWithNextAction:(CurrentPlayPart)nextAction {
    if([self.synthesizer isSpeaking]) {
        self.currentPlayPart = nextAction;
        [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
}

/**
 * 停止する
 */
- (void)stopWithRing {
    [self ringStop];
    [self stopWithNextAction:CURRENT_PLAY_PART_STOP];
}

//前へ
- (void)back {
    
    if([self.tweedDataList count] == 0){
        return;
    }
    
    if(self.currentIndex == 0){
        return;
    }
//    
//    [self stop];
    
    self.currentPlayPart = CURRENT_PLAY_PART_USER_NAME;
    self.currentIndex--;
    
    [self play];
}

//次へ
- (void)next {
    
    if([self.synthesizer isSpeaking] == NO){
        [self play];
        return;
    }
    
    if([self.tweedDataList count] == 0){
        return;
    }
    
    if(self.currentIndex == [self.tweedDataList count] - 1){
        return;
    }
    
    self.currentIndex++;
    
    [self stopWithNextAction:CURRENT_PLAY_PART_NEXT];
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

#pragma mark - twitterAPI

//新しいツイートを読み込む
//ツイートの情報を更新する
- (void)update {
    [self stopWithNextAction:CURRENT_PLAY_PART_STOP];
    [self reset];
    
    [[TwitterManager sharedManager] requestTimeline];
}

//現在のツイートをお気に入りに登録する
- (void)favorite {
    if(self.tweedDataList == nil){
        NSLog(@"データがないのでお気に入りできないっす");
        return;
    }
    
    [self stopWithNextAction:CURRENT_PLAY_PART_STOP];
    
    TweetData *data = [self.tweedDataList objectAtIndex:self.currentIndex];
    [self showLoading];
    [[TwitterManager sharedManager] requestCreateFavorite:data.serialId];
}

#pragma mark - AVSpeechSynthesizerDelegate

/**
 * 読み上げ完了した時処理
 * @param synthesizer
 * @param utterance
 */
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"didFinishSpeechUtterance");
    if(self.currentPlayPart == CURRENT_PLAY_PART_USER_NAME){
        self.currentPlayPart = CURRENT_PLAY_PART_BODY;
        [self play];
    } else if(self.currentPlayPart == CURRENT_PLAY_PART_BODY){
        self.currentIndex++;
        self.currentPlayPart = CURRENT_PLAY_PART_USER_NAME;
        [self play];
    } else if(self.currentPlayPart == CURRENT_PLAY_PART_STOP){
        self.currentPlayPart = CURRENT_PLAY_PART_USER_NAME;
    } else if(self.currentPlayPart == CURRENT_PLAY_PART_NEXT){
        self.currentPlayPart = CURRENT_PLAY_PART_USER_NAME;
        [self play];
    } else {
        NSLog(@"ありえない");
    }
}

#pragma mark - TwitterManagerDelegate

- (void)twitterManagerDidAuthenticated:(BOOL)boolean account:(NSArray *)accounts{
    if (boolean) {
        self.accounts = accounts;
        [self initialSetting];
    } else {
        [self twitterAutheticatedError];
    }
}

/**
 * タイムライン更新時
 * @param list
 */
- (void)twitterManagerDidUpdateTimeline:(NSMutableArray *)list {
    [self hideLoading];
    [self ringComplte];
//    [NSThread sleepForTimeInterval:0.8f];
    self.tweedDataList = list;
    [self play];
}

/**
 * お気に入り成功時
 */
- (void)twitterManagerDidFavorite {
    [self hideLoading];
    [self ringComplte];
//    [NSThread sleepForTimeInterval:0.8f];
    [self next];
}


#pragma mark - loading

- (void)showLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.grayView.hidden = NO;
        self.ai.hidden = NO;
        [self.ai startAnimating];
    });
}

- (void)hideLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.grayView.hidden = YES;
        [self.ai stopAnimating];
        self.ai.hidden = YES;
    });
}


#pragma mark - account select



#pragma mark - error

/**
 * ツイッターAPIでエラーが返ってきたとき
 */
- (void)twitterAutheticatedError {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"alert"
                                                    message:@"XXXXXXXX"
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
}

/**
 * ツイッターAPIでエラーが返ってきたとき
 */
- (void)twitterManagerDidApiError {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"alert"
                                                    message:@"エラーが発生しました"
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
}

@end
