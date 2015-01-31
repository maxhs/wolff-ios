//
//  WFSlidewshowSlideCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slide+helper.h"
#import "WFInteractiveImageView.h"

@interface WFSlideshowSlideCell : UICollectionViewCell
@property (strong, nonatomic) Slide *slide;
@property (strong, nonatomic) NSMutableOrderedSet *photos;
@property (weak, nonatomic) IBOutlet UIView *containerView1;
@property (weak, nonatomic) IBOutlet WFInteractiveImageView *artImageView1;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView1;
@property (weak, nonatomic) IBOutlet UIView *containerView2;
@property (weak, nonatomic) IBOutlet WFInteractiveImageView *artImageView2;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView2;
@property (weak, nonatomic) IBOutlet UIView *containerView3;
@property (weak, nonatomic) IBOutlet WFInteractiveImageView *artImageView3;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView3;

- (void)configureForPhotos:(NSMutableOrderedSet*)photos inSlide:(Slide*)slide;
- (void)recenterView:(WFInteractiveImageView*)viewToRecenter;

@end
