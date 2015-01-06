//
//  WFSearchResultsCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/31/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSearchResultsCell.h"
#import "Constants.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation WFSearchResultsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self.imageTile setAlpha:0.0];
    [self.artLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.artistLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
    [self.artistLabel setTextColor:[UIColor lightGrayColor]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.imageTile setAlpha:0.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureForArt:(Art *)art {
    [self.artLabel setText:art.title];
    NSString *artists = art.artistsToSentence;
    [self.artistLabel setText:artists.length ? artists : @"Artist Unknown"];
    NSURL *artUrl = [NSURL URLWithString:art.photo.thumbImageUrl];
    [self.imageTile sd_setImageWithURL:artUrl placeholderImage:nil options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [UIView animateWithDuration:.23f animations:^{
            [self.imageTile setAlpha:1.0];
        }];
    }];
}

@end
