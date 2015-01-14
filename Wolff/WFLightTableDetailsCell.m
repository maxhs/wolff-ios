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
    [self.label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.label setTextColor:[UIColor colorWithWhite:.7 alpha:.7]];
    
    [self.textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textField setBackgroundColor:kTextFieldBackground];
    self.textField.layer.cornerRadius = 3.f;
    self.textField.clipsToBounds = YES;
    [self.textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    self.textField.leftView = paddingView;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    
    [self.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textView setBackgroundColor:kTextFieldBackground];
    self.textView.layer.cornerRadius = 3.f;
    self.textView.clipsToBounds = YES;
    [self.textView setKeyboardAppearance:UIKeyboardAppearanceDark];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
