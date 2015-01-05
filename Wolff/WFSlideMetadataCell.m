//
//  WFSlideMetadataCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSlideMetadataCell.h"
#import "Constants.h"

@implementation WFSlideMetadataCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textLabel setTextColor:[UIColor whiteColor]];
    [self setBackgroundColor:[UIColor clearColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
