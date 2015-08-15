//
//  WFArtMetadataCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFArtMetadataCell.h"
#import "Constants.h"

@implementation WFArtMetadataCell

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
    // set edit mode to NO by default
    [self setDefaultStyle:NO];
    [self setBackgroundColor:[UIColor whiteColor]];
    [_privateSwitch setHidden:YES];
    _textView.layer.cornerRadius = 2.f;
    [_textView setKeyboardAppearance:UIKeyboardAppearanceDark];
    [_textView setAlpha:0.0];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_privateSwitch setHidden:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setDefaultStyle:(BOOL)editMode {
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:IDIOM == IPAD ? UIFontTextStyleBody : UIFontTextStyleCaption1 forFont:kMuseoSansThin] size:0]];
    [_label setTextColor:[UIColor blackColor]];
    [_textView setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_textView setTextColor:[UIColor blackColor]];
   
    if (editMode){
        _textView.layer.borderColor = [UIColor colorWithWhite:0 alpha:.1].CGColor;
        _textView.layer.borderWidth = .5f;
        [_textView setUserInteractionEnabled:YES];
    } else {
        _textView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0].CGColor;
        _textView.layer.borderWidth = 0.f;
        [_textView setUserInteractionEnabled:NO];
    }
}

@end
