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

- (void)awakeFromNib
{
    [super awakeFromNib];
    [_artLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForArt:(Art*)art {
    [_artLabel setText:art.title];
}
@end
