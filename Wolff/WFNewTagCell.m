//
//  WFNewTagCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 4/5/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFNewTagCell.h"
#import "Constants.h"

@implementation WFNewTagCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [_tagPrompt setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLightItalic] size:0]];
    [_tagPrompt setTextAlignment:NSTextAlignmentLeft];
    
    [self textFieldTreatment:_nameTextField];
    
    [_createButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_createButton setBackgroundColor:[UIColor colorWithWhite:1 alpha:.14]];
    _createButton.layer.cornerRadius = 7.f;
    _createButton.clipsToBounds = YES;
    
    [_nameLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_nameLabel setTextColor:[UIColor colorWithWhite:1 alpha:.77]];
    [_nameLabel setText:@"*CURRENT* LOCATION NAME"];
    [_nameLabel setHidden:YES];
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
