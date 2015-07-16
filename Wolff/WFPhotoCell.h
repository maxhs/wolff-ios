//
//  WFPhotoCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"
#import "Photo+helper.h"

@interface WFPhotoCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIView *slideContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *portraitArtImageView;
@property (weak, nonatomic) IBOutlet UIImageView *landscapeArtImageView;
@property (weak, nonatomic) IBOutlet UIImageView *checkmark;
@property (weak, nonatomic) IBOutlet UILabel *privateLabel;

- (UIImage *)getRasterizedImageCopy;
- (void)configureForPhoto:(Photo*)photo;

@end
