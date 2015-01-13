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
    
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansSemibold] size:0]];
    [self.textLabel setTextColor:[UIColor whiteColor]];
    [self.textLabel setText:@""];
    [_artLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
    [_artLabel setTextColor:[UIColor whiteColor]];
    
    UIView *selectedView = [[UIView alloc] initWithFrame:self.frame];
    [selectedView setBackgroundColor:kDarkTableViewCellSelectionColor];
    self.selectedBackgroundView = selectedView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForArt:(Art*)art {
    [_artLabel setText:art.title];
}

- (void)configureForTable:(Table *)table {
    if (table.name.length){
        [_artLabel setText:table.name];
        [_artLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    } else {
        [_artLabel setText:@"No name..."];
        [_artLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
    }
}
@end
