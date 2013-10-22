//
//  TwitterManager.m
//  Tweedio
//
//  Created by shunsuke sato on 2013/10/05.
//  Copyright (c) 2013年 shunsuke sato. All rights reserved.
//

#import "TwitterManager.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>


@interface TwitterManager ()

@property (nonatomic, strong) ACAccountStore *accountStore;

@end

@implementation TwitterManager


/*
 * シングルトンの実装
 *
 * http://programming-ios.com/objective-c-singleton/
 * を参考にしてる
 *
 */

+(TwitterManager*)sharedManager {
    
    static TwitterManager* sharedSingleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSingleton = [[TwitterManager alloc] initSharedInstance];
    });
    return sharedSingleton;
}

- (id)initSharedInstance {
    self = [super init];
    if (self) {
        // 初期化処理
    }
    return self;
}

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}





/**
 * 認証する
 *
 */
-(void)isAuthenticated {
    self.accountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [self.accountStore
                                         accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:twitterAccountType
                                               options:nil
                                            completion:^(BOOL granted, NSError *error){
                                                [self.delegate twitterManagerDidAuthenticated:granted account:self.accountStore.accounts];
                                            }];
}


/*
 * タイムラインを取得する
 * @param index
 */
-(void)requestTimeline {
    
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:accountType
                                               options:nil
                                            completion:^(BOOL granted, NSError *error) {
                                                
                                                NSLog(@"granted:%hhd", granted);
                                                
                                                if (granted) {
                                                    
                                                    NSDictionary *param = [NSDictionary dictionaryWithObject:@"200" forKey:@"count"];
                                                
                                                NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
                                                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                                                        requestMethod:SLRequestMethodGET
                                                                                                  URL:requestURL
                                                                                           parameters:param];
                                                
                                                 [request setAccount:[[self.accountStore accountsWithAccountType:accountType] objectAtIndex:0]];
                                                
                                                    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                                       
                                                        if (responseData) {
                                                            
                                                            if (urlResponse.statusCode == 200) {
                                                                
                                                                NSError *jsonError;
                                                                NSArray *timelineData =
                                                                [NSJSONSerialization
                                                                 JSONObjectWithData:responseData
                                                                 options:NSJSONReadingAllowFragments error:&jsonError];
                                                                
//                                                                timelineData
                                                                NSDictionary *aaa = [timelineData objectAtIndex:0];
                                                                
                                                                NSMutableArray *arr = [[NSMutableArray alloc] init];
                                                                for (int i = 0; i < [timelineData count]; i++) {
                                                                    NSDictionary *dic = [timelineData objectAtIndex:i];
                                                                    TweetData *data = [[TweetData alloc] init];
                                                                    data.serialId = [dic objectForKey:@"id_str"];//注：idでとったらfavoriteのところで404になった！ id_str
                                                                    data.body = [dic objectForKey:@"text"];
                                                                    NSDictionary *userDic = [dic objectForKey:@"user"];
                                                                    data.username = [userDic objectForKey:@"name"];
                                                                    
                                                                    [arr addObject:data];
                                                                }
                                                                
                                                                [self.delegate twitterManagerDidUpdateTimeline:arr];
                                                                
                                                            }
                                                            
                                                        }
                                                        
                                                    }];
                                                    
                                                } else {
                                                 
                                                    
                                                    
                                                }
                            
                                            }];
    
    
    
   
    
}

- (void)requestCreateFavorite:(NSString *)serialId {
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:accountType
                                               options:nil
                                            completion:^(BOOL granted, NSError *error) {
                                                
                                                if (granted) {
                                                    
                                                    NSDictionary *param = [NSDictionary dictionaryWithObject:serialId forKey:@"id"];
                                                    
                                                    NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/favorites/create.json"];
                                                    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                                                            requestMethod:SLRequestMethodPOST
                                                                                                      URL:requestURL
                                                                                               parameters:param];
                                                    
                                                    [request setAccount:[[self.accountStore accountsWithAccountType:accountType] objectAtIndex:0]];
                                                    
                                                    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                                        
                                                        if (responseData) {
                                                            
                                                            if (urlResponse.statusCode == 200) {
                                                                
                                                                [self.delegate twitterManagerDidFavorite];
                                                                
                                                            }
                                                            
                                                        }
                                                        
                                                    }];
                                                    
                                                } else {
                                                    
                                                    
                                                    
                                                }
                                                
                                            }];
}

@end
