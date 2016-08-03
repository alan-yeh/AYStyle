//
//  AYFontCenter.m
//  AYStyle
//
//  Created by Alan Yeh on 16/8/2.
//
//

#import "AYFontCenter.h"
#import <AYAspect/AYAspect.h>

static NSString *AYCurrentFontNameKey = @"AYCurrentFontNameKey";
static NSString *AYCurrentFontLevelKey = @"AYCurrentFontLevelKey";

@implementation AYFontCenter{
    NSString *_currentFontName;
    AYFontLevel _currentLevel;
    NSHashTable *_observers;
}
- (NSInteger)increasementForLevel:(AYFontLevel)level{
    if (level == AYFontLevelSystem) {
        NSString *contentSize = [UIApplication sharedApplication].preferredContentSizeCategory;
        if (contentSize == UIContentSizeCategoryExtraSmall || contentSize == UIContentSizeCategorySmall) {
            level = AYFontLevelSmall;
        }else if (contentSize == UIContentSizeCategoryMedium){
            level = AYFontLevelMedium;
        }else if (contentSize == UIContentSizeCategoryLarge){
            level = AYFontLevelLarge;
        }else if (contentSize == UIContentSizeCategoryExtraLarge){
            level = AYFontLevelExtralLarge;
        }else{
            level = AYFontLevelExtralExtralLarge;
        }
    }
    
    switch (level) {
        case AYFontLevelSmall:
            return -2;
        case AYFontLevelMedium:
            return 0;
        case AYFontLevelLarge:
            return 2;
        case AYFontLevelExtralLarge:
            return 4;
        case AYFontLevelExtralExtralLarge:
            return 8;
        default:
            return 0;
    }
}

- (instancetype)_init{
    if (self = [super init]) {
        _observers = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

+ (instancetype)center{
    static AYFontCenter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AYFontCenter alloc] _init];
    });
    return instance;
}

- (NSString *)currentFontName{
    return _currentFontName ?: ({
        _currentFontName = [[NSUserDefaults standardUserDefaults] objectForKey:AYCurrentFontNameKey];
        if (_currentFontName.length < 1) {
            _currentFontName = [[UIFont systemFontOfSize:10] fontName];
            [[NSUserDefaults standardUserDefaults] setObject:_currentFontName forKey:AYCurrentFontNameKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        _currentFontName;
    });
}

- (AYFontLevel)currentFontLevel{
    return _currentLevel ?: ({
        NSNumber *currentLevel = [[NSUserDefaults standardUserDefaults] objectForKey:AYCurrentFontLevelKey];
        if (currentLevel == nil) {
            currentLevel = @(AYFontLevelSystem);
            [[NSUserDefaults standardUserDefaults] setObject:currentLevel forKey:AYCurrentFontLevelKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        currentLevel.integerValue;
    });
}

#pragma mark - 全局调整字体
- (void)applyFontName:(NSString *)fontName{
    NSParameterAssert(fontName != nil && fontName.length > 0);
    _currentFontName = [fontName copy];
    [[NSUserDefaults standardUserDefaults] setObject:_currentFontName forKey:AYCurrentFontNameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<AYFontObserver> observer in _observers) {
            [observer loadFont:self];
        }
    });
}

- (void)applyFontLevel:(AYFontLevel)newLevel{
    _currentLevel = newLevel;
    [[NSUserDefaults standardUserDefaults] setObject:@(newLevel) forKey:AYCurrentFontLevelKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<AYFontObserver> observer in _observers) {
            [observer loadFont:self];
        }
    });
}

- (void)applyFontLevel:(AYFontLevel)newLevel withFontName:(NSString *)fontName{
    NSParameterAssert(fontName != nil && fontName.length > 0);
    _currentLevel = newLevel;
    _currentFontName = [fontName copy];
    [[NSUserDefaults standardUserDefaults] setObject:@(newLevel) forKey:AYCurrentFontLevelKey];
    [[NSUserDefaults standardUserDefaults] setObject:_currentFontName forKey:AYCurrentFontNameKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<AYFontObserver> observer in _observers) {
            [observer loadFont:self];
        }
    });
}

#pragma mark - 调整字体相关方法
- (CGFloat)fontSizeAfterAdjust:(CGFloat)originalSize{
    return originalSize + [self increasementForLevel:self.currentFontLevel];
}

- (UIFont *)fontAfterAdjust:(UIFont *)originalFont{
    return [UIFont fontWithName:originalFont.fontName size:[self fontSizeAfterAdjust:originalFont.pointSize]];
}

- (UIFont *)fontWithSize:(CGFloat)fontSize{
    return [UIFont fontWithName:self.currentFontName size:[self fontSizeAfterAdjust:fontSize]];
}

#pragma mark - 注册与应用主题
- (void)registerObserver:(id<AYFontObserver>)observer{
    [_observers addObject:observer];
}

- (void)applyToObserver:(id<AYFontObserver>)observer{
    [observer loadFont:self];
}

- (void)autoRegisterClass:(Class)aClass beforeExecuting:(SEL)registeSEL applybeforeExecuting:(SEL)applySEL{
    //自动注册
    [AYAspect interceptSelector:registeSEL
                        inClass:aClass
                withInterceptor:AYInterceptorMake(^(NSInvocation *invocation) {
        if ([invocation.target conformsToProtocol:@protocol(AYFontObserver)]) {
            if (self.showLog) {
                NSLog(@"🅰️🅰️AYFontCenter: Auto register instance: <%@ %p>\n", [invocation.target class], invocation.target);
            }
            [[AYFontCenter center] registerObserver:invocation.target];
        }
        [invocation invoke];
    })];
    
    //自动应用字体
    [AYAspect interceptSelector:applySEL
                        inClass:aClass
                withInterceptor:AYInterceptorMake(^(NSInvocation *invocation) {
        if ([invocation.target conformsToProtocol:@protocol(AYFontObserver)]) {
            [invocation.target loadFont:[AYFontCenter center]];
        }
        [invocation invoke];
    })];
}
@end