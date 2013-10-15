//
//  TwitterManager.h
//  Tweedio
//
//  Created by shunsuke sato on 2013/10/05.
//  Copyright (c) 2013年 shunsuke sato. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TweetData.h"

@protocol TwitterManagerDelegate <NSObject>

@optional
- (void)twitterManagerDidUpdate:(NSMutableArray *)list;
- (void)twitterManagerDidLoad:(NSMutableArray *)list;
- (void)twitterManagerDidFavorite;
@end

@interface TwitterManager : NSObject

@property id <TwitterManagerDelegate> delegate;

//twitterアカウント情報が設定されているか

+(TwitterManager*)sharedManager;

-(BOOL)isAuthenticated;
-(void)requestTimeline:(NSInteger)index;

+ (void)update;
+ (void)loadOldTweets;
- (void)requestCreateFavorite:(NSString *)serialId;

@end
