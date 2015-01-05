//
//  WFUtilities.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFUtilities.h"

@implementation WFUtilities
+ (UIImageView *)findNavShadow:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findNavShadow:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}
@end
