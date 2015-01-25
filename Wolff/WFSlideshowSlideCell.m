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
    [super awakeFromNib];
    [_artImageView1 setAlpha:0.f];
    [_artImageView2 setAlpha:0.f];
    [_artImageView3 setAlpha:0.f];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_artImageView1 setAlpha:0.f];
    [_artImageView1 setImage:nil];
    [_artImageView2 setAlpha:0.f];
    [_artImageView2 setImage:nil];
    [_artImageView3 setAlpha:0.f];
    [_artImageView3 setImage:nil];
}

- (void)configureForPhotos:(NSMutableOrderedSet *)photos inSlide:(Slide *)slide{
    [_artImageView1 setUserInteractionEnabled:YES];
    [_artImageView2 setUserInteractionEnabled:YES];
    [_artImageView3 setUserInteractionEnabled:YES];
    
    if (photos.count == 1){
        [_containerView1 setHidden:NO];
        [_containerView2 setHidden:YES];
        [_containerView3 setHidden:YES];
        Photo *photo = (Photo*)[photos firstObject];
        NSURL *art1thumbUrl = [NSURL URLWithString:photo.thumbImageUrl];
        NSURL *art1originalUrl = [NSURL URLWithString:photo.originalImageUrl];
        
        [_artImageView1 sd_setImageWithURL:art1thumbUrl completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            //if the image is cached, no need to fade it in
            if (cacheType == SDImageCacheTypeNone && _artImageView1.image != nil){
                [UIView animateWithDuration:.27 animations:^{
                    [_artImageView1 setAlpha:1.0];
                    [_progressView1 setAlpha:1.0];
                }];
            } else {
                [_artImageView1 setAlpha:1.0];
                [_progressView1 setAlpha:0.0];
            }
        }];
        [[SDWebImageManager sharedManager] downloadImageWithURL:art1originalUrl options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            [_progressView1 setProgress:((CGFloat)receivedSize/(CGFloat)expectedSize)];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (cacheType == SDImageCacheTypeNone){
                [UIView transitionWithView:_artImageView1 duration:kSlowAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                    _artImageView1.image = image;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:.23 animations:^{
                        [_progressView1 setAlpha:0.0];
                    } completion:^(BOOL finished) {
                        [_progressView1 setHidden:YES];
                    }];
                }];
            } else {
                [_artImageView1 setImage:image];
            }
        }];
        
    } else if (photos.count == 2) {
        [_containerView1 setHidden:YES];
        [_containerView2 setHidden:NO];
        [_containerView3 setHidden:NO];
        
        Photo *photo2 = (Photo*)photos[0];
        NSURL *art2thumbUrl = [NSURL URLWithString:photo2.thumbImageUrl];
        NSURL *art2originalUrl = [NSURL URLWithString:photo2.originalImageUrl];
        
        [_artImageView2 sd_setImageWithURL:art2thumbUrl placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            //if the image is cached, no need to fade it in
            if (cacheType == SDImageCacheTypeNone && _artImageView2.image != nil){
                [UIView animateWithDuration:.27 animations:^{
                    [_artImageView2 setAlpha:1.0];
                    [_progressView2 setAlpha:1.0];
                }];
            } else {
                [_artImageView2 setAlpha:1.0];
                [_progressView2 setAlpha:0.0];
            }
        }];
        
        [[SDWebImageManager sharedManager] downloadImageWithURL:art2originalUrl options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            [_progressView2 setProgress:((CGFloat)receivedSize/(CGFloat)expectedSize)];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        
            [UIView transitionWithView:_artImageView2 duration:kSlowAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                _artImageView2.image = image;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:.23 animations:^{
                    [_progressView2 setAlpha:0.0];
                } completion:^(BOOL finished) {
                    [_progressView2 setHidden:YES];
                }];
            }];
        }];
        
        Photo *photo3 = (Photo*)photos[1];
        NSURL *art3thumbUrl = [NSURL URLWithString:photo3.thumbImageUrl];
        NSURL *art3originalUrl = [NSURL URLWithString:photo3.originalImageUrl];
        
        [_artImageView3 sd_setImageWithURL:art3thumbUrl placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            //if the image is cached, no need to fade it in
            if (cacheType == SDImageCacheTypeNone && _artImageView3.image != nil){
                [UIView animateWithDuration:.27 animations:^{
                    [_artImageView3 setAlpha:1.0];
                    [_progressView3 setAlpha:1.0];
                }];
            } else {
                [_artImageView3 setAlpha:1.0];
                [_progressView3 setAlpha:0.0];
            }
        }];
        
        [[SDWebImageManager sharedManager] downloadImageWithURL:art3originalUrl options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            [_progressView3 setProgress:((CGFloat)receivedSize/(CGFloat)expectedSize)];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {

            [UIView transitionWithView:_artImageView3 duration:kSlowAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                _artImageView3.image = image;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:.23 animations:^{
                    [_progressView3 setAlpha:0.0];
                } completion:^(BOOL finished) {
                    [_progressView3 setHidden:YES];
                }];
            }];
        }];
    }
}

@end
