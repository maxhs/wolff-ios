//
//  WFPartnerProfileHeader.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/8/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Partner+helper.h"

@interface WFPartnerProfileHeader : UICollectionReusableView

@property (weak, nonatomic) IBOutlet UIButton *partnerPhotoButton;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *partnerSinceLabel;
@property (weak, nonatomic) IBOutlet UIButton *photoCountButton;
@property (weak, nonatomic) IBOutlet UIButton *slideshowsButton;
@property (weak, nonatomic) IBOutlet UIButton *lightTablesButton;
@property (weak, nonatomic) IBOutlet UIButton *urlButton;
- (void)configureForPartner:(Partner*)partner;

@end
