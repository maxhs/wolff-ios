//
//  WFSlideshowAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/4/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideshowAnimator.h"
#import "Constants.h"

@implementation WFSlideshowAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    CGFloat width = screenWidth();
    
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Set our ending frame. We'll modify this later if we have to
    CGRect endFrame = [UIScreen mainScreen].bounds;
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        
        [transitionContext.containerView addSubview:toViewController.view];
        
        CGRect startFrame = endFrame;
        startFrame.origin.x += width;
        
        CGRect originEndFrame = endFrame;
        originEndFrame.origin.x -= width;
        
        toViewController.view.frame = startFrame;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.975 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toViewController.view.frame = endFrame;
            fromViewController.view.frame = originEndFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    
    } else {
    
        toViewController.view.userInteractionEnabled = YES;
        
        endFrame.origin.x += width;
        CGRect originStartFrame = toViewController.view.frame;
        originStartFrame.origin.x = -width;
        toViewController.view.frame = originStartFrame;
        CGRect originEndFrame = toViewController.view.frame;
        originEndFrame.origin.x = 0;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.975 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromViewController.view.frame = endFrame;
            toViewController.view.frame = originEndFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
