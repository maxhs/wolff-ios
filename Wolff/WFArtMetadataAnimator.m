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
    
}

@end
@implementation WFArtMetadataAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController, *toViewController;
    UIView *fromView,*toView;
    fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f) {
        // iOS 8 logic
        fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    } else {
        // iOS 7 and below logic
        fromView = fromViewController.view;
        toView = toViewController.view;
    }
    
    if (self.presenting) {
        UIButton *darkBackground = [UIButton buttonWithType:UIButtonTypeCustom];
        [darkBackground setBackgroundColor:[UIColor colorWithWhite:.1 alpha:.5]];
        [darkBackground setAlpha:0.0];
        [darkBackground setFrame:[UIScreen mainScreen].bounds];
        [darkBackground setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [darkBackground setTag:kDarkBackgroundConstant];
        [darkBackground addTarget:(WFArtMetadataViewController*)toViewController action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [transitionContext.containerView addSubview:darkBackground];
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:toView];
        
        CGRect metadataStartFrame = CGRectMake((screenWidth()/2-300)-screenWidth(), screenHeight()/2-350, 600, 700);
        toViewController.view.frame = metadataStartFrame;
        CGRect metadataFrame = CGRectMake(screenWidth()/2-300, screenHeight()/2-350, 600, 700);
    
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.875 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            toViewController.view.frame = metadataFrame;
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
        [UIView animateWithDuration:outDuration delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            fromViewController.view.transform = CGAffineTransformMakeScale(.87, .87);
            [fromViewController.view setAlpha:0.0];
            [darkBackground setAlpha:0.0];
            toViewController.view.frame = [UIScreen mainScreen].bounds;
        } completion:^(BOOL finished) {
            [darkBackground removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }
}

- (void)tap {
    NSLog(@"tap!");
}

@end
