//
//  WFTransparentBGModalAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 4/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFTransparentBGModalAnimator.h"
#import "Constants.h"

@interface WFTransparentBGModalAnimator () {
    CGFloat width;
    CGFloat height;
    CGRect mainScreen;
    BOOL iOS8;
}
@end

@implementation WFTransparentBGModalAnimator
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return kDefaultAnimationDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
        mainScreen = [UIScreen mainScreen].bounds;
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
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
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:toView];
        
        CGRect toEndFrame;
        [toView setFrame:CGRectMake(0, height, width, height)];
        toEndFrame = toView.frame;
        toEndFrame.origin.y = 0;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.925 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [toView setFrame:toEndFrame];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    else {
    
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
        CGRect fromEndFrame = fromView.frame;
        if (IDIOM == IPAD){
            fromEndFrame.origin.x = width;
        } else {
            fromEndFrame.origin.y = height;
        }
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.925 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [fromView setFrame:fromEndFrame];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
