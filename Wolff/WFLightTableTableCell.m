//
//  WFLightTableTableCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 4/8/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFLightTableTableCell.h"
#import "Constants.h"

@implementation WFLightTableTableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.cellLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [self.cellLabel setTextColor:[UIColor colorWithWhite:1 alpha:.37]];
    
    [self.textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.77]];
    self.textView.layer.cornerRadius = 3.f;
    self.textView.clipsToBounds = YES;
    [self.textView setKeyboardAppearance:UIKeyboardAppearanceDark];
    
    [self.textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.77]];
    self.textField.layer.cornerRadius = 3.f;
    self.textField.clipsToBounds = YES;
    [self.textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    self.textField.leftView = paddingView;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    [self.textField setTintColor:[UIColor blackColor]];
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
