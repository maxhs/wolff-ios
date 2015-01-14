//
//  UIFontDescriptor+Custom.m
//  Wolff
//
//  Created by Max Haines-Stiles on 10/12/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "UIFontDescriptor+Custom.h"

@implementation UIFontDescriptor (Custom)

NSString *const ANUIFontTextStyleCaption3 = @"ANUIFontTextStyleCaption3";
NSString *const ANUIFontTextStyleCaption4 = @"ANUIFontTextStyleCaption4";

+ (UIFontDescriptor *)preferredCustomFontForTextStyle:(NSString *)textStyle forFont:(NSString*)font {
    
    static dispatch_once_t onceToken;
    static NSDictionary *fontSizeTable;
    dispatch_once(&onceToken, ^{
        fontSizeTable = @{
                          UIFontTextStyleHeadline: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @40,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @97,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @38,
                                  UIContentSizeCategoryAccessibilityLarge: @37,
                                  UIContentSizeCategoryAccessibilityMedium: @35,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @34,
                                  UIContentSizeCategoryExtraExtraLarge: @33,
                                  UIContentSizeCategoryExtraLarge: @32,
                                  UIContentSizeCategoryLarge: @31,
                                  UIContentSizeCategoryMedium: @30,
                                  UIContentSizeCategorySmall: @29,
                                  UIContentSizeCategoryExtraSmall: @28},
                          
                          UIFontTextStyleSubheadline: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @32,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @30,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @29,
                                  UIContentSizeCategoryAccessibilityLarge: @28,
                                  UIContentSizeCategoryAccessibilityMedium: @27,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @26,
                                  UIContentSizeCategoryExtraExtraLarge: @25,
                                  UIContentSizeCategoryExtraLarge: @24,
                                  UIContentSizeCategoryLarge: @23,
                                  UIContentSizeCategoryMedium: @22,
                                  UIContentSizeCategorySmall: @21,
                                  UIContentSizeCategoryExtraSmall: @19},
                          
                          UIFontTextStyleBody: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @22,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @21,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @20,
                                  UIContentSizeCategoryAccessibilityLarge: @20,
                                  UIContentSizeCategoryAccessibilityMedium: @19,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @19,
                                  UIContentSizeCategoryExtraExtraLarge: @18,
                                  UIContentSizeCategoryExtraLarge: @17,
                                  UIContentSizeCategoryLarge: @16,
                                  UIContentSizeCategoryMedium: @15,
                                  UIContentSizeCategorySmall: @14,
                                  UIContentSizeCategoryExtraSmall: @13},
                          
                          UIFontTextStyleCaption1: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @19,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @18,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @17,
                                  UIContentSizeCategoryAccessibilityLarge: @17,
                                  UIContentSizeCategoryAccessibilityMedium: @16,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @16,
                                  UIContentSizeCategoryExtraExtraLarge: @16,
                                  UIContentSizeCategoryExtraLarge: @15,
                                  UIContentSizeCategoryLarge: @14,
                                  UIContentSizeCategoryMedium: @13,
                                  UIContentSizeCategorySmall: @12,
                                  UIContentSizeCategoryExtraSmall: @12,},
                          
                          UIFontTextStyleCaption2: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @15,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @14,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @13,
                                  UIContentSizeCategoryAccessibilityLarge: @12,
                                  UIContentSizeCategoryAccessibilityMedium: @11,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @15,
                                  UIContentSizeCategoryExtraExtraLarge: @14,
                                  UIContentSizeCategoryExtraLarge: @13,
                                  UIContentSizeCategoryLarge: @12,
                                  UIContentSizeCategoryMedium: @11,
                                  UIContentSizeCategorySmall: @10,
                                  UIContentSizeCategoryExtraSmall: @9},
                          
                          ANUIFontTextStyleCaption3: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @17,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @16,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @15,
                                  UIContentSizeCategoryAccessibilityLarge: @15,
                                  UIContentSizeCategoryAccessibilityMedium: @14,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @14,
                                  UIContentSizeCategoryExtraExtraLarge: @13,
                                  UIContentSizeCategoryExtraLarge: @12,
                                  UIContentSizeCategoryLarge: @12,
                                  UIContentSizeCategoryMedium: @12,
                                  UIContentSizeCategorySmall: @11,
                                  UIContentSizeCategoryExtraSmall: @10,},
                          
                          UIFontTextStyleFootnote: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @16,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @15,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @14,
                                  UIContentSizeCategoryAccessibilityLarge: @13,
                                  UIContentSizeCategoryAccessibilityMedium: @12,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @16,
                                  UIContentSizeCategoryExtraExtraLarge: @15,
                                  UIContentSizeCategoryExtraLarge: @14,
                                  UIContentSizeCategoryLarge: @13,
                                  UIContentSizeCategoryMedium: @11,
                                  UIContentSizeCategorySmall: @10,
                                  UIContentSizeCategoryExtraSmall: @9},
                          
                          ANUIFontTextStyleCaption4: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @15,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @14,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @13,
                                  UIContentSizeCategoryAccessibilityLarge: @13,
                                  UIContentSizeCategoryAccessibilityMedium: @12,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @12,
                                  UIContentSizeCategoryExtraExtraLarge: @11,
                                  UIContentSizeCategoryExtraLarge: @11,
                                  UIContentSizeCategoryLarge: @10,
                                  UIContentSizeCategoryMedium: @10,
                                  UIContentSizeCategorySmall: @9,
                                  UIContentSizeCategoryExtraSmall: @9,},
                          };
    });
    
    NSString *contentSize = [UIApplication sharedApplication].preferredContentSizeCategory;
    return [UIFontDescriptor fontDescriptorWithName:font size:((NSNumber *)fontSizeTable[textStyle][contentSize]).floatValue];
}

@end
