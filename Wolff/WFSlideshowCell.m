//
//  WFSlideshowCell.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideshowCell.h"
#import "Constants.h"
#import "User+helper.h"
#import <MagicalRecord/MagicalRecord.h>

@implementation WFSlideshowCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    UIView *selectionView = [[UIView alloc] initWithFrame:self.frame];
    [selectionView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    self.selectedBackgroundView = selectionView;
    
    [_slideshowLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_slideshowLabel setTextColor:[UIColor whiteColor]];
    [_label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
    [_label setTextColor:[UIColor whiteColor]];
    [_label setText:@""];
    
    [_actionButton setBackgroundColor:[UIColor redColor]];
    [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_actionButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    
    [self.scrollView setContentSize:CGSizeMake(kSidebarWidth+100, self.contentView.frame.size.height)];
    [self.scrollView setUserInteractionEnabled:NO];
    self.scrollView.delegate = self;
    [self.textLabel setTextColor:[UIColor blackColor]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.textLabel setText:@""];
    [_slideshowLabel setText:@""];
    [_iconImageView setImage:nil];
    [self.imageView setImage:nil];
}

- (void)configureForSlideshow:(Slideshow *)slideshow {
    [self.textLabel setText:@""];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [slideshow.owner.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [_actionButton setImage:[UIImage imageNamed:@"whiteTrash"] forState:UIControlStateNormal];
        [_actionButton setBackgroundColor:[UIColor redColor]];
    } else {
        [_actionButton setImage:[UIImage imageNamed:@"remove"] forState:UIControlStateNormal];
        [_actionButton setBackgroundColor:[UIColor clearColor]];
    }
    
    //set up the title
    if (slideshow.title.length){
        [_slideshowLabel setText:slideshow.title];
        [_slideshowLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansItalic] size:0]];
        [_slideshowLabel setTextColor:[UIColor blackColor]];
    } else {
        [_slideshowLabel setText:@"No name..."];
        [_slideshowLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansLightItalic] size:0]];
        [_slideshowLabel setTextColor:[UIColor lightGrayColor]];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetX = scrollView.contentOffset.x;
    _actionButton.transform = CGAffineTransformMakeTranslation(-contentOffsetX, 0);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
