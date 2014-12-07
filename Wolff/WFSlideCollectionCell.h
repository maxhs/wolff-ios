//
//  WFSlideCollectionCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slide+helper.h"

@interface WFSlideCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *slideBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *singleArtImageView;
- (void)configureForSlide:(Slide*)slide;
@end
