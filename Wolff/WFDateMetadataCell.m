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
    [_circaLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_circaLabel setTextColor:[UIColor whiteColor]];
    [_eraLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_eraLabel setTextColor:[UIColor whiteColor]];
    
    [_ceButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_ceButton setTitleColor:[UIColor colorWithWhite:1 alpha:.23] forState:UIControlStateNormal];
    [_ceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    _ceButton.selected = YES;
    
    [_bceButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [_bceButton setTitleColor:[UIColor colorWithWhite:1 alpha:.23] forState:UIControlStateNormal];
    [_bceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    _bceButton.selected = NO;
    
    [_beginYearTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    _beginYearTextField.leftView = paddingView;
    _beginYearTextField.leftViewMode = UITextFieldViewModeAlways;
    [_beginYearTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    [_beginYearTextField setTextColor:[UIColor whiteColor]];
    [_beginYearTextField setTintColor:[UIColor whiteColor]];
    _beginYearTextField.layer.cornerRadius = 2.f;
    
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textLabel setTextColor:[UIColor whiteColor]];
}

- (void)configureForArt:(Art*)art {
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
