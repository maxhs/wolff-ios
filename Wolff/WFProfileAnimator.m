//
//  WFProfileAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/24/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFProfileAnimator.h"
#import "Constants.h"

@interface WFProfileAnimator (){
    BOOL iOS8;
}

@end
@implementation WFProfileAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    CGFloat width, height;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
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
    
    // Set our ending frame. We'll modify this later if we have to
    CGRect mainScreen = [UIScreen mainScreen].bounds;
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:toView];
        
        CGRect startFrame, originEndFrame;
        if (iOS8){
            startFrame = mainScreen;
            startFrame.origin.y += height;
            originEndFrame = mainScreen;
            originEndFrame.origin.y -= height;
        } else {
            startFrame = mainScreen;
            startFrame.origin.x += width;
            originEndFrame = mainScreen;
            originEndFrame.origin.x -= width;
        }
        
        toViewController.view.frame = startFrame;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.975 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toViewController.view.frame = mainScreen;
            fromViewController.view.frame = originEndFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    else {
        toViewController.view.userInteractionEnabled = YES;
        
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
        mainScreen.origin.x += width;
        CGRect originStartFrame = toViewController.view.frame;
        originStartFrame.origin.x = -width;
        toViewController.view.frame = originStartFrame;
        CGRect originEndFrame = toViewController.view.frame;
        originEndFrame.origin.x = 0;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.975 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromViewController.view.frame = mainScreen;
            toViewController.view.frame = originEndFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
