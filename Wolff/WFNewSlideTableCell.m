//
//  WFNewSlideTableCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFNewSlideTableCell.h"
#import "Constants.h"

@implementation WFNewSlideTableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor colorWithWhite:1 alpha:.17]];
    [_slideContainerView setBackgroundColor:[UIColor blackColor]];
    [_addPromptButton.titleLabel setFont:[UIFont fontWithName:kMuseoSansThin size:50]];
    [_addPromptButton setHidden:NO];
    [_addPromptButton setTitleColor:[UIColor colorWithWhite:1 alpha:.33] forState:UIControlStateNormal];
    [_addPromptButton.titleLabel setNumberOfLines:0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
