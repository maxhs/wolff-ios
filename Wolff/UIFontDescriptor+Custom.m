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
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @43,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @43,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @39,
                                  UIContentSizeCategoryAccessibilityLarge: @38,
                                  UIContentSizeCategoryAccessibilityMedium: @37,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @41,
                                  UIContentSizeCategoryExtraExtraLarge: @40,
                                  UIContentSizeCategoryExtraLarge: @39,
                                  UIContentSizeCategoryLarge: @38,
                                  UIContentSizeCategoryMedium: @37,
                                  UIContentSizeCategorySmall: @36,
                                  UIContentSizeCategoryExtraSmall: @35},
                          
                          UIFontTextStyleSubheadline: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @31,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @29,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @28,
                                  UIContentSizeCategoryAccessibilityLarge: @27,
                                  UIContentSizeCategoryAccessibilityMedium: @26,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @25,
                                  UIContentSizeCategoryExtraExtraLarge: @24,
                                  UIContentSizeCategoryExtraLarge: @23,
                                  UIContentSizeCategoryLarge: @22,
                                  UIContentSizeCategoryMedium: @21,
                                  UIContentSizeCategorySmall: @20,
                                  UIContentSizeCategoryExtraSmall: @18},
                          
                          UIFontTextStyleBody: @{
                                  UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @24,
                                  UIContentSizeCategoryAccessibilityExtraExtraLarge: @23,
                                  UIContentSizeCategoryAccessibilityExtraLarge: @22,
                                  UIContentSizeCategoryAccessibilityLarge: @21,
                                  UIContentSizeCategoryAccessibilityMedium: @20,
                                  UIContentSizeCategoryExtraExtraExtraLarge: @20,
                                  UIContentSizeCategoryExtraExtraLarge: @19,
                                  UIContentSizeCategoryExtraLarge: @18,
                                  UIContentSizeCategoryLarge: @17,
                                  UIContentSizeCategoryMedium: @16,
                                  UIContentSizeCategorySmall: @15,
                                  UIContentSizeCategoryExtraSmall: @14},
                          
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
