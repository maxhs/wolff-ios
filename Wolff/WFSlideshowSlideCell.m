//
//  WFSlideshowSlideCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideshowSlideCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface WFSlideshowSlideCell () {
    UIView *_parentView;
    UIPanGestureRecognizer *_panGesture;
    UIPinchGestureRecognizer *_pinchGesture;
}

@end

@implementation WFSlideshowSlideCell

- (void)awakeFromNib {
    [_artImageView1 setAlpha:0.f];
    [_artImageView2 setAlpha:0.f];
    [_artImageView3 setAlpha:0.f];
}

- (void)configureForSlide:(Slide *)slide inView:(UIView*)parentView {
    _parentView = parentView;
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    }
    if (!_pinchGesture) {
        _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    }
    
    if (slide.arts.count == 1){
        [_artImageView1 setHidden:NO];
        [_artImageView2 setHidden:YES];
        [_artImageView3 setHidden:YES];
        [_artImageView1 sd_setImageWithURL:[NSURL URLWithString:[[(Art*)[slide.arts firstObject] photo] largeImageUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.27 animations:^{
                [_artImageView1 setAlpha:1.0];
            }];
        }];
    } else if (slide.arts.count > 1) {
        [_artImageView1 setHidden:YES];
        [_artImageView2 setHidden:NO];
        [_artImageView3 setHidden:NO];
        
        [_artImageView2 sd_setImageWithURL:[NSURL URLWithString:[[(Art*)[slide.arts firstObject] photo] largeImageUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.27 animations:^{
                [_artImageView2 setAlpha:1.0];
            }];
            
        }];
        
        [_artImageView3 sd_setImageWithURL:[NSURL URLWithString:[[(Art*)slide.arts[1] photo] largeImageUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.27 animations:^{
                [_artImageView3 setAlpha:1.0];
            }];
        }];
        
    } else {
        [_artImageView1 setImage:nil];
        [_artImageView2 setImage:nil];
        [_artImageView3 setImage:nil];
    }
}

- (void)configureForArts:(NSMutableOrderedSet *)arts inView:(UIView*)parentView {
    _parentView = parentView;
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    }
    if (!_pinchGesture) {
        _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    }
    
    if (arts.count == 1){
        [_artImageView1 setHidden:NO];
        [_artImageView2 setHidden:YES];
        [_artImageView3 setHidden:YES];
        [_artImageView1 sd_setImageWithURL:[NSURL URLWithString:[[(Art*)[arts firstObject] photo] largeImageUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.27 animations:^{
                [_artImageView1 setAlpha:1.0];
            }];
        }];
    } else {
        [_artImageView1 setHidden:YES];
        [_artImageView2 setHidden:NO];
        [_artImageView3 setHidden:NO];
        
        [_artImageView2 sd_setImageWithURL:[NSURL URLWithString:[[(Art*)[arts firstObject] photo] largeImageUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.27 animations:^{
                [_artImageView2 setAlpha:1.0];
            }];
            
        }];
        
        [_artImageView3 sd_setImageWithURL:[NSURL URLWithString:[[(Art*)arts[1] photo] largeImageUrl]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.27 animations:^{
                [_artImageView3 setAlpha:1.0];
            }];
        }];
        
    }
}

- (void)handlePan:(UIPanGestureRecognizer*)sender {
    CGPoint touchLocation = [sender locationInView:_parentView];
    sender.view.center = touchLocation;
}

- (void)handlePinch:(UIPinchGestureRecognizer*)sender {
    sender.view.transform = CGAffineTransformScale(sender.view.transform, sender.scale, sender.scale);
    sender.scale = 1.f;
}

@end
