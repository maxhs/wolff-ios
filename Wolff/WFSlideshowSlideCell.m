//
//  WFSlideshowSlideCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideshowSlideCell.h"
#import "WFAppDelegate.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "Constants.h"
#import "SlideText+helper.h"

@interface WFSlideshowSlideCell () {
    
    
}
@end

@implementation WFSlideshowSlideCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [_artImageView1 setAlpha:0.f];
    [_artImageView2 setAlpha:0.f];
    [_artImageView3 setAlpha:0.f];
    [_artImageView1 setMoved:NO];
    [_artImageView2 setMoved:NO];
    [_artImageView3 setMoved:NO];
    [self.mainTextLabel setNumberOfLines:0];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self resetVisibility:_artImageView1];
    [self resetVisibility:_artImageView2];
    [self resetVisibility:_artImageView3];
    [self resetVisibility:_progressView1];
    [self resetVisibility:_progressView2];
    [self resetVisibility:_progressView3];
}

- (void)resetVisibility:(UIView*)view {
    [view setAlpha:0.f];
    if ([view isKindOfClass:[WFInteractiveImageView class]]){
        [(WFInteractiveImageView*)view setImage:nil];
    }
}

- (void)configureForPhotos:(NSOrderedSet *)photos inSlide:(Slide*)slide{
    CGFloat frameHeight = (IDIOM == IPAD) ? 660.f : 300.f;
    CGFloat singleWidth = (IDIOM == IPAD) ? 900.f : 460.f;
    CGFloat splitWidth = (IDIOM == IPAD) ? 480.f : 260.f;
    CGFloat width = screenWidth(); CGFloat height = screenHeight();
  
    if (slide.slideTexts.count) {
        [self.mainTextLabel setHidden:NO];
        [self.mainTextLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
        [self.mainTextLabel setTextColor:[UIColor whiteColor]];
        SlideText *slideText = slide.slideTexts.firstObject;
        [self.mainTextLabel setText:slideText.body];
        if ([slideText.alignment isEqualToNumber:@(WFSlideTextAlignmentCenter)]){
            [self.mainTextLabel setTextAlignment:NSTextAlignmentCenter];
        } else if ([slideText.alignment isEqualToNumber:@(WFSlideTextAlignmentLeft)]){
            [self.mainTextLabel setTextAlignment:NSTextAlignmentLeft];
        } else {
            [self.mainTextLabel setTextAlignment:NSTextAlignmentRight];
        }
        
    } else if (photos.count){
        [self.mainTextLabel setHidden:YES];
        
        [self.artImageView1 setUserInteractionEnabled:YES];
        [self.artImageView2 setUserInteractionEnabled:YES];
        [self.artImageView3 setUserInteractionEnabled:YES];
        
        if (photos.count == 1){
            if (slide && slide.photoSlides.count){
                PhotoSlide *photoSlide1 = slide.photoSlides[0];
                if (photoSlide1.hasValidFrame){
                    [_artImageView1 setFrame:CGRectMake(photoSlide1.positionX.floatValue, photoSlide1.positionY.floatValue, photoSlide1.width.floatValue, photoSlide1.height.floatValue)];
                    NSLog(@"Pre-positioning slide 1: %@ %@, %@ %@",photoSlide1.positionX, photoSlide1.positionY, photoSlide1.width, photoSlide1.height);
                } else {
                    [_artImageView1 setFrame:CGRectMake((width/2-singleWidth/2), (height/2-frameHeight/2), singleWidth, frameHeight)];
                }
            }
            [self.containerView1 setHidden:NO];
            [self.containerView2 setHidden:YES];
            [self.containerView3 setHidden:YES];
        
            Photo *photo1 = photos[0];
            NSURLRequest *artmediumUrlRequest1 = [NSURLRequest requestWithURL:[NSURL URLWithString:photo1.mediumImageUrl]];
            NSURLRequest *artOriginalUrlRequest1 = [NSURLRequest requestWithURL:[NSURL URLWithString:slide ? photo1.largeImageUrl : photo1.originalImageUrl]];
            
            [_artImageView1 setImageWithURLRequest:artmediumUrlRequest1 placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
                [_artImageView1 setImage:image];
                if (response){
                    [UIView animateWithDuration:.27 animations:^{
                        [_artImageView1 setAlpha:1.0];
                    }];
                } else {
                    [_artImageView1 setAlpha:1.0];
                }
                
                [_artImageView1 setImageWithURLRequest:artOriginalUrlRequest1 placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    if (response){
                        [UIView transitionWithView:_artImageView1 duration:kDefaultAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                            _artImageView1.image = image;
                        } completion:NULL];
                    } else {
                        _artImageView1.image = image;
                    }
                } failure:NULL];
            } failure:NULL];
            
        } else if (photos.count > 1) {
            if (slide && slide.photoSlides.count > 1){
                PhotoSlide *photoSlide2 = slide.photoSlides[0];
                if (photoSlide2.hasValidFrame){
                    [_artImageView2 setFrame:CGRectMake(photoSlide2.positionX.floatValue, photoSlide2.positionY.floatValue, photoSlide2.width.floatValue, photoSlide2.height.floatValue)];
                    NSLog(@"Pre-positioning slide 2: %@ %@, %@ %@",photoSlide2.positionX, photoSlide2.positionY, photoSlide2.width, photoSlide2.height);
                } else {
                    [_artImageView2 setFrame:CGRectMake((width/4-splitWidth/2), (height/2-frameHeight/2), splitWidth, frameHeight)];
                }
                PhotoSlide *photoSlide3 = slide.photoSlides[1];
                if (photoSlide3.hasValidFrame){
                    [_artImageView3 setFrame:CGRectMake(photoSlide3.positionX.floatValue, photoSlide3.positionY.floatValue, photoSlide3.width.floatValue, photoSlide3.height.floatValue)];
                    NSLog(@"Pre-positioning slide 3: %@ %@, %@ %@",photoSlide3.positionX, photoSlide3.positionY, photoSlide3.width, photoSlide3.height);
                } else {
                    [_artImageView3 setFrame:CGRectMake((width/4-splitWidth/2), (height/2-frameHeight/2), splitWidth, frameHeight)];
                }
            }
            [self.containerView1 setHidden:YES];
            [self.containerView2 setHidden:NO];
            [self.containerView3 setHidden:NO];

            Photo *photo2 = photos[0];
            NSURLRequest *artMediumUrlRequest2 = [NSURLRequest requestWithURL:[NSURL URLWithString:photo2.mediumImageUrl]];
            NSURLRequest *artOriginalUrlRequest2 = [NSURLRequest requestWithURL:[NSURL URLWithString:slide ? photo2.largeImageUrl : photo2.originalImageUrl]];
            
            [_artImageView2 setImageWithURLRequest:artMediumUrlRequest2 placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
                [_artImageView2 setImage:image];
                if (response){
                    [UIView animateWithDuration:.27 animations:^{
                        [_artImageView2 setAlpha:1.0];
                    }];
                } else {
                    [_artImageView2 setAlpha:1.0];
                }
                
                [_artImageView2 setImageWithURLRequest:artOriginalUrlRequest2 placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    if (response){
                        [UIView transitionWithView:_artImageView2 duration:kDefaultAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                            _artImageView2.image = image;
                        } completion:NULL];
                    } else {
                        _artImageView2.image = image;
                    }
                } failure:NULL];
            } failure:NULL];
            
            Photo *photo3 = photos[1];
            NSURLRequest *artMediumUrlRequest3 = [NSURLRequest requestWithURL:[NSURL URLWithString:photo3.mediumImageUrl]];
            NSURLRequest *artOriginalUrlRequest3 = [NSURLRequest requestWithURL:[NSURL URLWithString:slide ? photo3.largeImageUrl : photo3.originalImageUrl]];
            
            [_artImageView3 setImageWithURLRequest:artMediumUrlRequest3 placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
                [_artImageView3 setImage:image];
                if (response){
                    [UIView animateWithDuration:.27 animations:^{
                        [_artImageView3 setAlpha:1.0];
                    }];
                } else {
                    [_artImageView3 setAlpha:1.0];
                }
                
                [_artImageView3 setImageWithURLRequest:artOriginalUrlRequest3 placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                    if (response){
                        [UIView transitionWithView:_artImageView3 duration:kDefaultAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                            _artImageView3.image = image;
                        } completion:NULL];
                    } else {
                        _artImageView3.image = image;
                    }
                } failure:NULL];
            } failure:NULL];
        }
    }
}

@end