//
//  WFNewArtCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 11/23/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFNewArtCell.h"
#import "Constants.h"

@implementation WFNewArtCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    _textField.leftView = paddingView;
    _textField.leftViewMode = UITextFieldViewModeAlways;
    
    _textField.layer.borderColor = [UIColor colorWithWhite:.9 alpha:1].CGColor;
    _textField.layer.borderWidth = .5f;
    _textField.layer.cornerRadius = 2.f;
}

@end
