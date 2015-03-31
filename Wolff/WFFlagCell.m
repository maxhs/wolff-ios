//
//  WFFlagCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/22/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFFlagCell.h"
#import "Constants.h"

@implementation WFFlagCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_textFieldLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    _textField.layer.borderWidth = .5f;
    _textField.layer.borderColor = [UIColor colorWithWhite:0 alpha:.1].CGColor;
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 34)];
    _textField.leftView = paddingView;
    _textField.leftViewMode = UITextFieldViewModeAlways;
    [_textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    [_textView setKeyboardAppearance:UIKeyboardAppearanceDark];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_label setText:@""];
    [_textField setText:@""];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
