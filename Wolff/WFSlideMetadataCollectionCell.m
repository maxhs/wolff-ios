//
//  WFSlideMetadataCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 4/27/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSlideMetadataCollectionCell.h"
#import "Constants.h"

@implementation WFSlideMetadataCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

- (void)configureForPhotoSlide:(PhotoSlide *)photoSlide {
    Art *art = photoSlide.photo.art;
    NSString *title = art.title.length ? art.title : @"";
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0], NSForegroundColorAttributeName : [UIColor colorWithWhite:1 alpha:1]}];
    
    NSAttributedString *artistString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"   %@",art.artistsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    NSAttributedString *dateString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"   %@",art.readableDate] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    NSAttributedString *locationString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"   %@",art.locationsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    [titleString appendAttributedString:artistString];
    [titleString appendAttributedString:dateString];
    [titleString appendAttributedString:locationString];
    
    [self.titleLabel setAttributedText:titleString];
    [self.titleLabel setTextColor:[UIColor whiteColor]];
    [self.titleLabel setHidden:NO];
    [self.titleLabel setAlpha:1.0];
    [self.titleLabel setNumberOfLines:0];
}

@end
