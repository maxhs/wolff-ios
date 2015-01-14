//
//  WFLightTableKeyCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/12/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLightTableKeyCell.h"
#import "Constants.h"

@implementation WFLightTableKeyCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self.label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.label setTextColor:[UIColor colorWithWhite:.7 alpha:.7]];
    
    [self.textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textField setBackgroundColor:kTextFieldBackground];
    self.textField.layer.cornerRadius = 3.f;
    self.textField.clipsToBounds = YES;
    [self.textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    self.textField.leftView = paddingView;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    
    [_joinButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_joinButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _joinButton.layer.cornerRadius = 14.f;
    _joinButton.clipsToBounds = YES;
    [_joinButton setBackgroundColor:[UIColor blackColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
