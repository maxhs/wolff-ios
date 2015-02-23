//
//  WFBillingCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/17/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFBillingCell.h"
#import "Constants.h"
#import <DateTools/DateTools.h>

@implementation WFBillingCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textLabel setTextColor:[UIColor whiteColor]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self setAccessoryType:UITableViewCellAccessoryNone];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForCard:(Card *)card {
    [self.textLabel setText:[NSString stringWithFormat:@"**** %@ added %@",card.last4,card.createdDate.timeAgoSinceNow]];
}

@end
