//
//  AYThemeCenter.m
//  AYStyle
//
//  Created by Alan Yeh on 16/8/2.
//
//

#import "AYThemeCenter.h"
#import <AYAspect/AYAspect.h>

static NSString * PSThemeManagerKey = @"PS_THEME_MANAGER_KEY";

@interface PSThemeCenter()
@property (nonatomic, strong) NSMutableDictionary *registedThemes;
@property (nonatomic, strong) NSHashTable *observers;
@end

@implementation PSThemeCenter{
    PSTheme *_currentTheme;
    NSString *_currentThemeName;
}
- (instancetype)_init{
    if (self = [super init]) {
        self.registedThemes = [NSMutableDictionary new];
        self.observers = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

+ (instancetype)center{
    static PSThemeCenter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PSThemeCenter alloc] _init];
    });
    return instance;
}

- (void)registerTheme:(PSTheme *)theme forName:(NSString *)themeName{
    NSAssert(![self.registedThemes.allKeys containsObject:themeName], @"已存在名为【%@】的主题", themeName);
    [self.registedThemes setObject:theme forKey:themeName];
}

- (void)registerObserver:(id<PSThemeObserver>)observer{
    NSParameterAssert(observer != nil);
    [self.observers addObject:observer];
}

- (void)applyThemeToObserver:(id<PSThemeObserver>)observer{
    [observer loadTheme:self.currentTheme];
}

- (void)changeThemeWithName:(NSString *)themeName{
    NSParameterAssert(themeName != nil && themeName.length > 0);
    NSAssert([self.registedThemes.allKeys containsObject:themeName], @"不存在名为【%@】的主题", themeName);
    PSTheme *theme = [self.registedThemes objectForKey:themeName];
    
    _currentTheme = theme;
    _currentThemeName = themeName;
    //保存主题信息
    [[NSUserDefaults standardUserDefaults] setObject:themeName forKey:PSThemeManagerKey];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //应用主题
        for (id<PSThemeObserver> observer in self.observers) {
            [observer loadTheme:_currentTheme];
        }
    });
}

- (PSTheme *)currentTheme{
    if (!_currentTheme) {
        NSAssert(self.registedThemes.count, @"应用没有注册主题, 无法获取主题");
        _currentTheme = [self.registedThemes objectForKey:self.currentThemeName];
    }
    return _currentTheme;
}

- (NSString *)currentThemeName{
    return _currentThemeName ?: ({
        _currentThemeName = [[NSUserDefaults standardUserDefaults] objectForKey:PSThemeManagerKey];
        if (_currentThemeName.length < 1) {
            _currentThemeName = [self.registedThemes allKeys][0];
            [[NSUserDefaults standardUserDefaults] setObject:_currentThemeName forKey:PSThemeManagerKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        _currentThemeName;
    });
}

- (void)autoRegisterClass:(Class)aClass beforeExecuting:(SEL)registeSEL applyBeforeExecuting:(SEL)applySEL{
    //自动注册
    [AYAspect interceptSelector:registeSEL
                        inClass:aClass
                withInterceptor:AYInterceptorMake(^(NSInvocation *invocation) {
        if ([invocation.target conformsToProtocol:@protocol(PSThemeObserver)]) {
            if (self.showLog) {
                NSLog(@"🌈🌈PSThemeCenter: Auto register instance: <%@ %p>\n", [invocation.target class], invocation.target);
            }
            [[PSThemeCenter center] registerObserver:invocation.target];
        }
        [invocation invoke];
    })];
    
    //自动应用主题
    [AYAspect interceptSelector:applySEL
                        inClass:aClass
                withInterceptor:AYInterceptorMake(^(NSInvocation *invocation) {
        if ([invocation.target conformsToProtocol:@protocol(PSThemeObserver)]) {
            [invocation.target loadTheme:[PSThemeCenter center].currentTheme];
        }
        [invocation invoke];
    })];
}
@end

@implementation PSTheme{
    NSMapTable<NSString *, UIImage *> *_imageCache;
    NSMapTable<NSString *, UIColor *> *_colorCache;
    NSDictionary<NSString *,NSString *> *_colorDic;
}

- (NSMapTable<NSString *, UIImage *> *)imageCache{
    return _imageCache ?: ({_imageCache = [NSMapTable strongToWeakObjectsMapTable];});
}

- (NSMapTable<NSString *, UIColor *> *)colorCache{
    return _colorCache ?: ({_colorCache = [NSMapTable strongToWeakObjectsMapTable];});
}

- (NSDictionary<NSString *, NSString *> *)colorDic{
    return _colorDic ?: ({_colorDic = [self colorDictionary]; });
}

- (UIColor *)colorForName:(NSString *)colorName{
    return [[self colorCache] objectForKey:colorName] ?: ({
        UIColor *color = [self ps_colorFromString:[self.colorDic objectForKey:colorName]];
        [[self colorCache] setObject:color forKey:colorName];
        color;
    });
}

- (UIImage *)imageForName:(NSString *)imageName{
    NSString *themeName = [self themeNameFor:imageName];
    return [[self imageCache] objectForKey:themeName] ?: ({
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[self imageBundle] pathForResource:themeName ofType:nil]];
        [[self imageCache] setObject:image forKey:themeName];
        image;
    });
}

- (void)imageForName:(NSString *)imageName asyncCallback:(void (^)(UIImage *))callback{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self imageForName:imageName];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(image);
        });
    });
}

#pragma mark - 主题子类需要实现的方法
- (NSDictionary<NSString *,NSString *> *)colorDictionary{
    [self doesNotRecognizeSelector:@selector(colorDictionary)];
    return nil;
}

- (NSString *)themeNameFor:(NSString *)name{
    return name;
}

- (NSBundle *)imageBundle{
    return [NSBundle mainBundle];
}

#pragma mark - 将字符串转为颜色
- (UIColor *)ps_colorFromString:(NSString *)colorString{
    NSParameterAssert(colorString != nil && colorString.length > 0);
    
    if ([colorString hasPrefix:@"#"]) {
        //处理类似#FFFFFF的色值
        return [self _ps_colorFromHexString:[colorString substringFromIndex:1]];
    }else if ([colorString hasPrefix:@"0X"] || [colorString hasPrefix:@"0x"]){
        //处理类似OXFFFFFF的色值
        return [self _ps_colorFromHexString:[colorString substringFromIndex:2]];
    }else{
        NSArray<NSString *> *rgbs = [colorString componentsSeparatedByString:@","];
        switch (rgbs.count) {
            case 1:{
                float white = [rgbs[0] floatValue];
                return [UIColor colorWithWhite:white alpha:1];
                break;
            }
            case 2:{
                float white = [rgbs[0] floatValue];
                float alpha = [rgbs[1] floatValue];
                return [UIColor colorWithWhite:white alpha:alpha];
                break;
            }
            case 3:{
                float red = [rgbs[0] floatValue];
                float green = [rgbs[1] floatValue];
                float blue = [rgbs[2] floatValue];
                return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1];
                break;
            }
            case 4:{
                float red = [rgbs[0] floatValue];
                float green = [rgbs[1] floatValue];
                float blue = [rgbs[2] floatValue];
                float alpha = [rgbs[3] floatValue];
                return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha];
                break;
            }
            default:
                break;
        }
    }
    return nil;
}
//如果是6位的, 则不含有alpha, 8位含有alpha
- (UIColor *)_ps_colorFromHexString:(NSString *)hexString{
    if (hexString.length != 6 && hexString.length != 8) {
        return [UIColor blackColor];
    }
    NSString *rString = [hexString substringWithRange:NSMakeRange(0, 2)];
    NSString *gString = [hexString substringWithRange:NSMakeRange(2, 2)];
    NSString *bString = [hexString substringWithRange:NSMakeRange(4, 2)];
    NSString *sString = @"FF";
    if (hexString.length == 8) {
        sString = [hexString substringWithRange:NSMakeRange(6, 2)];
    }
    unsigned int r, g, b, s;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    [[NSScanner scannerWithString:sString] scanHexInt:&s];
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b/255.0f alpha:s/255.0f];
}
@end
