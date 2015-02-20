//
//  WFIconCollectionCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/13/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Icon+helper.h"

@interface WFIconCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIImageView *checkmark;
@property (weak, nonatomic) IBOutlet UILabel *iconLabel;
- (void)configureForIcon:(Icon*)icon;

@end
