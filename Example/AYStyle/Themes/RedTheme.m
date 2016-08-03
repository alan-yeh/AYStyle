//
//  RedTheme.m
//  AYStyle
//
//  Created by PoiSon on 16/8/3.
//  Copyright © 2016年 Alan Yeh. All rights reserved.
//

#import "RedTheme.h"

@implementation RedTheme
- (NSDictionary<NSString *,NSString *> *)colorDictionary{
    return [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"RedTheme" withExtension:@"plist"]];
}
- (NSString *)themeNameFor:(NSString *)name{
    return [@"red_" stringByAppendingString:name];
}
@end
