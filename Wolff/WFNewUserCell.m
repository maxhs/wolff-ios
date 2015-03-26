//
//  WFNewUserCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 3/15/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFNewUserCell.h"
#import "Constants.h"

@implementation WFNewUserCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [_userPrompt setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLightItalic] size:0]];
    
    [_nameTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];

    [_createButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_createButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
    _createButton.layer.cornerRadius = 7.f;
    _createButton.clipsToBounds = YES;
    
    [_nameTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
    [_nameTextField setTintColor:[UIColor whiteColor]];
    [_nameTextField setTextColor:[UIColor whiteColor]];
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    _nameTextField.leftView = paddingView;
    _nameTextField.leftViewMode = UITextFieldViewModeAlways;
    
    [_nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_nameLabel setTextColor:[UIColor colorWithWhite:1 alpha:.77]];
    [_nameLabel setText:@"USER NAME"];
    [_nameLabel setHidden:YES];
}

- (void)prepareForReuse {
    [super prepareForReuse];
}

@end
