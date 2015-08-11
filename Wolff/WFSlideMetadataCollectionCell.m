//
//  WFSlideMetadataCollectionCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 4/27/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSlideMetadataCollectionCell.h"
#import "Constants.h"
#import "User+helper.h"

@implementation WFSlideMetadataCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
}

- (void)configureForPhoto:(Photo *)photo withPhotoCount:(NSUInteger)photoCount {
    Art *art = photo.art;
    NSAttributedString *locationString, *artistString, *dateString, *materialString, *creditString, *iconographyString, *tagsString, *notesString, *dimensionsString, *postedByString;
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle defaultParagraphStyle].mutableCopy;
    paragraphStyle.lineHeightMultiple = 1.15f;
    
    NSString *title = art.title.length ? art.title : @"";
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0], NSForegroundColorAttributeName : [UIColor colorWithWhite:1 alpha:1], NSParagraphStyleAttributeName:paragraphStyle}];
    
    if (art.artistsToSentence.length){
        artistString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@",art.artistsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
        [titleString appendAttributedString:artistString];
    }
    
    if (art.readableDate.length){
        dateString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@",art.readableDate] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
        [titleString appendAttributedString:dateString];
    }
    
    // if it's a single slide, put materials on the first line... if not, start a new line
    NSMutableAttributedString *componentsString = [[NSMutableAttributedString alloc] initWithString:@"" attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
    if ((int)photoCount == 1){
        if (art.materialsToSentence.length){
            materialString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",art.materialsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
            [componentsString appendAttributedString:materialString];
        }
        if (art.locationsToSentence.length){
            locationString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@",art.locationsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
            [titleString appendAttributedString:locationString];
        }
    } else {
        if (art.locationsToSentence.length){
            locationString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@",art.locationsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
            [titleString appendAttributedString:locationString];
        }
        if (art.materialsToSentence.length){
            materialString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",art.materialsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
            [componentsString appendAttributedString:materialString];
        }
    }
    
    if (art.readableDimensions.length){
        dimensionsString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",art.readableDimensions] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
        [componentsString appendAttributedString:dimensionsString];
    }
    
    if (photo.iconsToSentence.length){
        iconographyString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",photo.iconsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
        [componentsString appendAttributedString:iconographyString];
    }

    if (art.tagsToSentence.length){
        tagsString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",art.tagsToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
        [componentsString appendAttributedString:tagsString];
    }
    
    if (photo.credit.length){
        creditString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",photo.credit] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
        [componentsString appendAttributedString:creditString];
    }
    
    if (photo.partnersToSentence.length){
        postedByString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",photo.partnersToSentence] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : kElectricBlue, NSParagraphStyleAttributeName:paragraphStyle}];
        [componentsString appendAttributedString:postedByString];
    } else if (photo.user.fullName.length){
        postedByString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",photo.user.fullName] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : kElectricBlue, NSParagraphStyleAttributeName:paragraphStyle}];
        [componentsString appendAttributedString:postedByString];
    }
    
    if (photo.notes.length){
        notesString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@",photo.notes] attributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0], NSForegroundColorAttributeName : [UIColor whiteColor], NSParagraphStyleAttributeName:paragraphStyle}];
        [componentsString appendAttributedString:notesString];
    }
    
    
    [self.titleLabel setAttributedText:titleString];
    [self.titleLabel setNumberOfLines:0];
    
    [self.metadataComponentsLabel setAttributedText:componentsString];
    [self.metadataComponentsLabel setNumberOfLines:0];
}

@end
