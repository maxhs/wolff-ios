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

    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:IDIOM == IPAD ? UIFontTextStyleBody : UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_label setTextColor:[UIColor whiteColor]];
    [_rangeLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:IDIOM == IPAD ? UIFontTextStyleBody : UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_rangeLabel setTextColor:[UIColor whiteColor]];
    [_fromLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:IDIOM == IPAD ? UIFontTextStyleBody : UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_fromLabel setTextColor:[UIColor whiteColor]];
    [_toLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:IDIOM == IPAD ? UIFontTextStyleBody : UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_toLabel setTextColor:[UIColor whiteColor]];
 
    [_orLabel setText:@"OR"];
    [_orLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSansLightItalic] size:0]];
    [_orLabel setTextColor:[UIColor colorWithWhite:1 alpha:.77]];
    
    [_circaLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_circaLabel setTextColor:[UIColor whiteColor]];
    
    [_eraButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_eraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
    
    [_beginEraButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_beginEraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
    
    [_endEraButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_endEraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
    
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

- (void)configureArt:(Art*)art forEditMode:(BOOL)editMode {
    [_eraButton setTitle:art.interval.suffix forState:UIControlStateNormal];
    [_beginEraButton setTitle:art.interval.beginSuffix forState:UIControlStateNormal];
    [_endEraButton setTitle:art.interval.beginSuffix forState:UIControlStateNormal];
    
    [_label setText:@"DATE"];
    [_rangeLabel setText:@"RANGE"];
    [_circaLabel setText:@"CIRCA"];
    [_singleYearTextField setPlaceholder:@"e.g. 1776"];
    [_beginYearTextField setPlaceholder:@"Beginning"];
    [_endYearTextField setPlaceholder:@"End"];
    if (art.interval.year && ![art.interval.year isEqualToNumber:@0]){
        [_singleYearTextField setText:[NSString stringWithFormat:@"%@",art.interval.year]];
        [_eraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    } else {
        [_eraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
    }
    if (art.interval.beginRange && ![art.interval.beginRange isEqualToNumber:@0]){
        [_beginYearTextField setText:[NSString stringWithFormat:@"%@",art.interval.beginRange]];
        [_beginEraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    } else {
        [_beginEraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
    }
    if (art.interval.endRange && ![art.interval.endRange isEqualToNumber:@0]){
        [_endYearTextField setText:[NSString stringWithFormat:@"%@",art.interval.endRange]];
        [_endEraButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    } else {
        [_endEraButton setTitleColor:kPlaceholderTextColor forState:UIControlStateNormal];
    }
    
    if (editMode){
        [_label setText:@"DATE"];
        [_label setTextColor:[UIColor blackColor]];
        [_rangeLabel setText:@"DATE RANGE"];
        [_rangeLabel setTextColor:[UIColor blackColor]];
        [_circaLabel setTextColor:[UIColor blackColor]];
        [_circaLabel setFont:[UIFont fontWithDescriptor: [UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
        
        [self editModeTextFieldTreatement:_beginYearTextField];
        [self editModeTextFieldTreatement:_endYearTextField];
        [self editModeTextFieldTreatement:_singleYearTextField];
        
    } else {
        [_eraButton setShowsTouchWhenHighlighted:YES];
        [_beginEraButton setShowsTouchWhenHighlighted:YES];
        [_endEraButton setShowsTouchWhenHighlighted:YES];
    }
}

- (void)editModeTextFieldTreatement:(UITextField*)textField {
    [textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    textField.leftView = paddingView;
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.layer.borderColor = [UIColor colorWithWhite:0 alpha:.14].CGColor;
    textField.layer.borderWidth = .5f;
    textField.layer.cornerRadius = 2.f;
    [textField setTextColor:[UIColor blackColor]];
    [textField setTintColor:[UIColor blackColor]];
    [textField setKeyboardType:UIKeyboardTypeNumberPad];
    [textField setKeyboardAppearance:UIKeyboardAppearanceDark];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
