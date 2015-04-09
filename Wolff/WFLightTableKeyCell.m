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
    [_headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [_headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:.9]];
    
    [self.label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [self.label setTextColor:[UIColor colorWithWhite:1 alpha:.37]];
    
    [self.textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textField setBackgroundColor:kTextFieldBackground];
    self.textField.layer.cornerRadius = 3.f;
    self.textField.clipsToBounds = YES;
    [self.textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    self.textField.leftView = paddingView;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    [self.textField setTintColor:[UIColor blackColor]];
    
    [_joinButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_joinButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _joinButton.layer.cornerRadius = 14.f;
    _joinButton.clipsToBounds = YES;
    [_joinButton setUserInteractionEnabled:YES];
    [_joinButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.077]];
    _joinButton.enabled = NO;
}

@end
