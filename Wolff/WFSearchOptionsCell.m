//
//  WFSearchOptionsCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSearchOptionsCell.h"
#import "Constants.h"

@implementation WFSearchOptionsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    
    [_slideShowButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_slideShowButton.titleLabel setNumberOfLines:0];
    [_slideShowButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [_slideShowButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    /*CGRect slideShowButtonFrame = _slideShowButton.frame;
    slideShowButtonFrame.size.width = self.frame.size.width/2;
    slideShowButtonFrame.origin.x = 0;
    [_slideShowButton setFrame:slideShowButtonFrame];*/
    
    [_lightTableButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
    [_lightTableButton.titleLabel setNumberOfLines:0];
    [_lightTableButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [_lightTableButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [_lightTableButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    /*CGRect lightTableFrame = _lightTableButton.frame;
    lightTableFrame.size.width = self.frame.size.width/2;
    lightTableFrame.origin.x = self.frame.size.width/2;
    [_lightTableButton setFrame:lightTableFrame];*/
    
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textLabel setTextColor:[UIColor darkGrayColor]];
    [self.textLabel setTextAlignment:NSTextAlignmentCenter];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
