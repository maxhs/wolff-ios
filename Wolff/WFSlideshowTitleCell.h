//
//  WFSlideshowTitleCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/23/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slideshow+helper.h"

@interface WFSlideshowTitleCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *institutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *wolffLabel;
@property (weak, nonatomic) IBOutlet UIImageView *wolffIcon;

- (void)configureForSlideshow:(Slideshow*)slideshow;

@end
