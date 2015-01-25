//
//  WFLightTableDetailsCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLightTableDetailsCell.h"
#import "Constants.h"

@implementation WFLightTableDetailsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    
    [_headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [_headerLabel setTextColor:[UIColor colorWithWhite:0 alpha:.9]];
    
    [self labelTreatment:_titleLabel];
    [_titleLabel setText:@"NAME"];
    [self labelTreatment:_descriptionLabel];
    [_descriptionLabel setText:@"DESCRIPTION"];
    [self labelTreatment:_keyLabel];
    [_keyLabel setText:@"TABLE KEY"];
    [self labelTreatment:_confirmKeyLabel];
    [_confirmKeyLabel setText:@"CONFIRM TABLE KEY"];
    
    [self textFieldTreatment:_titleTextField];
    [self textFieldTreatment:_keyTextField];
    [self textFieldTreatment:_confirmKeyTextField];
    
    [self.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textView setBackgroundColor:kTextFieldBackground];
    self.textView.layer.cornerRadius = 3.f;
    self.textView.clipsToBounds = YES;
    [self.textView setKeyboardAppearance:UIKeyboardAppearanceDark];
    
    [_actionButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _actionButton.layer.cornerRadius = 14.f;
    _actionButton.clipsToBounds = YES;
    [_actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.1]];
}

- (void)textFieldTreatment:(UITextField*)textField {
    [textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [textField setBackgroundColor:kTextFieldBackground];
    textField.layer.cornerRadius = 3.f;
    textField.clipsToBounds = YES;
    [textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
    [textField setTintColor:[UIColor blackColor]];
}

- (void)labelTreatment:(UILabel*)label {
    [label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [label setTextColor:[UIColor colorWithWhite:0 alpha:.23]];
}

@end
