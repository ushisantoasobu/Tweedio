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
- (void)twitterManagerDidAuthenticated:(BOOL)boolean account:(NSArray *)accounts;
- (void)twitterManagerDidUpdateTimeline:(NSMutableArray *)list;
- (void)twitterManagerDidFavorite;
- (void)twitterManagerDidApiError;
@end

@interface TwitterManager : NSObject

@property id <TwitterManagerDelegate> delegate;

+(TwitterManager*)sharedManager;

-(void)isAuthenticated;
-(void)requestTimeline:(NSInteger)accountIndex;
-(void)requestCreateFavorite:(NSString *)serialId accountIndex:(NSInteger)accountIndex;

@end
