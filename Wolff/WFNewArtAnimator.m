//
//  WFNewArtAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFNewArtAnimator.h"
#import "Constants.h"
#import "WFNewArtViewController.h"

@interface WFNewArtAnimator () {
    CGFloat width;
    CGFloat height;
}

@end

@implementation WFNewArtAnimator
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
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
        [darkBackground addTarget:(WFNewArtViewController*)toViewController action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        
        CGRect newArtStartFrame = CGRectMake(0, 0, width, height*.5);
        toView.frame = newArtStartFrame;
        CGRect newArtFrame = CGRectMake(0, 0, width, height*.5);
        
        [transitionContext.containerView addSubview:darkBackground];
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:toView];
        
        // set the new art view background here, becuase we're resetting the framing (and it's not reflects in either the viewDidLoad or viewWillAppear methods
        UIToolbar *toolbarBackground = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, newArtFrame.size.width, newArtFrame.size.height)];
        [toolbarBackground setBarStyle:UIBarStyleBlackTranslucent];
        [toolbarBackground setTranslucent:YES];
        [toView addSubview:toolbarBackground];
        [toView sendSubviewToBack:toolbarBackground];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.875 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            toView.frame = newArtFrame;
            [darkBackground setAlpha:1.0];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else {
        UIButton *darkBackground = (UIButton*)[transitionContext.containerView viewWithTag:kDarkBackgroundConstant];
        
        toView.userInteractionEnabled = YES;
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
        NSTimeInterval outDuration = [self transitionDuration:transitionContext]*.7;
        [UIView animateWithDuration:outDuration delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            fromView.transform = CGAffineTransformMakeScale(.87, .87);
            [fromView setAlpha:0.0];
            [darkBackground setAlpha:0.0];
        } completion:^(BOOL finished) {
            [darkBackground removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }
}
@end
