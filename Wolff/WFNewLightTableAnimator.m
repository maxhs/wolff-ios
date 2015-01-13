//
//  WFNewLightTableAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/1/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFNewLightTableAnimator.h"
#import "Constants.h"
#import "WFNewLightTableViewController.h"
#import "WFDismissableNavigationController.h"

@interface WFNewLightTableAnimator () {
    CGFloat width;
    CGFloat height;
    CGRect mainScreen;
    BOOL iOS8;
}

@end

@implementation WFNewLightTableAnimator
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        iOS8 = YES;
        width = screenWidth(); height = screenHeight();
        mainScreen = [UIScreen mainScreen].bounds;
    } else {
        iOS8 = NO;
        width = screenHeight(); height = screenWidth();
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
        [darkBackground setFrame:[UIScreen mainScreen].bounds];
        [darkBackground setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [darkBackground setTag:kDarkBackgroundConstant];
        [darkBackground addTarget:(WFDismissableNavigationController*)toViewController action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        
        CGRect newArtFrame;
        if (iOS8){
            CGRect newArtStartFrame = CGRectMake(width*.1, 7, width*.8, height*.475);
            toViewController.view.frame = newArtStartFrame;
            newArtFrame = CGRectMake(width*.1, 7, width*.8, height*.475);
        } else {
            CGRect newArtStartFrame = CGRectMake(0, 0, height, width);
            toViewController.view.frame = newArtStartFrame;
            newArtFrame = CGRectMake(0, 0, height, width);
        }
        
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:darkBackground];
        [transitionContext.containerView addSubview:toView];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.875 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            toViewController.view.frame = newArtFrame;
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
            if (iOS8){
                fromViewController.view.transform = CGAffineTransformMakeScale(.87, .87);
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

