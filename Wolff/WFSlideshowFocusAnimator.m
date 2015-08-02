//
//  WFSlideshowFocusAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideshowFocusAnimator.h"
#import "UIImage+ImageEffects.h"
#import "Constants.h"
#import "WFSlideshowViewController.h"

@interface WFSlideshowFocusAnimator () {
    CGFloat width;
    CGFloat height;

}

@end
@implementation WFSlideshowFocusAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    width = screenWidth(); height = screenHeight();
    CGRect mainScreen = [UIScreen mainScreen].bounds;

    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        
        UIButton *blurredButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [blurredButton setBackgroundImage:[self blurredSnapshotForWindow:[transitionContext.containerView window]]  forState:UIControlStateNormal];
        
        //this is a little fragile, since if the view hierarchy changes, this will break
        UINavigationController *nav = (UINavigationController*)toViewController;
        [blurredButton addTarget:nav.viewControllers.firstObject action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [blurredButton setFrame:mainScreen];
        [blurredButton setAlpha:0.0];
        [blurredButton setTag:kBlurredBackgroundConstant];
        
        [toViewController.view setFrame:mainScreen];
        toViewController.view.transform = CGAffineTransformMakeScale(.95, .95);
        [toViewController.view setAlpha:0.0];
        
        [transitionContext.containerView addSubview:blurredButton];
        [transitionContext.containerView addSubview:toViewController.view];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.75 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [blurredButton setAlpha:1.0];
            [toViewController.view setAlpha:1.0];
            toViewController.view.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    
    } else {
    
        UIImageView *blurredButton = (UIImageView*)[transitionContext.containerView viewWithTag:kBlurredBackgroundConstant];
        toViewController.view.userInteractionEnabled = YES;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext]*.7 delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [blurredButton setAlpha:0.0];
            [fromViewController.view setAlpha:0.0];
            fromViewController.view.transform = CGAffineTransformMakeScale(.925, .925);
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
