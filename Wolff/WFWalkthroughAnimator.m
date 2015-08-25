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
    CGRect mainScreen;
}
@end

@implementation WFWalkthroughAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .4f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    width = screenWidth(); height = screenHeight();
    mainScreen = [UIScreen mainScreen].bounds;
    
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    
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
