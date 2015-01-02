//
//  WFNotificationCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFNotificationCell.h"
#import "Constants.h"
#import <DateTools/DateTools.h>

@implementation WFNotificationCell

- (void)awakeFromNib {
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForNotificaiton:(Notification *)notification {
    [self.textLabel setText:notification.message];
    [self.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    UILabel *timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 70, self.contentView.frame.size.height)];
    [timestampLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [timestampLabel setTextColor:[UIColor lightGrayColor]];
    [timestampLabel setText:notification.sentAt.shortTimeAgoSinceNow];
    [timestampLabel setTextAlignment:NSTextAlignmentRight];
    self.accessoryView = timestampLabel;
}
@end
