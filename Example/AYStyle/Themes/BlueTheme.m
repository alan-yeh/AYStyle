//
//  BlueTheme.m
//  AYStyle
//
//  Created by PoiSon on 16/8/3.
//  Copyright © 2016年 Alan Yeh. All rights reserved.
//

#import "BlueTheme.h"

@implementation BlueTheme
- (NSDictionary<NSString *,NSString *> *)colorDictionary{
    return [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"BlueTheme" withExtension:@"plist"]];
}
- (NSString *)themeNameFor:(NSString *)name{
    return [@"blue_" stringByAppendingString:name];
}
@end
