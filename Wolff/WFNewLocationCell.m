//
//  WFNewLocationCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFNewLocationCell.h"
#import "Constants.h"

@implementation WFNewLocationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [_locationPrompt setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
    [_locationPrompt setTextAlignment:NSTextAlignmentLeft];
    
    [_nameTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_nameTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
    [_nameTextField setTintColor:[UIColor whiteColor]];
    [_nameTextField setTextColor:[UIColor whiteColor]];
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    _nameTextField.leftView = paddingView;
    _nameTextField.leftViewMode = UITextFieldViewModeAlways;
    
    [_countryTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_countryTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
    [_countryTextField setTintColor:[UIColor whiteColor]];
    [_countryTextField setTextColor:[UIColor whiteColor]];
    
    UIView *countryPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    _countryTextField.leftView = countryPaddingView;
    _countryTextField.leftViewMode = UITextFieldViewModeAlways;
    
    [_cityTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_cityTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
    [_cityTextField setTintColor:[UIColor whiteColor]];
    [_cityTextField setTextColor:[UIColor whiteColor]];
    
    UIView *cityPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    _cityTextField.leftView = cityPaddingView;
    _cityTextField.leftViewMode = UITextFieldViewModeAlways;
    
    [_createButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_createButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
    _createButton.layer.cornerRadius = 7.f;
    _createButton.clipsToBounds = YES;
    
    [_nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_nameLabel setTextColor:[UIColor colorWithWhite:1 alpha:.77]];
    [_nameLabel setText:@"CURRENT LOCATION NAME"];
    [_nameLabel setHidden:YES];
    
    [_cityLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_cityLabel setTextColor:[UIColor colorWithWhite:1 alpha:.77]];
    [_cityLabel setText:@"CITY"];
    [_cityLabel setHidden:YES];
    
    [_countryLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_countryLabel setTextColor:[UIColor colorWithWhite:1 alpha:.77]];
    [_countryLabel setText:@"CURRENT COUNTRY"];
    [_countryLabel setHidden:YES];
    
}

@end
