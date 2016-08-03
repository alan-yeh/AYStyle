//
//  AYThemeCenter.h
//  AYStyle
//
//  Created by Alan Yeh on 16/8/2.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AYTheme;
@protocol AYThemeObserver;

/***************************************************************
 *  主题管理
 ***************************************************************/
@interface AYThemeCenter : NSObject
- (instancetype)init __attribute__((unavailable("不允许直接实例化")));
+ (instancetype)new __attribute__((unavailable("不允许直接实例化")));

+ (instancetype)center;

@property (nonatomic, assign) BOOL showLog;/**< 是否输出调试信息 */
@property (nonatomic, strong, readonly)AYTheme *currentTheme;/**< 当前主题 */
@property (nonatomic, strong, readonly)NSString *currentThemeName;/**< 当前主题名字 */

- (void)applyThemeWithName:(NSString *)themeName;/**< 更新主题 */
- (void)applyToObserver:(id<AYThemeObserver>)observer;/**< 手动应用主题至该观察者 */

#pragma mark - 注册
- (void)registerTheme:(AYTheme *)theme forName:(NSString *)themeName;/**< 注册主题 */
- (void)registerObserver:(id<AYThemeObserver>)observer;/**< 注册观察者 */
/** 自动将该类型【及子类】下所有实例【已实现协议】自动注册至主题中心，在执行${registeSEL}之前，自动注册进主题中心，在执行${applySEL}之前，自动应用主题 */
- (void)autoRegisterClass:(Class)aClass beforeExecuting:(SEL)registeSEL applyBeforeExecuting:(SEL)applySEL;
@end

#pragma mark - 协议
/***************************************************************
 *  主题观察者协议，需要使用主题的需要实现这个协议，并在协议中更新主题对象
 ***************************************************************/
@protocol AYThemeObserver <NSObject>
- (void)loadTheme:(AYTheme *)theme;/**< 加载主题 */
@end

/***************************************************************
 *  主题基类
 ***************************************************************/
@interface AYTheme : NSObject
- (UIColor *)colorForName:(NSString *)colorName;
- (UIImage *)imageForName:(NSString *)imageName;
- (void)imageForName:(NSString *)imageName asyncCallback:(void (^)(UIImage *image))callback;

#pragma mark - 主题子类需要实现的方法
- (NSDictionary<NSString *, NSString *> *)colorDictionary;/**< 颜色字典 */
- (NSString *)themeNameFor:(NSString *)name;/**< 主题图片名字切换，加前缀或后缀之类 */
- (NSBundle *)imageBundle;/**< 图片存在的位置, 默认为mainBundle，可以将主题图片存放于不同的bundle中 */
@end

