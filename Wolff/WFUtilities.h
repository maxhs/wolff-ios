//
//  WFUtilities.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WFUtilities : NSObject
+ (UIImageView *)findNavShadow:(UIView *)view;
+ (NSDate*)parseDate:(id)value;
+ (NSDate*)parseDateTime:(id)value;
+ (NSString*)parseDateReturnString:(id)value;
+ (NSString*)parseDateTimeReturnString:(id)value;
+ (UIImage *)fixOrientation:(UIImage*)image;
@end
