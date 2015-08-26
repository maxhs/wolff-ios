//
//  WFSlidewshowSlideCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slide+helper.h"
#import "PhotoSlide+helper.h"
#import "WFInteractiveImageView.h"
#import <SDWebImage/SDWebImageManager.h>

@interface WFSlideshowSlideCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIView *containerView1;
@property (weak, nonatomic) IBOutlet WFInteractiveImageView *artImageView1;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView1;
@property (weak, nonatomic) IBOutlet UIView *containerView2;
@property (weak, nonatomic) IBOutlet WFInteractiveImageView *artImageView2;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView2;
@property (weak, nonatomic) IBOutlet UIView *containerView3;
@property (weak, nonatomic) IBOutlet WFInteractiveImageView *artImageView3;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView3;
@property (weak, nonatomic) IBOutlet UILabel *mainTextLabel;

@property (strong, nonatomic) id <SDWebImageOperation> imageDownloadOperation;

- (void)configureForPhotos:(NSOrderedSet*)photos inSlide:(Slide*)slide withImageManager:(SDWebImageManager*)imageManager;
//- (void)recenterView:(WFInteractiveImageView*)viewToRecenter;

@end
