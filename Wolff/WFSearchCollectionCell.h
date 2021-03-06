//
//  WFSearchCollectionCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/1/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo+helper.h"

@interface WFSearchCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *checkmark;
- (UIImage *)getRasterizedImageCopy;
- (void)configureForPhoto:(Photo*)photo;
@end
