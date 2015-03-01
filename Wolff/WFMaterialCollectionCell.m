//
//  WFMaterialCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/6/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFMaterialCollectionCell.h"
#import "Constants.h"
#import "Photo+helper.h"
#import "Art+helper.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation WFMaterialCollectionCell

- (void)awakeFromNib{
    [super awakeFromNib];
    [_materialLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_materialLabel setTextColor:[UIColor whiteColor]];
    [_materialLabel setTextAlignment:NSTextAlignmentLeft];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_materialImageView setAlpha:0.0];
}

- (void)configureForMaterial:(Material *)material {
    [_materialLabel setText:material.name];
    __block Photo *coverPhoto;
    [material.arts enumerateObjectsUsingBlock:^(Art *art, NSUInteger idx, BOOL *stop) {
        if (art.photo){
            coverPhoto = art.photo;
            *stop = YES;
        }
    }];
    if (coverPhoto.slideImageUrl.length){
        [_materialImageView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0]];
        [_materialImageView sd_setImageWithURL:[NSURL URLWithString:coverPhoto.slideImageUrl] placeholderImage:nil options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:kFastAnimationDuration animations:^{
                [_materialImageView setAlpha:1.0];
            }];
        }];
    } else {
        [_materialImageView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
        [_materialImageView setImage:nil];
        [_materialImageView setAlpha:1.0];
    }
}

@end
