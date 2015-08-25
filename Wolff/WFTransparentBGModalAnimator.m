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
}
@end

@implementation WFTransparentBGModalAnimator
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return kDefaultAnimationDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    width = screenWidth(); height = screenHeight();
    mainScreen = [UIScreen mainScreen].bounds;
    
    // Grab the from and to views from the context
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    
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
