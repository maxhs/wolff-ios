//
//  WFWalkthroughViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/10/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFWalkthroughViewController.h"
#import "Constants.h"

@interface WFWalkthroughViewController () {
    CGFloat width;
    CGFloat height;
    NSInteger currentPage;
    CGRect mainScreen;
    UIMotionEffectGroup *motionGroup;
}

@end

@implementation WFWalkthroughViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();height = screenHeight();
        mainScreen = [UIScreen mainScreen].bounds;
        [_scrollView setContentSize:CGSizeMake(width*3, height)];
    } else {
        height = screenHeight(); width = screenWidth();
        mainScreen = CGRectMake(0, 0, height, width);
        [_scrollView setContentSize:CGSizeMake(height*3, width)];
    }
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    [_scrollView setFrame:CGRectMake(0, 0, width, height)];
    [_scrollView setBackgroundColor:[UIColor clearColor]];
    
    [_skipButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [_skipButton.titleLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
    [_skipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_skipButton setTitle:@"Skip" forState:UIControlStateNormal];
    _skipButton.layer.cornerRadius = 14.f;
    _skipButton.clipsToBounds = YES;
    _skipButton.backgroundColor = [UIColor colorWithWhite:1 alpha:.07];
    
    _pageControl.numberOfPages = 3;
    
    [self setUpMotionEffects];
    
    [_imageView1 addMotionEffect:motionGroup];
    [_imageView2 addMotionEffect:motionGroup];
    [_imageView3 addMotionEffect:motionGroup];
    [self labelTreatment:_label1];
    [_label1 setText:@"Discover, organize, and present works of art in high resolution."];
    [self labelTreatment:_label2];
    [_label2 setText:@"Interactive slideshows with side-by-side comparisons in high resolution."];
    [self labelTreatment:_label3];
    [_label3 setText:@"Contribute to the Wölff catalog: a crowd-sourced library of digitized artworks."];
    
    [self bigLabelTreatment:_bigLabel1];
    [self bigLabelTreatment:_bigLabel2];
    [self bigLabelTreatment:_bigLabel3];
}

- (void)setUpMotionEffects {
    UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-33);
    verticalMotionEffect.maximumRelativeValue = @(33);
    
    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-33);
    horizontalMotionEffect.maximumRelativeValue = @(33);
    
    motionGroup = [UIMotionEffectGroup new];
    motionGroup.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];
}

- (void)labelTreatment:(UILabel *)label {
    [label setClipsToBounds:NO];
    [label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [label setTextColor:[UIColor whiteColor]];
    label.layer.shadowColor = [UIColor colorWithWhite:0 alpha:.5].CGColor;
    label.layer.shadowOffset = CGSizeMake(.9f, .9f);
    label.layer.shadowRadius = 1.7f;
    label.layer.shadowOpacity = .45f;
    [label addMotionEffect:motionGroup];
}

- (void)bigLabelTreatment:(UILabel*)label {
    [label setFont:[UIFont fontWithName:kMuseoSansThin size:66]];
    [label setTextColor:[UIColor whiteColor]];
    label.layer.shadowColor = [UIColor colorWithWhite:0 alpha:.5].CGColor;
    label.layer.shadowOffset = CGSizeMake(1.2f, 1.2f);
    label.layer.shadowRadius = 3.7f;
    label.layer.shadowOpacity = .75f;
    [label addMotionEffect:motionGroup];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    CGFloat offsetX = scrollView.contentOffset.x;
    float fractionalPage = offsetX / pageWidth;
    NSInteger page = lround(fractionalPage);
    if (currentPage != page) {
        currentPage = page;
        [_pageControl setCurrentPage:currentPage];
        if (currentPage + 1 >= _pageControl.numberOfPages){
            [_skipButton setTitle:@"Done" forState:UIControlStateNormal];
        } else {
            [_skipButton setTitle:@"Skip" forState:UIControlStateNormal];
        }
    }
    [_backgroundImageView1 setAlpha:1-(offsetX/_scrollView.frame.size.width)];
    [_backgroundImageView2 setAlpha:2-(offsetX/(_scrollView.frame.size.width))];
    [_backgroundImageView3 setAlpha:3-(offsetX/(_scrollView.frame.size.width))];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat endedAtX = scrollView.contentOffset.x;
    if (endedAtX > ((width * 2) + 100)) {
        [scrollView setContentOffset:CGPointMake(width * 4, 0) animated:YES];
        [self dismiss];
    }
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
