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
    BOOL iOS8;
    CGRect mainScreen;
}
@end

@implementation WFWalkthroughAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
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
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:toView];
        [toView setFrame:mainScreen];
        [toView setAlpha:0.0];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            [toView setAlpha:1.0];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
        
    } else {
        
        toViewController.view.userInteractionEnabled = YES;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
        /*mainScreen.origin.x -= screenWidth();
         CGRect originStartFrame = toViewController.view.frame;
         originStartFrame.origin.x = screenWidth();
         toViewController.view.frame = originStartFrame;
         CGRect originEndFrame = toViewController.view.frame;
         originEndFrame.origin.x = 0;*/
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            [fromView setAlpha:0.0];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

-(UIImage *)blurredSnapshotForWindow:(UIWindow*)window {
    UIGraphicsBeginImageContextWithOptions(mainScreen.size, NO, window.screen.scale);
    [window drawViewHierarchyInRect:mainScreen afterScreenUpdates:YES];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyExtraLightEffect];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

@end
