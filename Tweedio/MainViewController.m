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

typedef enum NextAction:NSInteger {
    NEXT_ACTION_USER_NAME,
    NEXT_ACTION_BODY,
    NEXT_ACTION_STOP,
    NEXT_ACTION_NEXT,
    NEXT_ACTION_BACK,
    NEXT_ACTION_UPDATE
} TweetPlayPart;

//次のアクション
@property (nonatomic) enum NextAction nextAction;


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


#pragma mark -

- (void)doNextAction {
    
    NSLog(@"donextaction");
    
    if (self.nextAction == NEXT_ACTION_USER_NAME) {
        NSLog(@"a");
        [self next];
    
    } else if (self.nextAction == NEXT_ACTION_BODY) {
        NSLog(@"b");
        [NSThread sleepForTimeInterval:0.5f];
        [self play];
    
    } else if (self.nextAction == NEXT_ACTION_STOP) {
        NSLog(@"c");
        [self ringStop];
        //何もしない
    
    } else if (self.nextAction == NEXT_ACTION_NEXT) {
        NSLog(@"d");
        self.nextAction = NEXT_ACTION_USER_NAME;
        [self play];
        
    } else if (self.nextAction == NEXT_ACTION_BACK) {
        NSLog(@"e");
        self.nextAction = NEXT_ACTION_USER_NAME;
        [self play];
        
    } else if (self.nextAction == NEXT_ACTION_UPDATE) {
        NSLog(@"f");
        [self reset];
        [self showLoading];
        [[TwitterManager sharedManager] requestTimeline];
        
    } else {
        NSLog(@"g");
    }
}

#pragma mark - IBAction

- (IBAction)respondToBtnUpdate:(id)sender {
    
    self.nextAction = NEXT_ACTION_UPDATE;
    
    //もし音が鳴っていたら止める
    [self stop];
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
    self.nextAction = NEXT_ACTION_STOP;
    [self stop];
}

- (IBAction)respondToBtnPlay:(id)sender {
    
    if (self.nextAction != NEXT_ACTION_STOP) {
        return;
    }
    
    self.nextAction = NEXT_ACTION_USER_NAME;
    [self play];
}


#pragma mark - data

- (void)reset {
    self.tweedDataList = [NSMutableArray array];
    self.currentIndex = 0;
    self.nextAction = NEXT_ACTION_USER_NAME;
}

#pragma mark - sound

- (void)ring {
    AudioServicesPlaySystemSound(1109);
//    AudioServicesPlaySystemSound(1308);
}

- (void)ringComplte {
    AudioServicesPlaySystemSound(1154);
}

- (void)ringStop {
    AudioServicesPlaySystemSound(1305);
}

#pragma mark - operation

//再生する
- (void)play {
    
    if (self.tweedDataList == nil || [self.tweedDataList count] == 0) {
        return;
    }
    
    TweetData *data = [self.tweedDataList objectAtIndex:self.currentIndex];
    
    NSString *str;
    if(self.nextAction == NEXT_ACTION_USER_NAME){
        self.nextAction = NEXT_ACTION_BODY;
        str = data.username;
        [self ring];
        [NSThread sleepForTimeInterval:1.0f];
    } else if(self.nextAction == NEXT_ACTION_BODY){
        self.nextAction = NEXT_ACTION_USER_NAME;
        str = data.body;
    } else {
        NSLog(@"ここのログでてたらまずい");
    }
    NSString *generatedTweet = [TweetUtil replaceForHearing:str];
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:generatedTweet];

    //各種設定
    [utterance setRate              :self.settingData.rate];
    [utterance setPitchMultiplier   :self.settingData.pitchMultiplier];
    [utterance setVolume:0.30];
    
    AVSpeechSynthesisVoice *voice = [[AVSpeechSynthesisVoice alloc] init];
    [utterance setVoice:voice];
    
    [self.synthesizer speakUtterance:utterance];
}

/**
 * 停止する
 */
- (void)stop {
    
    if([self.synthesizer isSpeaking]) {
        
        NSLog(@"isspeaking");
        
        /**--なんかとまらなかったので強引な方法？？記事も見つからず・・・--*/
        /**--空のものを読み上げされるためイベントが発生するという展開に・・・--*/
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:nil];
        AVSpeechSynthesisVoice *voice = [[AVSpeechSynthesisVoice alloc] init];
        [utterance setVoice:voice];
        [self.synthesizer speakUtterance:utterance];
        /**-----------------------------------------------------------------*/
        
        [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        
//        [self doNextAction];
        
    } else {
        NSLog(@"isnotspeaking");
        [self doNextAction];
        
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
    
    self.currentIndex--;
    self.nextAction = NEXT_ACTION_BACK;
    
    [self stop];
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
    self.nextAction = NEXT_ACTION_NEXT;
    
    [self stop];
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
    [self reset];
    
//    [TwitterManager update];
}

//古いツイートをさらに読み込む
- (void)loadOldTweets {
//    [TwitterManager loadOldTweets];
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

/**
 * 読み上げ完了した時処理
 * @param synthesizer
 * @param utterance
 */
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    NSLog(@"didFinishSpeechUtterance");
    [self doNextAction];
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
    [NSThread sleepForTimeInterval:0.8f];
    self.tweedDataList = list;
    [self play];
}

/**
 * お気に入り成功時
 */
- (void)twitterManagerDidFavorite {
    [self hideLoading];
    [self ringComplte];
    [NSThread sleepForTimeInterval:0.8f];
    [self next];
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
}

@end
