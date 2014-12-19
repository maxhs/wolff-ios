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

- (void)awakeFromNib
{
    // Initialization code
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleBody forFont:kLatoLight] size:0]];
    [_label setTextColor:[UIColor blackColor]];
    
    [_value setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
    [_value setTextColor:[UIColor blackColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
