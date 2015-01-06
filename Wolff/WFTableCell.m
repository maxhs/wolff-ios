//
//  WFGroupCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/13/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFTableCell.h"
#import "Constants.h"

@implementation WFTableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [_tableLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForTable:(Table *)table {
    [_tableLabel setText:table.name];
}

@end
