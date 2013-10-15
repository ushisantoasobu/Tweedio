//
//  TweetData.h
//  Tweedio
//
//  Created by shunsuke sato on 2013/10/07.
//  Copyright (c) 2013年 shunsuke sato. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TweetData : NSObject

@property (nonatomic, strong) NSString *serialId;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *body;

@end
