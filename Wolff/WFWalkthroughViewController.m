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
}

@end

@implementation WFWalkthroughViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
        [_scrollView setContentSize:CGSizeMake(width*4, height)];
    } else {
        height = screenHeight();
        width = screenWidth();
        [_scrollView setContentSize:CGSizeMake(height*4, width)];
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
    
    _pageControl.numberOfPages = 4;
    
    [self labelTreatment:_label1];
    [_label1 setText:@"Hello! Welcome to Wolff!"];
    [self labelTreatment:_label2];
    [_label2 setText:@"This is another slide, where we'll tell you more about this fantastic app."];
    [self labelTreatment:_label3];
    [_label3 setText:@"But wait... there's more! Yes, much more. You can actually DO things with this Wolff thingy."];
    [self labelTreatment:_label4];
    [_label4 setText:@"As if you thought we'd only have three slides... here's a fourth! That was the last one though. Time to get going!"];
}

- (void)labelTreatment:(UILabel *)label {
    [label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [label setTextColor:[UIColor whiteColor]];
    [label setClipsToBounds:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    if (currentPage != page) {
        currentPage = page;
        [_pageControl setCurrentPage:currentPage];
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
