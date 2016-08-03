//
//  AYViewController.m
//  AYStyle
//
//  Created by Alan Yeh on 08/01/2016.
//  Copyright (c) 2016 Alan Yeh. All rights reserved.
//

#import "AYViewController.h"
#import <AYStyle/AYStyle.h>

@interface AYViewController ()<AYThemeObserver, AYFontObserver>
@property (weak, nonatomic) IBOutlet UILabel *themeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *themeImage;
@end

@implementation AYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)loadTheme:(AYTheme *)theme{
    self.themeLabel.textColor = [theme colorForName:@"LabelFontColor"];
    self.themeImage.image = [theme imageForName:@"theme.png"];
}

- (void)loadFont:(AYFontCenter *)center{
    self.themeLabel.font = [center fontWithSize:17];
}

- (IBAction)applyFontLevel:(UIButton *)sender {
    [[AYFontCenter center] applyFontLevel:(AYFontLevel)sender.tag];
}

- (IBAction)applyFont:(UIButton *)sender {
    [[AYFontCenter center] applyFontName:[sender currentTitle]];
}

- (IBAction)applyBlueTheme:(id)sender {
    [[AYThemeCenter center] applyThemeWithName:@"blue"];
}


- (IBAction)applyRedTheme:(id)sender {
    [[AYThemeCenter center] applyThemeWithName:@"red"];
}
@end
