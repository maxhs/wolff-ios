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

- (void)configureForPhoto:(Photo *)photo withPhotoCount:(NSUInteger)photoCount {
    Art *art = photo.art;
    NSAttributedString *locationString, *artistString, *dateString, *materialString, *creditString, *iconographyString, *tagsString, *notesString;
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle defaultParagraphStyle].mutableCopy;
    paragraphStyle.lineHeightMultiple = 1.15f;
    
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
    
    
    // if it's a single slide, put materials on the first line... if not, start a new line
    NSMutableAttributedString *componentsString = [[NSMutableAttributedString alloc] initWithString:@"" attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    if ((int)photoCount == 1){
        if (art.materialsToSentence.length){
            materialString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@",art.materialsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
        } else {
            materialString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
        }
        if (art.locationsToSentence.length){
            locationString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@",art.locationsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
        } else {
            locationString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
        }
    } else {
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
    }
    
    if (photo.iconsToSentence.length){
        iconographyString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",photo.iconsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    } else {
        iconographyString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
    }
    
    if (photo.credit.length){
        creditString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",photo.credit] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    } else {
        creditString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
    }
    
    if (photo.notes.length){
        notesString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",photo.notes] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    } else {
        notesString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
    }
    
    if (art.tagsToSentence.length){
        tagsString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",art.tagsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    } else {
        tagsString = [[NSAttributedString alloc] initWithString:@"" attributes:nil];
    }
    
    [titleString appendAttributedString:artistString];
    [titleString appendAttributedString:dateString];
    [titleString appendAttributedString:locationString];
    
    [componentsString appendAttributedString:materialString];
    [componentsString appendAttributedString:iconographyString];
    [componentsString appendAttributedString:creditString];
    [componentsString appendAttributedString:notesString];
    [componentsString appendAttributedString:tagsString];
    
    [self.titleLabel setAttributedText:titleString];
    [self.titleLabel setNumberOfLines:0];
    
    [self.metadataComponentsLabel setAttributedText:componentsString];
    [self.metadataComponentsLabel setNumberOfLines:0];
}

@end
