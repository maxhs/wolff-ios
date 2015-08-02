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
}

@end

@implementation WFNewLightTableAnimator
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return kDefaultAnimationDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    width = screenWidth(); height = screenHeight();
    mainScreen = [UIScreen mainScreen].bounds;
    
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.presenting) {
        [transitionContext.containerView addSubview:toViewController.view];
        
        CGRect newArtStartFrame = CGRectMake(0, height, width, height);
        toViewController.view.frame = newArtStartFrame;
        CGRect newArtFrame = mainScreen;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            toViewController.view.frame = newArtFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
        
    } else {
        
        CGRect newLightTableFrame = fromViewController.view.frame;
        newLightTableFrame.origin.y += height;
       
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.875 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [fromViewController.view setFrame:newLightTableFrame];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}
@end

