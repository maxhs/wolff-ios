//
//  WFUserCollectionCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 3/15/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User+helper.h"

@interface WFUserCollectionCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userProfileImage;
@property (weak, nonatomic) IBOutlet UIImageView *checkmark;

- (void)configureForUser:(User*)user;
@end
