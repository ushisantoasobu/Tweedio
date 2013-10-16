//
//  SettingDataManager.m
//  Tweedio
//
//  Created by shunsuke sato on 2013/10/07.
//  Copyright (c) 2013年 shunsuke sato. All rights reserved.
//

#import "SettingDataManager.h"

@implementation SettingDataManager

//シングルトンにしなくては・・・・

+(SettingData *)getData {
    
    SettingData *data = [[SettingData alloc] init];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    float rate = [ud floatForKey:@"RATE"];
    float picth = [ud floatForKey:@"PITCH"];
    
//    data.rate = rate != [NSNull null] ? rate : data.rate;
//    if(rate != 0){
        data.rate = rate;
//    }
    
    if (picth != 0) {
        data.pitchMultiplier = picth;
    } else {
        data.pitchMultiplier = 0.5;
    }
    
    return data;
}

//+(BOOL)setData:(SettingData *)data {
//    
//    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
//    [ud setFloat:data.rate forKey:@"RATE"];
//    [ud setFloat:data.pitchMultiplier forKey:@"PITCH"];
//    
//    return YES;
//}

+(BOOL)setRate:(float)rate {
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setFloat:rate forKey:@"RATE"];
    
    return YES;
}

+(BOOL)setPitch:(float)pitch {
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setFloat:pitch forKey:@"PITCH"];
    
    return YES;
}


@end
