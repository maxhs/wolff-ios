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
}

- (UIImage *)getRasterizedImageCopy {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)configureForArt:(Art *)art {
    //NSLog(@"configure search cell for %@, %@",art.title, art.photo.smallImageUrl);
    if (art.photo.smallImageUrl.length){
        [self.imageView sd_setImageWithURL:[NSURL URLWithString:art.photo.smallImageUrl]  placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            
            [UIView animateWithDuration:.23 animations:^{
                [self.imageView setAlpha:1.0];
            }];
        }];
        
    } /*else {
        [self.imageView setImage:nil];
    }*/
}
@end
