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

    [self setBackgroundColor:[UIColor clearColor]];
    
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_label setTextColor:[UIColor whiteColor]];
    
    [_textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    _textField.leftView = paddingView;
    _textField.leftViewMode = UITextFieldViewModeAlways;
    [_textField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    [_textField setTextColor:[UIColor whiteColor]];
    [_textField setTintColor:[UIColor whiteColor]];
    _textField.layer.cornerRadius = 2.f;
    
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textLabel setTextColor:[UIColor whiteColor]];
}

@end
