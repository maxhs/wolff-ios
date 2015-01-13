//
//  WFArtMetadataAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFArtMetadataAnimator.h"
#import "Constants.h"
#import "WFCatalogViewController.h"
#import "WFArtMetadataViewController.h"

@interface WFArtMetadataAnimator () {
    CGFloat width;
    CGFloat height;
    BOOL iOS8;
}

@end
@implementation WFArtMetadataAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    CGRect mainScreen;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        iOS8 = YES;
        width = screenWidth();
        height = screenHeight();
        mainScreen = [UIScreen mainScreen].bounds;
    } else {
        iOS8 = NO;
        width = screenHeight();
        height = screenWidth();
        mainScreen = CGRectMake(0, 0, height, width);
    }
    
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController, *toViewController;
    UIView *fromView,*toView;
    fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (iOS8) {
        fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    } else {
        fromView = fromViewController.view;
        toView = toViewController.view;
    }
    
    if (self.presenting) {
        UIButton *darkBackground = [UIButton buttonWithType:UIButtonTypeCustom];
        [darkBackground setBackgroundColor:[UIColor colorWithWhite:.1 alpha:.5]];
        [darkBackground setAlpha:0.0];

        [darkBackground setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [darkBackground setTag:kDarkBackgroundConstant];
        [darkBackground addTarget:(WFArtMetadataViewController*)toViewController action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        
        [darkBackground setFrame:mainScreen];
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:darkBackground];
        [transitionContext.containerView addSubview:toView];
        

        [toView setAlpha:0.0];
        
        CGFloat offset = height/2-350;
        UITableView *metadataTableView = [(WFArtMetadataViewController*)toViewController tableView];
        [metadataTableView setContentInset:UIEdgeInsetsMake(offset, 0, offset, 0)];
        [metadataTableView setContentOffset:CGPointMake(0, -offset)];
        int lowerBound = 1; int upperBound = 3;
        int rndValue = lowerBound + arc4random() % (upperBound - lowerBound);
        CGFloat xOffset = rndValue == 1 ? width : -width;
        
        CGRect metadataFrame;
        if (iOS8) {
            metadataFrame = CGRectMake(width/2-300, 0, 600, height);
            CGRect metadataStartFrame = CGRectMake((width/2-300)-xOffset, 0, 600, height);
            toView.frame = metadataStartFrame;
        } else {
            metadataFrame = CGRectMake(0, width/2-300, height, 600);
            CGRect metadataStartFrame = CGRectMake(0, (width/2-300)-xOffset, height, 600);
            toView.frame = metadataStartFrame;
        }
    
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.975 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toView.frame = metadataFrame;
            [toView setAlpha:1.0];
            [darkBackground setAlpha:1.0];
            
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else {
        UIButton *darkBackground = (UIButton*)[transitionContext.containerView viewWithTag:kDarkBackgroundConstant];
        
        toViewController.view.userInteractionEnabled = YES;
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
        NSTimeInterval outDuration = [self transitionDuration:transitionContext]*.7;
        [UIView animateWithDuration:outDuration delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseIn animations:^{
            if (iOS8){
                fromViewController.view.transform = CGAffineTransformMakeScale(.923f, .923f);
            }
            [fromViewController.view setAlpha:0.0];
            [darkBackground setAlpha:0.0];
        } completion:^(BOOL finished) {
            [darkBackground removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
