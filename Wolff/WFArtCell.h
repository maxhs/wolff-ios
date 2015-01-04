//
//  WFArtCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"

@interface WFArtCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIView *slideContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *portraitArtImageView;
@property (weak, nonatomic) IBOutlet UIImageView *landscapeArtImageView;
@property (weak, nonatomic) IBOutlet UIImageView *checkmark;

- (UIImage *)getRasterizedImageCopy;
- (void)configureForArt:(Art*)art;

@end
