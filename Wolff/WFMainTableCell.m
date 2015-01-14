//
//  WFMainTableCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFMainTableCell.h"
#import "Constants.h"

@implementation WFMainTableCell

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
    [self setBackgroundColor:[UIColor clearColor]];
    UIView *clearFrame = [[UIView alloc] initWithFrame:self.frame];
    [clearFrame setBackgroundColor:[UIColor clearColor]];
    self.backgroundView = clearFrame;
    
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
    [_label setTextColor:[UIColor whiteColor]];
    [_label setText:@""];

    [_tableLabel setTextColor:[UIColor whiteColor]];
    [_pieceCountLabel setTextColor:[UIColor colorWithWhite:1 alpha:.33]];
    
    UIView *selectedView = [[UIView alloc] initWithFrame:self.frame];
    [selectedView setBackgroundColor:kDarkTableViewCellSelectionColor];
    self.selectedBackgroundView = selectedView;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_pieceCountLabel setText:@""];
    [_tableLabel setText:@""];
    [_label setText:@""];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForTable:(Table *)table {
    if (table.name.length){
        [_tableLabel setText:table.name];
        [_tableLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansItalic] size:0]];
    } else {
        [_tableLabel setText:@"No name..."];
        [_tableLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
    }
    NSString *pieceCount = table.photos.count == 1 ? @"1 slide" : [NSString stringWithFormat:@"%lu slides",(unsigned long)table.photos.count];
    [_pieceCountLabel setText:pieceCount];
    [_pieceCountLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansItalic] size:0]];
}
@end
