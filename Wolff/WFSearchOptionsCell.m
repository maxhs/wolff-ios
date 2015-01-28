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
    
    [_lightTableButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0]];
    [_lightTableButton.titleLabel setNumberOfLines:0];
    [_lightTableButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_lightTableButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [_lightTableButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    [_slideShowButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0]];
    [_slideShowButton.titleLabel setNumberOfLines:0];
    [_slideShowButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_slideShowButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [_slideShowButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    [_clearSelectedButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0]];
    [_clearSelectedButton.titleLabel setNumberOfLines:0];
    [_clearSelectedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_clearSelectedButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [_clearSelectedButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [self.textLabel setTextColor:[UIColor darkGrayColor]];
    [self.textLabel setTextAlignment:NSTextAlignmentCenter];
    
    _backgroundToolbar = [[UIToolbar alloc] initWithFrame:self.frame];
    [_backgroundToolbar setBarStyle:UIBarStyleBlackTranslucent];
    _backgroundToolbar.translucent = YES;
    [self setBackgroundView:_backgroundToolbar];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
