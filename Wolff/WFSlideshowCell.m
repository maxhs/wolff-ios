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
@interface WFSlideshowCell() {
    Slideshow *_slideshow;
}
@end

@implementation WFSlideshowCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    UIView *selectionView = [[UIView alloc] initWithFrame:self.frame];
    [selectionView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    self.selectedBackgroundView = selectionView;
    
    [_slideshowLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
    [_slideshowLabel setTextColor:[UIColor whiteColor]];
    
    [_actionButton setBackgroundColor:[UIColor redColor]];
    [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_actionButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0]];
    
    [_scrollView setContentSize:CGSizeMake(kSidebarWidth+100, self.contentView.frame.size.height)];
    [_scrollView setUserInteractionEnabled:NO];
    _scrollView.delegate = self;
    [self.textLabel setTextColor:[UIColor blackColor]];
    
    [_iconImageView setImage:nil];
    [self.imageView setImage:nil];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.textLabel setText:@""];
    [_slideshowLabel setText:@""];
    [_iconImageView setImage:nil];
    [self.imageView setImage:nil];
}

- (void)configureForSlideshow:(Slideshow *)slideshow {
    _slideshow = slideshow;
    [self.textLabel setText:@""];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [slideshow.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [_actionButton setTitle:@"Delete" forState:UIControlStateNormal];
        [_actionButton setBackgroundColor:[UIColor redColor]];
        [_actionButton addTarget:self action:@selector(deleteShow) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [_actionButton setTitle:@"Remove" forState:UIControlStateNormal];
        [_actionButton setBackgroundColor:kSaffronColor];
        [_actionButton addTarget:self action:@selector(removeShow) forControlEvents:UIControlEventTouchUpInside];
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
    //NSLog(@"action button origin x: %f",_actionButton.frame.origin.x);
    //NSLog(@"content offset x: %f",contentOffsetX);
    //if (_actionButton.frame.origin.x >= 219.f){
    _actionButton.transform = CGAffineTransformMakeTranslation(-contentOffsetX, 0);
    //}
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)deleteShow {
    if (self.delegate && [self.delegate respondsToSelector:@selector(deleteSlideshow:)]){
        [self.delegate deleteSlideshow:_slideshow];
    }
}

- (void)removeShow {
    if (self.delegate && [self.delegate respondsToSelector:@selector(removeSlideshow:)]){
        [self.delegate removeSlideshow:_slideshow];
    }
}

@end
