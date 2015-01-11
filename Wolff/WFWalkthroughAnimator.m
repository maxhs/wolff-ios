//
//  WFWalkthroughAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/10/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFWalkthroughAnimator.h"
#import "Constants.h"
#import "UIImage+ImageEffects.h"

@interface WFWalkthroughAnimator () {
    CGFloat width;
    CGFloat height;
}
@end

@implementation WFWalkthroughAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    CGRect mainScreen;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
        mainScreen = [UIScreen mainScreen].bounds;
    } else {
        width = screenHeight();
        height = screenWidth();
        mainScreen = CGRectMake(0, 0, height, width);
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
        fromViewController.view.userInteractionEnabled = NO;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        
        UIButton *blurredButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [blurredButton setBackgroundImage:[self blurredSnapshotForWindow:[transitionContext.containerView window]]  forState:UIControlStateNormal];
        [blurredButton setFrame:mainScreen];
        [blurredButton setAlpha:0.0];
        [blurredButton setTag:kBlurredBackgroundConstant];
        
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView insertSubview:blurredButton belowSubview:toView];
        [toView setFrame:mainScreen];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.875 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [blurredButton setAlpha:1.0];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
        
    } else {
        
        toViewController.view.userInteractionEnabled = YES;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        UIImageView *blurredButton = (UIImageView*)[transitionContext.containerView viewWithTag:kBlurredBackgroundConstant];
        
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
        /*mainScreen.origin.x -= screenWidth();
         CGRect originStartFrame = toViewController.view.frame;
         originStartFrame.origin.x = screenWidth();
         toViewController.view.frame = originStartFrame;
         CGRect originEndFrame = toViewController.view.frame;
         originEndFrame.origin.x = 0;*/
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [fromView setAlpha:0.0];
            [blurredButton setAlpha:0.0];
        } completion:^(BOOL finished) {
            [blurredButton removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }
}

-(UIImage *)blurredSnapshotForWindow:(UIWindow*)window {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, window.screen.scale);
    [window drawViewHierarchyInRect:CGRectMake(0, 0, width, height) afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

@end
