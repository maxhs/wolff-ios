//
//  WFProfileHeader.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/1/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User+helper.h"
@interface WFProfileHeader : UICollectionReusableView
@property (weak, nonatomic) IBOutlet UIButton *userPhotoButton;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *institutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *userSinceLabel;
@property (weak, nonatomic) IBOutlet UIButton *photoCountButton;
@property (weak, nonatomic) IBOutlet UIButton *slideshowsButton;
@property (weak, nonatomic) IBOutlet UIButton *lightTablesButton;
@property (weak, nonatomic) IBOutlet UIButton *urlButton;
- (void)configureForUser:(User*)user;
@end
