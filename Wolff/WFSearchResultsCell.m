//
//  WFSearchResultsCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/31/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSearchResultsCell.h"
#import "Constants.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation WFSearchResultsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self.imageTile setAlpha:0.0];
    [self.artLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [self.artistLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLightItalic] size:0]];
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

- (void)configureForPhoto:(Photo *)photo {
    [self.artLabel setText:photo.art.title];
    [self.artLabel setTextColor: (IDIOM == IPAD) ? [UIColor blackColor] : [UIColor whiteColor]];
    NSString *artists = photo.art.artistsToSentence;
    if (artists.length){
        [self.artistLabel setText:artists];
        [self.artistLabel setTextColor: (IDIOM == IPAD) ? [UIColor blackColor] : [UIColor whiteColor]];
    } else {
        [self.artistLabel setText:@"Artist Uknown"];
        [self.artistLabel setTextColor:[UIColor lightGrayColor]];
    }
    NSURL *artUrl = [NSURL URLWithString:photo.thumbImageUrl];
    NSURLRequest *artUrlRequest = [NSURLRequest requestWithURL:artUrl cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];
    self.imageTile.contentMode = UIViewContentModeScaleAspectFill;
    self.imageTile.clipsToBounds = YES;
    
    [self.imageTile setImageWithURLRequest:artUrlRequest placeholderImage:nil success:^(NSURLRequest * request, NSHTTPURLResponse * response, UIImage * image) {
        [self.imageTile setImage:image];
        if (response){
            [UIView animateWithDuration:.23f animations:^{
                [self.imageTile setAlpha:1.0];
            }];
        } else {
            [self.imageTile setAlpha:1.0];
        }
    } failure:^(NSURLRequest * request, NSHTTPURLResponse * response, NSError * error) {
        
    }];
}

@end
