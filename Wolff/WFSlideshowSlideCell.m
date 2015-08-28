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
  
    if (photos.count){
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

            
        }
    } else if (slide.slideTexts.count) {
        [self.mainTextLabel setHidden:NO];
        [self.mainTextLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
        [self.mainTextLabel setTextColor:[UIColor whiteColor]];
        SlideText *slideText = slide.slideTexts.firstObject;
        [self.mainTextLabel setText:slideText.body];
    }
}

@end