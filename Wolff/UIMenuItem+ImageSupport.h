//
//  UIMenuItem+ImageSupport.h
//  Wolff
//
//  Created by Max Haines-Stiles on 9/8/15.
//  Copyright © 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

#if !__has_feature(nullability)

#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#define __nullable

#endif

@class MenuItemSettings;

NS_ASSUME_NONNULL_BEGIN

@interface UIMenuItem (ImageSupport)

- (instancetype)initWithTitle:(NSString *)title action:(SEL)action image:(UIImage *)image;
- (instancetype)initWithTitle:(NSString *)title action:(SEL)action settings:(MenuItemSettings *)settings;
- (void)setImage:(UIImage *)image;
- (void)setSettings:(MenuItemSettings *)settings;

@end

// Uses a settings class instead of NSDictionary to avoid misspelled keys
@interface MenuItemSettings : NSObject <NSCopying>

+ (instancetype)settingsWithDictionary:(NSDictionary *)dict;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic) BOOL shadowDisabled;
@property (nonatomic, strong) UIColor * __nullable shadowColor; // Default is [[UIColor blackColor] colorWithAlphaComponent:1./3.]
@property (nonatomic) CGFloat shrinkWidth; // For adjustment item width only, will not be preciouse because menu item will keep its minimun width, it's useful for showing some large amount of menu items without expanding.

@end

NS_ASSUME_NONNULL_END