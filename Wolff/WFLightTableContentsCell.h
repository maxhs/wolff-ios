//
//  WFLightTableContentsCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/30/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photo+helper.h"
#import "WFInteractiveImageView.h"

@interface WFLightTableContentsCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *slideContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *portraitArtImageView;
@property (weak, nonatomic) IBOutlet UIImageView *landscapeArtImageView;
- (void)configureForPhoto:(Photo*)photo;

@end
