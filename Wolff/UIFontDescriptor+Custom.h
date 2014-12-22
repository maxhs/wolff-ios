//
//  UIFontDescriptor+Custom.h
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFontDescriptor (Custom)

+ (UIFontDescriptor *)preferredLatoFontForTextStyle:(NSString *)textStyle forFont:(NSString *)font;

@end
