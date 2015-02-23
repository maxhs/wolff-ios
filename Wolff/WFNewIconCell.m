//
//  WFNewIconCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/13/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFNewIconCell.h"
#import "Constants.h"

@implementation WFNewIconCell

- (void)awakeFromNib{
    [super awakeFromNib];
    [_prompt setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLightItalic] size:0]];
    
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_label setTextColor:[UIColor colorWithWhite:1 alpha:.77]];
    [_label setText:@"NEW ICONOGRAPHY"];
    [_label setHidden:YES];
    
    [_iconNameTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
    [_iconNameTextField setTintColor:[UIColor whiteColor]];
    [_iconNameTextField setTextColor:[UIColor whiteColor]];
    [_iconNameTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    _iconNameTextField.leftView = paddingView;
    _iconNameTextField.leftViewMode = UITextFieldViewModeAlways;
    
    [_createButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_createButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
    _createButton.layer.cornerRadius = 7.f;
    _createButton.clipsToBounds = YES;
}

@end
