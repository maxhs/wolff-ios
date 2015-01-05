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
}
@end

@implementation WFSlideMetadataAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return kDefaultAnimationDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
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
    
    // Set our ending frame. We'll modify this later if we have to
    CGRect mainScreen = [UIScreen mainScreen].bounds;
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        
        UIButton *blurredButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [blurredButton setBackgroundImage:[self blurredSnapshotForWindow:[transitionContext.containerView window]]  forState:UIControlStateNormal];
        
        //this is a little fragile, since if the view hierarchy changes, this will break
        UINavigationController *nav = (UINavigationController*)toViewController;
        [blurredButton addTarget:(WFSlideMetadataViewController*)nav.viewControllers.firstObject action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [blurredButton setFrame:mainScreen];
        [blurredButton setAlpha:0.0];
        [blurredButton setTag:kBlurredBackgroundConstant];
        
        CGFloat differential = width/3;
        [toView setFrame:CGRectMake(width, 0, (differential), height)];
        [toViewController setPreferredContentSize:CGSizeMake((differential), height)];
        CGRect toEndFrame = toView.frame;
        toEndFrame.origin.x -= differential;
        
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:toView];
        
        [transitionContext.containerView insertSubview:blurredButton belowSubview:toView];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [blurredButton setAlpha:1.0];
            [toView setFrame:toEndFrame];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    else {
        UIImageView *blurredButton = (UIImageView*)[transitionContext.containerView viewWithTag:kBlurredBackgroundConstant];
        toViewController.view.userInteractionEnabled = YES;
        
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
        CGRect fromEndFrame = fromView.frame;
        fromEndFrame.origin.x = width;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [blurredButton setAlpha:0.0];
            [fromView setFrame:fromEndFrame];
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
