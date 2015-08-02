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
    CGRect mainScreen;
    CGFloat differential;
}
@end

@implementation WFSlideMetadataAnimator

@synthesize orientation = _orientation;

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return kDefaultAnimationDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    width = screenWidth();
    height = screenHeight();
    mainScreen = [UIScreen mainScreen].bounds;
    
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController, *toViewController;
    fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    differential = height/4;
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
    
        [toViewController.view setFrame:CGRectMake(0, height, width, height)];
        [toViewController setPreferredContentSize:CGSizeMake(width, differential)];
        CGRect toEndFrame = toViewController.view.frame;
        toEndFrame.origin.y = height - differential;
        
        UIButton *removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [removeButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.5]];
        UINavigationController *nav = (UINavigationController*)toViewController;
        UIViewController *firstVC = nav.viewControllers.firstObject;
        if ([firstVC isKindOfClass:[WFSlideMetadataViewController class]]){
            [removeButton addTarget:(WFSlideMetadataViewController*)firstVC action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        }
        [removeButton setFrame:mainScreen];
        [removeButton setTag:kDarkBackgroundConstant];
        [removeButton setAlpha:0.0];
        
        [transitionContext.containerView addSubview:removeButton]; // order matters here
        [transitionContext.containerView addSubview:toViewController.view];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [toViewController.view setFrame:toEndFrame];
            [removeButton setAlpha:1.0];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    
    } else {
        toViewController.view.userInteractionEnabled = YES;
        UIButton *removeButton = (UIButton*)[transitionContext.containerView viewWithTag:kDarkBackgroundConstant];
        
        CGRect fromEndFrame = fromViewController.view.frame;
        fromEndFrame.origin.y = height;
        
        [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [fromViewController.view setFrame:fromEndFrame];
            [removeButton setAlpha:0.0];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
            [removeButton removeFromSuperview];
        }];
    }
}

@end