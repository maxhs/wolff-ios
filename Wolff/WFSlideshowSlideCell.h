//
//  WFSlidewshowSlideCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slide+helper.h"

@interface WFSlideshowSlideCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *artImageView1;
@property (weak, nonatomic) IBOutlet UIImageView *artImageView2;
@property (weak, nonatomic) IBOutlet UIImageView *artImageView3;
- (void)configureForSlide:(Slide*)slide inView:(UIView*)parentView;
- (void)configureForArts:(NSMutableOrderedSet*)arts inView:(UIView*)parentView;
@end
