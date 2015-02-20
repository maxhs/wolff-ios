//
//  WFDateMetadataCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/6/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFDateMetadataCell.h"
#import "Constants.h"

@implementation WFDateMetadataCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setBackgroundColor:[UIColor clearColor]];
    
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_label setTextColor:[UIColor whiteColor]];
    [_rangeLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_rangeLabel setTextColor:[UIColor whiteColor]];
    
    [_orLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
    [_orLabel setTextColor:[UIColor colorWithWhite:1 alpha:.23]];
    
    [_circaLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_circaLabel setTextColor:[UIColor whiteColor]];
    
    [_ceButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_ceButton setTitleColor:[UIColor colorWithWhite:1 alpha:.23] forState:UIControlStateNormal];
    [_ceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    _ceButton.selected = YES;
    
    [_bceButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_bceButton setTitleColor:[UIColor colorWithWhite:1 alpha:.23] forState:UIControlStateNormal];
    [_bceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    _bceButton.selected = NO;
    
    [_ceBeginButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_ceBeginButton setTitleColor:[UIColor colorWithWhite:1 alpha:.23] forState:UIControlStateNormal];
    [_ceBeginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    _ceBeginButton.selected = YES;
    
    [_bceBeginButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_bceBeginButton setTitleColor:[UIColor colorWithWhite:1 alpha:.23] forState:UIControlStateNormal];
    [_bceBeginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    _bceBeginButton.selected = NO;
    
    [_ceEndButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_ceEndButton setTitleColor:[UIColor colorWithWhite:1 alpha:.23] forState:UIControlStateNormal];
    [_ceEndButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    _ceEndButton.selected = YES;
    
    [_bceEndButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_bceEndButton setTitleColor:[UIColor colorWithWhite:1 alpha:.23] forState:UIControlStateNormal];
    [_bceEndButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    _bceEndButton.selected = NO;
    
    [self textFieldTreatment:_beginYearTextField];
    [self textFieldTreatment:_singleYearTextField];
    [self textFieldTreatment:_endYearTextField];
    
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textLabel setTextColor:[UIColor whiteColor]];
}

- (void)textFieldTreatment:(UITextField*)textField {
    [textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
    [textField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    [textField setTextColor:[UIColor whiteColor]];
    [textField setTintColor:[UIColor whiteColor]];
    textField.layer.cornerRadius = 2.f;
    [textField setKeyboardType:UIKeyboardTypeNumberPad];
    [textField setKeyboardAppearance:UIKeyboardAppearanceDark];
}

- (void)configureForArt:(Art*)art {
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
