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
    [_locationPrompt setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLightItalic] size:0]];
    [_locationPrompt setTextAlignment:NSTextAlignmentLeft];
    
    [self textFieldTreatment:_nameTextField];
    [self textFieldTreatment:_countryTextField];
    [self textFieldTreatment:_cityTextField];
    
    [_createButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_createButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
    [_createButton setTitle:@"Add New Location" forState:UIControlStateNormal];
    _createButton.layer.cornerRadius = 7.f;
    _createButton.clipsToBounds = YES;
    
    [_nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_nameLabel setTextColor:[UIColor colorWithWhite:1 alpha:.77]];
    [_nameLabel setText:@"*CURRENT* LOCATION NAME"];
    [_nameLabel setHidden:YES];
    
    [_cityLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_cityLabel setTextColor:[UIColor colorWithWhite:1 alpha:.77]];
    [_cityLabel setText:@"CITY"];
    [_cityLabel setHidden:YES];
    
    [_countryLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_countryLabel setTextColor:[UIColor colorWithWhite:1 alpha:.77]];
    [_countryLabel setText:@"COUNTRY"];
    [_countryLabel setHidden:YES];
    
}

- (void)textFieldTreatment:(UITextField*)textField {
    [textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [textField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
    [textField setTintColor:[UIColor whiteColor]];
    [textField setTextColor:[UIColor whiteColor]];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
    [textField setHidden:YES];
}

@end
