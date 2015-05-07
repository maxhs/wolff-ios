//
//  WFNewLightTableAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/1/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFNewLightTableAnimator.h"
#import "Constants.h"
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
    return kDefaultAnimationDuration;
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
    UIViewController *fromViewController, *toViewController; UIView *fromView,*toView;
    fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (iOS8) {
        fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    } else {
        fromView = fromViewController.view;
        toView = toViewController.view;
    }
    
    [transitionContext.containerView addSubview:fromView];
    [transitionContext.containerView addSubview:toView];
    
    if (self.presenting) {

        if (iOS8){
            CGRect newArtStartFrame = CGRectMake(0, height, width, height);
            toViewController.view.frame = newArtStartFrame;
        } else {
            CGRect newArtStartFrame = CGRectMake(0, width, height, width);
            toViewController.view.frame = newArtStartFrame;
        }
        CGRect newArtFrame = mainScreen;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            toView.frame = newArtFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
        
    } else {
        
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
        CGRect newLightTableFrame = fromView.frame;
        if (iOS8){
            newLightTableFrame.origin.y += height;
        } else {
            [fromView setFrame:mainScreen];
            newLightTableFrame.origin.y -= width;
            newLightTableFrame.origin.x -= height;
        }
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.875 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [fromViewController.view setFrame:newLightTableFrame];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}
@end

