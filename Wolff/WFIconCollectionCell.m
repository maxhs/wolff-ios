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
    [_iconImageView setContentMode:UIViewContentModeScaleAspectFit];
    [_iconLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_iconLabel setTextColor:[UIColor whiteColor]];
}

- (void)configureForIcon:(Icon *)icon{
    [_iconLabel setText:icon.name];
    if (icon.photos.count){
        if (icon.coverPhoto.mediumImageUrl){
            [_iconImageView sd_setImageWithURL:[NSURL URLWithString:icon.coverPhoto.mediumImageUrl] placeholderImage:nil options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                
            }];
        }
    }
    [self setUserInteractionEnabled:YES];
}

@end
