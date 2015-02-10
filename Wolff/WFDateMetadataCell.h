//
//  WFDateMetadataCell.h
//  Wolff
//
//  Created by Max Haines-Stiles on 2/6/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Art+helper.h"

@interface WFDateMetadataCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITextField *beginYearTextField;
@property (weak, nonatomic) IBOutlet UIButton *ceButton;
@property (weak, nonatomic) IBOutlet UIButton *bceButton;
@property (weak, nonatomic) IBOutlet UILabel *eraLabel;
@property (weak, nonatomic) IBOutlet UILabel *circaLabel;
@property (weak, nonatomic) IBOutlet UISwitch *circaSwitch;
- (void)configureForArt:(Art*)art;
@end
