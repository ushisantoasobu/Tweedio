//
//  SettingDataManager.m
//  Tweedio
//
//  Created by shunsuke sato on 2013/10/07.
//  Copyright (c) 2013年 shunsuke sato. All rights reserved.
//

#import "SettingDataManager.h"

@implementation SettingDataManager

+(SettingData *)getData {
    
    SettingData *data = [[SettingData alloc] init];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    float rate = [ud floatForKey:@"RATE"];
    float picth = [ud floatForKey:@"PITCH"];
    
//    data.rate = rate != [NSNull null] ? rate : data.rate;
    if(rate != 0){
        data.rate = rate;
    }
    
    if (picth != 0) {
        data.pitchMultiplier = picth;
    }
    
    return data;
}

+(BOOL)setData:(SettingData *)data {
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setFloat:data.rate forKey:@"RATE"];
    [ud setFloat:data.pitchMultiplier forKey:@"PITCH"];
    
    return YES;
}


@end
