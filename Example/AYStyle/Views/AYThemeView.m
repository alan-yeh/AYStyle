//
//  AYThemeView.m
//  AYStyle
//
//  Created by Alan Yeh on 16/8/3.
//  Copyright © 2016年 Alan Yeh. All rights reserved.
//

#import "AYThemeView.h"

@implementation AYThemeView

- (void)loadTheme:(AYTheme *)theme{
    self.backgroundColor = [theme colorForName:@"ViewBackgroundColor"];
}
@end
