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
    NSAttributedString *locationString, *artistString, *dateString, *materialString, *creditString, *iconographyString;
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle defaultParagraphStyle].mutableCopy;
    paragraphStyle.lineHeightMultiple = 1.3f;
    
    NSString *title = art.title.length ? art.title : @"";
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0], NSForegroundColorAttributeName : [UIColor colorWithWhite:1 alpha:1], NSParagraphStyleAttributeName:paragraphStyle}];
    
    if (art.artistsToSentence.length){
        artistString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@",art.artistsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    } else {
        artistString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
    }
    
    if (art.readableDate.length){
        dateString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@",art.readableDate] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    } else {
        dateString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
    }
    
    if (art.locationsToSentence.length){
        locationString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@",art.locationsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    } else {
        locationString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
    }
    
    if (art.materialsToSentence.length){
        materialString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",art.materialsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    } else {
        materialString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
    }
    if (photoSlide.photo.iconsToSentence.length){
        iconographyString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",photoSlide.photo.iconsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    } else {
        iconographyString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
    }
    if (photoSlide.photo.credit.length){
        creditString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",photoSlide.photo.credit] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    } else {
        creditString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
    }
    
    NSAttributedString *spacerString = [[NSAttributedString alloc] initWithString:@"\n" attributes:nil];
    
    [titleString appendAttributedString:artistString];
    [titleString appendAttributedString:dateString];
    [titleString appendAttributedString:locationString];
    [titleString appendAttributedString:spacerString];
    [titleString appendAttributedString:materialString];
    [titleString appendAttributedString:iconographyString];
    [titleString appendAttributedString:creditString];
    
    [self.titleLabel setAttributedText:titleString];
    [self.titleLabel setHidden:NO];
    [self.titleLabel setAlpha:1.0];
    [self.titleLabel setNumberOfLines:0];
}

@end
