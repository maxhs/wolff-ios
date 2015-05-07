//
//  WFSettingsCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSettingsCell.h"
#import "Constants.h"

@implementation WFSettingsCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [_textField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_textField setKeyboardAppearance:UIKeyboardAppearanceDark];
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_settingsSwitch setHidden:YES];
    [_actionButton setHidden:YES];
    [_actionButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLight] size:0]];
    [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _actionButton.layer.cornerRadius = 7.f;
    _actionButton.clipsToBounds = YES;
    [_actionButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.23]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.textField setText:@""];
    [self.textLabel setText:@""];
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.textField setUserInteractionEnabled:YES];
    [_actionButton setHidden:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
