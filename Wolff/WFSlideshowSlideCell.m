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
@synthesize slide = _slide;

- (void)awakeFromNib {
    [super awakeFromNib];
    [_artImageView1 setAlpha:0.f];
    [_artImageView2 setAlpha:0.f];
    [_artImageView3 setAlpha:0.f];
    [_artImageView1 setMoved:NO];
    [_artImageView2 setMoved:NO];
    [_artImageView3 setMoved:NO];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [_progressView1 setAlpha:1.0];
    [_progressView1 setHidden:NO];
    [_progressView2 setAlpha:1.0];
    [_progressView2 setHidden:NO];
    [_progressView3 setAlpha:1.0];
    [_progressView3 setHidden:NO];
    
    [self recenterView:_artImageView1];
    [self recenterView:_artImageView2];
    [self recenterView:_artImageView3];
}

- (void)recenterView:(WFInteractiveImageView*)viewToRecenter{
    [viewToRecenter setAlpha:0.f];
    [viewToRecenter setImage:nil];
    
    viewToRecenter.transform = CGAffineTransformIdentity;
    CGRect newFrame = viewToRecenter.frame;
    if (viewToRecenter == _artImageView1){
        newFrame.origin.x = (_containerView1.frame.size.width-newFrame.size.width) / 2;
        newFrame.origin.y = (_containerView1.frame.size.height-newFrame.size.height) / 2;
    } else if (viewToRecenter == _artImageView2){
        newFrame.origin.x = (_containerView2.frame.size.width-newFrame.size.width) / 2;
        newFrame.origin.y = (_containerView2.frame.size.height-newFrame.size.height) / 2;
    } else if (viewToRecenter == _artImageView3){
        newFrame.origin.x = (_containerView3.frame.size.width-newFrame.size.width) / 2;
        newFrame.origin.y = (_containerView3.frame.size.height-newFrame.size.height) / 2;
    }
    [viewToRecenter setFrame:newFrame];
}

- (void)configureForPhotos:(NSMutableOrderedSet *)photos inSlide:(Slide *)slide{
    if (slide) _slide = slide;
    [_artImageView1 setUserInteractionEnabled:YES];
    [_artImageView2 setUserInteractionEnabled:YES];
    [_artImageView3 setUserInteractionEnabled:YES];
    
    if (photos.count == 1){
        [_containerView1 setHidden:NO];
        [_containerView2 setHidden:YES];
        [_containerView3 setHidden:YES];
        if (slide.rectString1.length){
            CGRect savedFrame = CGRectFromString(slide.rectString1);
            [_artImageView1 setFrame:savedFrame];
        }
        Photo *photo = (Photo*)[photos firstObject];
        NSURL *art1thumbUrl = [NSURL URLWithString:photo.thumbImageUrl];
        NSURL *art1originalUrl = [NSURL URLWithString:photo.originalImageUrl];
        
        [_artImageView1 sd_setImageWithURL:art1thumbUrl placeholderImage:nil options:SDWebImageLowPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            //if the image is cached, no need to fade it in slowly
            if (cacheType == SDImageCacheTypeNone && _artImageView1.image != nil){
                [UIView animateWithDuration:.27 animations:^{
                    [_artImageView1 setAlpha:1.0];
                    [_progressView1 setAlpha:1.0];
                }];
            } else {
                [UIView animateWithDuration:.14 animations:^{
                    [_artImageView1 setAlpha:1.0];
                    [_progressView1 setAlpha:1.0];
                }];
            }
            if (!slide.originalRectString1.length){
                slide.originalRectString1 = NSStringFromCGRect(_artImageView1.frame);
            }
        }];
        [[SDWebImageManager sharedManager] downloadImageWithURL:art1originalUrl options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            [_progressView1 setProgress:((CGFloat)receivedSize/(CGFloat)expectedSize)];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            CGFloat duration = cacheType == SDImageCacheTypeNone ?  kSlowAnimationDuration : kFastAnimationDuration;
            [_progressView1 setAlpha:1.0];
            [UIView transitionWithView:_artImageView1 duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                _artImageView1.image = image;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:.23 animations:^{
                    [_progressView1 setAlpha:0.0];
                } completion:^(BOOL finished) {
                    
                }];
            }];
        }];
        
    } else if (photos.count == 2) {
        [_containerView1 setHidden:YES];
        [_containerView2 setHidden:NO];
        [_containerView3 setHidden:NO];
        
        if (slide.rectString2.length){
            CGRect savedFrame = CGRectFromString(slide.rectString2);
            [_artImageView2 setFrame:savedFrame];
        }
        if (slide.rectString3.length){
            CGRect savedFrame = CGRectFromString(slide.rectString3);
            [_artImageView3 setFrame:savedFrame];
        }
        
        Photo *photo2 = (Photo*)photos[0];
        NSURL *art2thumbUrl = [NSURL URLWithString:photo2.thumbImageUrl];
        NSURL *art2originalUrl = [NSURL URLWithString:photo2.originalImageUrl];
        
        [_artImageView2 sd_setImageWithURL:art2thumbUrl placeholderImage:nil options:SDWebImageLowPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            //if the image is cached, no need to fade it in
            if (cacheType == SDImageCacheTypeNone && _artImageView2.image != nil){
                [UIView animateWithDuration:.27 animations:^{
                    [_artImageView2 setAlpha:1.0];
                    [_progressView2 setAlpha:1.0];
                }];
            } else {
                [UIView animateWithDuration:.14 animations:^{
                    [_artImageView2 setAlpha:1.0];
                    [_progressView2 setAlpha:1.0];
                }];
            }
            if (!slide.originalRectString2.length){
                slide.originalRectString2 = NSStringFromCGRect(_artImageView2.frame);
            }
        }];
        
        [[SDWebImageManager sharedManager] downloadImageWithURL:art2originalUrl options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            [_progressView2 setProgress:((CGFloat)receivedSize/(CGFloat)expectedSize)];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            CGFloat duration = cacheType == SDImageCacheTypeNone ?  kSlowAnimationDuration : kFastAnimationDuration;
            [_progressView2 setAlpha:1.0];
            [UIView transitionWithView:_artImageView2 duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                _artImageView2.image = image;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:.23 animations:^{
                    [_progressView2 setAlpha:0.0];
                } completion:^(BOOL finished) {

                }];
            }];
        }];
        
        Photo *photo3 = (Photo*)photos[1];
        NSURL *art3thumbUrl = [NSURL URLWithString:photo3.thumbImageUrl];
        NSURL *art3originalUrl = [NSURL URLWithString:photo3.originalImageUrl];
        
        [_artImageView3 sd_setImageWithURL:art3thumbUrl placeholderImage:nil options:SDWebImageLowPriority completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            //if the image is cached, no need to fade it in
            if (cacheType == SDImageCacheTypeNone && _artImageView3.image != nil){
                [UIView animateWithDuration:.27 animations:^{
                    [_artImageView3 setAlpha:1.0];
                    [_progressView3 setAlpha:1.0];
                }];
            } else {
                [UIView animateWithDuration:.14 animations:^{
                    [_artImageView3 setAlpha:1.0];
                    [_progressView3 setAlpha:1.0];
                }];
            }
            if (!slide.originalRectString3.length){
                slide.originalRectString3 = NSStringFromCGRect(_artImageView3.frame);
            }
        }];
        
        [[SDWebImageManager sharedManager] downloadImageWithURL:art3originalUrl options:SDWebImageLowPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
            [_progressView3 setProgress:((CGFloat)receivedSize/(CGFloat)expectedSize)];
        } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            CGFloat duration = cacheType == SDImageCacheTypeNone ?  kSlowAnimationDuration : kFastAnimationDuration;
            [_progressView3 setAlpha:1.0];
            [UIView transitionWithView:_artImageView3 duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                _artImageView3.image = image;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:.23 animations:^{
                    [_progressView3 setAlpha:0.0];
                } completion:^(BOOL finished) {
                    
                }];
            }];
        }];
    }
}

@end
