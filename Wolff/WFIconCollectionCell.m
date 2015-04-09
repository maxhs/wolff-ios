//
//  WFIconCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/13/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFIconCollectionCell.h"
#import "Constants.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation WFIconCollectionCell

- (void)awakeFromNib{
    [super awakeFromNib];
    [_iconLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_iconLabel setTextColor:[UIColor whiteColor]];
    [_iconLabel setTextAlignment:NSTextAlignmentLeft];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_iconImageView setAlpha:0.0];
}

- (void)configureForIcon:(Icon *)icon{
    [_iconLabel setText:icon.name];
    if (icon.photos.count && icon.coverPhoto.thumbImageUrl){
        [_iconImageView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0]];
        [_iconImageView sd_setImageWithURL:[NSURL URLWithString:icon.coverPhoto.thumbImageUrl] placeholderImage:nil options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
                [_iconImageView setAlpha:1.0];
            }];
        }];
    } else {
        [_iconImageView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1]];
        [_iconImageView setImage:nil];
        [_iconImageView setAlpha:1.0];
    }
    [self setUserInteractionEnabled:YES];
}

@end
