//
//  MainViewController.h
//  Tweedio
//
//  Created by shunsuke sato on 2013/10/07.
//  Copyright (c) 2013年 shunsuke sato. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "TwitterManager.h"
#import "SettingDataManager.h"
#import "TweetData.h"

@interface MainViewController : UIViewController<AVSpeechSynthesizerDelegate,
TwitterManagerDelegate>

@end
