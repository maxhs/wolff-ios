//
//  WFFlagCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/22/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFFlagCell.h"
#import "Constants.h"

@implementation WFFlagCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_label setText:@""];
    [_textField setText:@""];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
