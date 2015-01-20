//
//  WFSlideMetadataAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFSlideMetadataAnimator.h"
#import "UIImage+ImageEffects.h"
#import "Constants.h"
#import "WFSlideMetadataViewController.h"

@interface WFSlideMetadataAnimator () {
    CGFloat width;
    CGFloat height;
    BOOL iOS8;
    CGRect mainScreen;
    CGFloat differential;
}
@end

@implementation WFSlideMetadataAnimator

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
    
    differential = width/3;
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
    
        CGRect toEndFrame;
        if (iOS8){
            [toView setFrame:CGRectMake(width, 0, (differential), height)];
            [toViewController setPreferredContentSize:CGSizeMake((differential), height)];
            toEndFrame = toView.frame;
            toEndFrame.origin.x -= differential;
        } else {
            [toView setFrame:CGRectMake(0, -width, width, (differential))];
            [toViewController setPreferredContentSize:CGSizeMake((differential), width)];
            toEndFrame = toView.frame;
            toEndFrame.origin.x = 0;
            toEndFrame.origin.y = 0;
        }
        
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:toView];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [toView setFrame:toEndFrame];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    
    } else {
        toViewController.view.userInteractionEnabled = YES;
        
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
        CGRect fromEndFrame;
        if (iOS8){
            fromEndFrame = fromView.frame;
            fromEndFrame.origin.x = width;
        } else {
            fromEndFrame = CGRectMake(0, -width, width, differential);
        }
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [fromView setFrame:fromEndFrame];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
            NSLog(@"toView from slideMetadataAnimator? %@",toView);
        }];
    }
}

@end