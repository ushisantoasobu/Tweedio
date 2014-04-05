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
    
    //test 1文字足す <- なんでだっけ？
    tweet = [NSString stringWithFormat:@"%@%@", tweet, @" "];
    
    //リンク
    tweet = [TweetUtil replace:tweet
                       pattern:@"(http://|https://){1}[\\w\\.\\-/:]+"
                   replacement:@"、リンク、"];
    
    tweet = [TweetUtil replace:tweet
                       pattern:@"#"
                   replacement:@"、ハッシュタグ、"];
    
    tweet = [TweetUtil replace:tweet
                       pattern:@"RT(:| )"
                   replacement:@"、リツイート、"];
    
    return tweet;
}

+(NSString *)replace:(NSString *)orginal pattern:(NSString *)pattern replacement:(NSString *)replacement
{
    NSRegularExpression *regexp = [NSRegularExpression
              regularExpressionWithPattern:pattern
              options:NSRegularExpressionCaseInsensitive
              error:nil
              ];
    
    NSString *retStr = [regexp
                      stringByReplacingMatchesInString:orginal
                      options:NSMatchingReportProgress
                      range:NSMakeRange(0, orginal.length)
                      withTemplate:replacement
                      ];
    
//    NSLog(@"%@", retStr);
    
    
    return retStr;
}

@end
