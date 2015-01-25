//
//  WFSearchCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/1/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSearchCollectionCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation WFSearchCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.imageView setAlpha:0.0];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
    //self.imageView.clipsToBounds = YES;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imageView setAlpha:0.0];
}

- (UIImage *)getRasterizedImageCopy {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)configureForPhoto:(Photo *)photo {
    if (photo.thumbImageUrl.length){
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:photo.thumbImageUrl] placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.23 animations:^{
                [self.imageView setAlpha:1.0];
            }];
        }];
        
    }
}
@end
