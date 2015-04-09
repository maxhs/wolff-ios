//
//  WFPhotoTileCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFPhotoTileCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation WFPhotoTileCell

- (void)configureForPhoto:(Photo*)photo {
    [self.artImageView sd_setImageWithURL:[NSURL URLWithString:photo.thumbImageUrl] placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [UIView animateWithDuration:.23 animations:^{
            [self.artImageView setAlpha:1.0];
        } completion:^(BOOL finished) {
            [self.artImageView.layer setShouldRasterize:YES];
            self.artImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        }];
    }];
}
@end
