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
@property (weak, nonatomic) IBOutlet UILabel *rangeLabel;
@property (weak, nonatomic) IBOutlet UILabel *fromLabel;
@property (weak, nonatomic) IBOutlet UILabel *toLabel;
@property (weak, nonatomic) IBOutlet UITextField *singleYearTextField;
@property (weak, nonatomic) IBOutlet UITextField *beginYearTextField;
@property (weak, nonatomic) IBOutlet UITextField *endYearTextField;
@property (weak, nonatomic) IBOutlet UIButton *eraButton;
@property (weak, nonatomic) IBOutlet UIButton *beginEraButton;
@property (weak, nonatomic) IBOutlet UIButton *endEraButton;
@property (weak, nonatomic) IBOutlet UILabel *circaLabel;
@property (weak, nonatomic) IBOutlet UISwitch *circaSwitch;
@property (weak, nonatomic) IBOutlet UILabel *orLabel;
- (void)configureArt:(Art*)art forEditMode:(BOOL)editMode;
@end
