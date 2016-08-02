//
//  AYMethodSwizzling.h
//  AYStyle
//
//  Created by Alan Yeh on 16/8/2.
//
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface AYMethodSwizzling : NSObject
+ (void)swizzlingMethodWithSelector:(SEL)aSelector toIMP:(id)block;
@end
