//
//  WFSlideshowSlideCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideshowSlideCell.h"
#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "Constants.h"

@interface WFSlideshowSlideCell () {
    
}

@end

@implementation WFSlideshowSlideCell

- (void)awakeFromNib {
    [_artImageView1 setAlpha:0.f];
    [_artImageView2 setAlpha:0.f];
    [_artImageView3 setAlpha:0.f];
}

- (void)prepareForReuse {
    [_artImageView1 setAlpha:0.f];
    [_artImageView2 setAlpha:0.f];
    [_artImageView3 setAlpha:0.f];
}

- (void)configureForArts:(NSMutableOrderedSet *)arts inSlide:(Slide *)slide{
    [_artImageView1 setUserInteractionEnabled:YES];
    [_artImageView2 setUserInteractionEnabled:YES];
    [_artImageView3 setUserInteractionEnabled:YES];
    
    if (arts.count == 1){
        [_containerView1 setHidden:NO];
        [_containerView2 setHidden:YES];
        [_containerView3 setHidden:YES];
        Art *art = (Art*)[arts firstObject];
        NSLog(@"configuring for single art: %@",art.title);
        NSURL *art1thumbUrl = [NSURL URLWithString:art.photo.thumbImageUrl];
        NSURL *art1originalUrl = [NSURL URLWithString:art.photo.originalImageUrl];
        
        [_artImageView1 sd_setImageWithURL:art1thumbUrl completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.27 animations:^{
                [_artImageView1 setAlpha:1.0];
            }];
        }];
        [[SDWebImageManager sharedManager] downloadImageWithURL:art1originalUrl options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            UIImage *fullImage = image;
            [UIView transitionWithView:_artImageView1 duration:kDefaultAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                _artImageView1.image = fullImage;
            } completion:^(BOOL finished) {
                _artImageView1.layer.shouldRasterize = YES;
                _artImageView1.layer.rasterizationScale = [UIScreen mainScreen].scale;
            }];
        }];
        
    } else {
        [_containerView1 setHidden:YES];
        [_containerView2 setHidden:NO];
        [_containerView3 setHidden:NO];
        
        NSURL *art2thumbUrl = [NSURL URLWithString:[[(Art*)[arts firstObject] photo] mediumImageUrl]];
        NSURL *art2originalUrl = [NSURL URLWithString:[[(Art*)[arts firstObject] photo] originalImageUrl]];
        
        [_artImageView2 sd_setImageWithURL:art2thumbUrl placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.27 animations:^{
                [_artImageView2 setAlpha:1.0];
            }];
        }];
        
        [[SDWebImageManager sharedManager] downloadImageWithURL:art2originalUrl options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            UIImage *fullImage = image;
            [UIView transitionWithView:_artImageView2 duration:kDefaultAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                _artImageView2.image = fullImage;
            } completion:^(BOOL finished) {
                _artImageView2.layer.shouldRasterize = YES;
                _artImageView2.layer.rasterizationScale = [UIScreen mainScreen].scale;
            }];
        }];
        
        NSURL *art3thumbUrl = [NSURL URLWithString:[[(Art*)arts[1] photo] mediumImageUrl]];
        NSURL *art3originalUrl = [NSURL URLWithString:[[(Art*)arts[1] photo] originalImageUrl]];
        
        [_artImageView3 sd_setImageWithURL:art3thumbUrl  placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.27 animations:^{
                [_artImageView3 setAlpha:1.0];
            }];
        }];
        
        [[SDWebImageManager sharedManager] downloadImageWithURL:art3originalUrl options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            UIImage *fullImage = image;
            [UIView transitionWithView:_artImageView3 duration:kDefaultAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                _artImageView3.image = fullImage;
            } completion:^(BOOL finished) {
                _artImageView3.layer.shouldRasterize = YES;
                _artImageView3.layer.rasterizationScale = [UIScreen mainScreen].scale;
            }];
        }];
    }
}

@end
