//
//  TweetUtil.m
//  Tweedio
//
//  Created by shunsuke sato on 2013/10/07.
//  Copyright (c) 2013年 shunsuke sato. All rights reserved.
//

#import "TweetUtil.h"

@implementation TweetUtil

+(NSString *)replaceForHearing:(NSString *)tweet{
    
    NSLog(@"%@", tweet);
    
    //test 1文字足す
    tweet = [NSString stringWithFormat:@"%@%@", tweet, @" "];
    
    //リンク
    NSString *pattern = @"http.* ";
    NSString *replacement = @"、リンク、";
    
    NSRegularExpression *regexp = [NSRegularExpression
                                   regularExpressionWithPattern:pattern
                                   options:NSRegularExpressionCaseInsensitive
                                   error:nil
                                   ];
    
    NSString *str = [regexp
                     stringByReplacingMatchesInString:tweet
                     options:NSMatchingReportProgress
                     range:NSMakeRange(0, tweet.length)
                     withTemplate:replacement
                     ];
    
    NSLog(@"%@", str);
    
    //ハッシュタグ
    
    pattern = @"#";
    replacement = @"、ハッシュタグ、";
    
    regexp = [NSRegularExpression
                                   regularExpressionWithPattern:pattern
                                   options:NSRegularExpressionCaseInsensitive
                                   error:nil
                                   ];
    
    NSString *str2 = [regexp
                     stringByReplacingMatchesInString:str
                     options:NSMatchingReportProgress
                     range:NSMakeRange(0, str.length)
                     withTemplate:replacement
                     ];
    
    NSLog(@"%@", str2);
    
    //写真
    
    //
    
    return str2;
}

@end
