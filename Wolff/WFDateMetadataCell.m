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
 
    [_orLabel setText:@"OR"];
    [_orLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSansLightItalic] size:0]];
    [_orLabel setTextColor:[UIColor colorWithWhite:1 alpha:.77]];
    
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

- (void)configureArt:(Art*)art forEditMode:(BOOL)editMode {
    if ([art.interval.suffix isEqualToString:@"CE"]){
        [_ceButton setSelected:YES];
        [_bceButton setSelected:NO];
    } else if ([art.interval.suffix isEqualToString:@"BCE"]){
        [_ceButton setSelected:NO];
        [_bceButton setSelected:YES];
    }
    
    if ([art.interval.beginSuffix isEqualToString:@"CE"]){
        [_ceBeginButton setSelected:YES];
        [_bceBeginButton setSelected:NO];
    } else if ([art.interval.beginSuffix isEqualToString:@"BCE"]){
        [_ceBeginButton setSelected:NO];
        [_bceBeginButton setSelected:YES];
    }
    
    if ([art.interval.endSuffix isEqualToString:@"CE"]){
        [_ceEndButton setSelected:YES];
        [_bceEndButton setSelected:NO];
    } else if ([art.interval.endSuffix isEqualToString:@"BCE"]){
        [_ceEndButton setSelected:NO];
        [_bceEndButton setSelected:YES];
    }
    
    if ([art.interval.suffix isEqualToString:@"CE"]){
        [_ceButton setSelected:YES];
        [_bceButton setSelected:NO];
    } else if ([art.interval.suffix isEqualToString:@"BCE"]){
        [_ceButton setSelected:NO];
        [_bceButton setSelected:YES];
    }
    [_label setText:@"DATE"];
    [_rangeLabel setText:@"RANGE"];
    [_circaLabel setText:@"CIRCA"];
    [_singleYearTextField setPlaceholder:@"e.g. 1776"];
    [_beginYearTextField setPlaceholder:@"Beginning"];
    [_endYearTextField setPlaceholder:@"End"];
    if (art.interval.year && ![art.interval.year isEqualToNumber:@0]){
        [_singleYearTextField setText:[NSString stringWithFormat:@"%@",art.interval.year]];
    }
    if (art.interval.beginRange && ![art.interval.beginRange isEqualToNumber:@0]){
        [_beginYearTextField setText:[NSString stringWithFormat:@"%@",art.interval.beginRange]];
    }
    if (art.interval.endRange && ![art.interval.endRange isEqualToNumber:@0]){
        [_endYearTextField setText:[NSString stringWithFormat:@"%@",art.interval.endRange]];
    }
    
    if (editMode){
        [_ceButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
        [_ceButton setTitleColor:[UIColor colorWithWhite:0 alpha:.23] forState:UIControlStateNormal];
        [_ceButton setTitleColor:kSaffronColor forState:UIControlStateSelected];
        _ceButton.selected = YES;
        
        [_bceButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
        [_bceButton setTitleColor:[UIColor colorWithWhite:0 alpha:.23] forState:UIControlStateNormal];
        [_bceButton setTitleColor:kSaffronColor forState:UIControlStateSelected];
        _bceButton.selected = NO;
        
        [_ceBeginButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
        [_ceBeginButton setTitleColor:[UIColor colorWithWhite:0 alpha:.23] forState:UIControlStateNormal];
        [_ceBeginButton setTitleColor:kSaffronColor forState:UIControlStateSelected];
        _ceBeginButton.selected = YES;
        
        [_bceBeginButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
        [_bceBeginButton setTitleColor:[UIColor colorWithWhite:0 alpha:.23] forState:UIControlStateNormal];
        [_bceBeginButton setTitleColor:kSaffronColor forState:UIControlStateSelected];
        _bceBeginButton.selected = NO;
        
        [_ceEndButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
        [_ceEndButton setTitleColor:[UIColor colorWithWhite:0 alpha:.23] forState:UIControlStateNormal];
        [_ceEndButton setTitleColor:kSaffronColor forState:UIControlStateSelected];
        _ceEndButton.selected = YES;
        
        [_bceEndButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
        [_bceEndButton setTitleColor:[UIColor colorWithWhite:0 alpha:.23] forState:UIControlStateNormal];
        [_bceEndButton setTitleColor:kSaffronColor forState:UIControlStateSelected];
        _bceEndButton.selected = NO;
        
        [_label setText:@"DATE"];
        [_label setFont:[UIFont fontWithDescriptor: [UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThin] size:0]];
        [_label setTextColor:[UIColor blackColor]];
        [_rangeLabel setText:@"DATE RANGE"];
        [_rangeLabel setTextColor:[UIColor blackColor]];
        [_rangeLabel setFont:[UIFont fontWithDescriptor: [UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThin] size:0]];
        [_circaLabel setTextColor:[UIColor blackColor]];
        [_circaLabel setFont:[UIFont fontWithDescriptor: [UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
        
        [self editModeTextFieldTreatement:_beginYearTextField];
        [self editModeTextFieldTreatement:_endYearTextField];
        [self editModeTextFieldTreatement:_singleYearTextField];
        
        [_ceBeginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_ceButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_ceEndButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_bceButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_bceBeginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_bceEndButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    } else {
        [_ceButton setShowsTouchWhenHighlighted:YES];
        [_ceBeginButton setShowsTouchWhenHighlighted:YES];
        [_ceEndButton setShowsTouchWhenHighlighted:YES];
        [_bceButton setShowsTouchWhenHighlighted:YES];
        [_bceBeginButton setShowsTouchWhenHighlighted:YES];
        [_bceEndButton setShowsTouchWhenHighlighted:YES];
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
