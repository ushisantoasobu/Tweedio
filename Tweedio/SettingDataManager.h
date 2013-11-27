//
//  SettingDataManager.h
//  Tweedio
//
//  Created by shunsuke sato on 2013/10/07.
//  Copyright (c) 2013年 shunsuke sato. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingData.h"

@interface SettingDataManager : NSObject

+(SettingData *)getData;

//+(BOOL)setData:(SettingData *)data;

+(BOOL)setRate:(float)rate;
+(BOOL)setPitch:(float)pitch;
+(BOOL)setAccountIndex:(int)index;

@end
