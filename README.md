# AYStyle

[![CI Status](http://img.shields.io/travis/alan-yeh/AYStyle.svg?style=flat)](https://travis-ci.org/alan-yeh/AYStyle)
[![Version](https://img.shields.io/cocoapods/v/AYStyle.svg?style=flat)](http://cocoapods.org/pods/AYStyle)
[![License](https://img.shields.io/cocoapods/l/AYStyle.svg?style=flat)](http://cocoapods.org/pods/AYStyle)
[![Platform](https://img.shields.io/cocoapods/p/AYStyle.svg?style=flat)](http://cocoapods.org/pods/AYStyle)

## 引用
　　使用[CocoaPods](http://cocoapods.org)可以很方便地引入AYStyle。Podfile添加AYStyle的依赖。

```ruby
pod "AYStyle"
```

## 简介
　　AYStyle包含两个主要框架，一个是`AYThemeCenter`，用于管理应用主题；另一个是`AYFontCenter`，用于管理应用字体。

　　当前，移动app对于界面的美观性等有越来越高的要求，一套UI已经满足不了用户日益增长的“精神需求”。因此，项目中经常会有更换主题、更换字体这类的需求。之前写主题管理时，经常乱得头皮发麻，经过几次整理、重构，完成了AYThemeCenter和AYFontCenter这两个界面管理框架。
### AYThemeCenter
---
　　AYThemeCenter是主题管理中心，主要用于管理User Interface中的图片、颜色等。AYThemeCenter使用起来非常简单，同时它实现了图片的缓存管理，减少重复载入、内存占用等。

　　那么接下来，演示如何从0开始实现一个主题管理中心。主题主题，那么首先应该创建主题。创建主题需要继承`PSTheme`。

```objective-c
@interface PSTheme : NSObject
- (UIColor *)colorForName:(NSString *)colorName;
- (UIImage *)imageForName:(NSString *)imageName;
- (void)imageForName:(NSString *)imageName asyncCallback:(void (^)(UIImage *image))callback;

#pragma mark - 主题子类需要实现的方法
- (NSDictionary<NSString *, NSString *> *)colorDictionary;/**< 颜色字典 */
- (NSString *)themeNameFor:(NSString *)name;/**< 主题图片名字切换 */
- (NSBundle *)imageBundle;/**< 图片存在的位置, 默认为mainBundle */
@end
```
　　PSTheme是一个抽像类，里面已经默认实现了前三个方法和用于缓存之类的方法。需要开发者实现下面三个方法，返回主题需要的一些基本信息。

　　BlueTheme是一个蓝色主题，它有以下实现。

```objective-c
#import <PSExtensions/PSExtensions.h>
@interface BlueTheme : PSTheme
@end

@implementation BlueTheme
/** 主题颜色字典，这个必须实现，否则将会抛出异常 */
- (NSDictionary<NSString *, NSString *> *)colorDictionary{
    return @{//支持多种颜色格式
             @"ViewControllerBackgroundColor": @"#000066",
             @"TitleColor": @"0, 153, 153",
             @"TitleBackgroundColor": @"0.3"
             };
    
    //此方法也可以返回Documents下的主题资源，方便从服务器上下载主题资源包
//    return [NSDictionary dictionaryWithContentsOfFile:[[[PSFile documents] child:@"ThemesResources"] child:@"BlueColorDic.plist"].path];
}

/** 主题图片名字（不实现的话，默认返回原来的名字） */
- (NSString *)themeNameFor:(NSString *)name{
    //给图片加上前缀之类的
    return [@"blue_" stringByAppendingString:name];
}

/** 主题图片所在的位置（不实现的话，默认是mainBundle） */
- (NSBundle *)imageBundle{
    //可以返回Documents下的主题资源，方便从服务器上下载主题资源包
    return [NSBundle bundleWithPath:[[[PSFile documents] child:@"ThemesResources"] child:@"Blue"].path];
}
@end
```
　　蓝色的主题建完了，还可以再建一个金色的主题`GoldTheme`，实现与上面类似的方法即可。

　　接下来将主题注册进主题主心

```objective-c
    [[AYThemeCenter center] registerTheme:[BlueTheme new] forName:@"Blue"];
    [[AYThemeCenter center] registerTheme:[GoldTheme new] forName:@"Gold"];
```
　　将观察者注册进主题中心。

```objective-c
//手动注册进字体中心
@implementation SomeObject
- (instancetype)init{
    if (self = [super init]){
        //AYThemeCenter保持的是此对象的weak引用，所以不需要在[-dealloc]中移除观察者（自身）。
        [[AYThemeCenter center] registerObserver:self];
    }
}
@end
```
　　AYThemeCenter方便之处，在于它可以`自动`将符合条件的对象注册进主题中心，并在用户觉得适当的时候，应用主题方法。

```objective-c
    //将项目中，所有UIViewController及其子类（实现了PSThemeObserver协议）自动注册进主题中心
    //在执行-[UIViewController viewDidLoad]方法之前，将该对象注册进主题中心
    //在执行-[UIViewController viewDidLayoutSubviews]之前，执行应用主题方法
    [[AYThemeCenter center] autoRegisterClass:[UIViewController class] beforeExecuting:@selector(viewDidLoad) applyBeforeExecuting:@selector(viewDidLayoutSubviews)];
```
　　ViewController中需要做的，就只是实现主题观察者协议就足够了。

```objective-c
@interface ViewController ()<PSThemeObserver>
@end

@implementation ViewController
/** 当主题变更时，或者在执行viewDidLayoutSubviews（用户在上面指定）之前，此方法自动执行，无需用户手动调取 */
- (void)loadTheme:(PSTheme *)theme{
    self.logoView.image = [theme imageForName:@"logo.png"];
    self.backgroundColor = [theme colorForName:@"ViewControllerBackgroundColor"];
    self.titleLabel.textColor = [theme colorForName:@"TitleColor"];
    self.titleLabel.backgroundColor = [theme colorForName:@"TitleBackgroundColor"];
}
@end
```
　　是时间该更换主题了，一行代码就将整个应用变成了金色主题了。

```objective-c
[[AYThemeCenter center] applyThemeWithName:@"Gold"];
```

### 2 AYFontCenter
---
　　AYFontCenter是字体管理中心，主要用于管理User Interface中的文字大小、字体。AYThemeCenter使用起来也很简单。

　　那么，接下来，还是演示一下怎么从0开始实现字体管理。字体管理与主题管理不同的地方是，字体管理中心不需要实现字体（字体怎么实现？？？），只需要把对象注册进字体中心，然后便可以直使用字体中心的功能了。

```objective-c
//手动注册进字体中心
@implementation SomeObject
- (instancetype)init{
    if (self = [super init]){
        [[AYFontCenter center] registerObserver:self];
    }
}
@end
```

```objective-c
    //将项目中，所有UIViewController及其子类（实现了PSFontObserver协议）自动注册进字体中心
    //在执行-[UIViewController viewDidLoad]方法之前，将该对象注册进主题主心
    //在执行-[UIViewController viewDidLayoutSubviews]之前，执行应用主题方法
    [[AYFontCenter center] autoRegisterClass:[UIViewController class] beforeExecuting:@selector(viewDidLoad) applybeforeExecuting:@selector(viewDidLayoutSubviews)];
```
　　实现字体观察者方法。

```objective-c
@interface ViewController ()<PSFontObserver>
@end

@implementation ViewController
/** 当主题变更时，或者在执行viewDidLayoutSubviews（用户在上面指定）之前，此方法自动执行，无需用户手动调取 */
- (void)loadFont:(AYFontCenter *)center{
    self.titleLabel.font = [center fontWithSize:20.0f];
    self.contentLabel.font = [center fontWithSize:15.0f];
}
@end
```
　　全局更新字体与字体大小

```objective-c
    //单纯更新字体
    [[AYFontCenter center] applyFontName:@"Courier-Bold"];
    //单线更新字体大小
    [[AYFontCenter center] applyFontLevel:PSFontLevelExtralLarge];
    //同时更新字体及字体大小
    [[AYFontCenter center] applyFontLevel:PSFontLevelSmall withFontName:@"Helvetica"]; 
```

## License

AYStyle is available under the MIT license. See the LICENSE file for more info.
