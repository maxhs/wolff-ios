//
//  WFGroupCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/13/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFTableCell.h"
#import "Constants.h"

@implementation WFTableCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self.tableLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    
    if (IDIOM == IPAD){
        [self.textLabel setTextColor:[UIColor blackColor]];
        [self setTintColor:[UIColor blackColor]];
    } else {
        [self.textLabel setTextColor:[UIColor whiteColor]];
        [self setTintColor:[UIColor whiteColor]];
        [self.tableLabel setTextColor:[UIColor whiteColor]];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.textLabel setText:@""];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForTable:(LightTable *)lightTable {
    [self.tableLabel setText:lightTable.name];
}

@end
