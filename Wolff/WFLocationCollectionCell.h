//
//  WFLocationCollectionCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Location+helper.h"

@interface WFLocationCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *locationCoverImage;
@property (weak, nonatomic) IBOutlet UILabel *locationNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkmark;

- (void)configureForLocation:(Location*)location;
@end
