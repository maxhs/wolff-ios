//
//  WFPhotoTileCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo+helper.h"

@interface WFPhotoTileCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *artImageView;
- (void)configureForPhoto:(Photo*)photo;
@end
