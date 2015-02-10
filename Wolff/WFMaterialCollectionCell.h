//
//  WFMaterialCollectionCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/6/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Material+helper.h"

@interface WFMaterialCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *materialImageView;
@property (weak, nonatomic) IBOutlet UIImageView *checkmark;
@property (weak, nonatomic) IBOutlet UILabel *materialLabel;
- (void)configureForMaterial:(Material*)material;

@end
