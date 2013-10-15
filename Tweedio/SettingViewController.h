//
//  SettingViewController.h
//  Tweedio
//
//  Created by shunsuke sato on 2013/10/07.
//  Copyright (c) 2013年 shunsuke sato. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingData.h"

@protocol SettingViewDelegate <NSObject>

@optional
- (void)settingViewDidSet:(SettingData *)data;
@end

@interface SettingViewController : UIViewController

@property id <SettingViewDelegate> delegate;

@end
