//
//  WFSlideMetadataCollectionCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 4/27/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Slide+helper.h"

@interface WFSlideMetadataCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
- (void)configureForPhotoSlide:(PhotoSlide*)photoSlide;
@end