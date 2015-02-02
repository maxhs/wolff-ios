//
//  WFProfileAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/24/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFProfileAnimator.h"
#import "Constants.h"
#import "WFProfileViewController.h"
#import "UIImage+ImageEffects.h"

@interface WFProfileAnimator (){
    BOOL iOS8;
    CGFloat width;
    CGFloat height;
    CGRect mainScreen;
}

@end
@implementation WFProfileAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
        mainScreen = [UIScreen mainScreen].bounds;
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
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
    
    if (self.presenting) {
        UIButton *blurredButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [blurredButton setBackgroundImage:[self blurredSnapshotForWindow:[transitionContext.containerView window]]  forState:UIControlStateNormal];
        [blurredButton setAdjustsImageWhenHighlighted:NO];
        
        //this is a little fragile, since if the view hierarchy changes, this will break
        //UINavigationController *nav = (UINavigationController*)toViewController;
        [blurredButton addTarget:(WFProfileViewController*)toViewController action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [blurredButton setFrame:mainScreen];
        [blurredButton setAlpha:0.0];
        [blurredButton setTag:kBlurredBackgroundConstant];
        
        [transitionContext.containerView addSubview:fromView];
        [transitionContext.containerView addSubview:blurredButton];
        [transitionContext.containerView addSubview:toView];
        
        [toView setAlpha:0.0];
        
        CGRect startFrame;
        if (iOS8){
            startFrame = mainScreen;
            startFrame.origin.y += height;
        } else {
            startFrame = mainScreen;
            startFrame.origin.x += width;
        }
        
        toViewController.view.frame = startFrame;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.975 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toView.frame = mainScreen;
            [blurredButton setAlpha:1.0];
            [toView setAlpha:1.0];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    
    } else {
        UIButton *blurredBackground = (UIButton*)[transitionContext.containerView viewWithTag:kBlurredBackgroundConstant];
        [transitionContext.containerView addSubview:toView];
        [transitionContext.containerView addSubview:fromView];
        
        CGRect originEndFrame;
        if (iOS8){
            originEndFrame = mainScreen;
            originEndFrame.origin.y -= height;
        } else {
            originEndFrame = mainScreen;
            originEndFrame.origin.x -= width;
        }
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.975 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromView.frame = originEndFrame;
            [fromView setAlpha:0.0];
            [blurredBackground setAlpha:0.0];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
            [blurredBackground removeFromSuperview];
        }];
    }
}

-(UIImage *)blurredSnapshotForWindow:(UIWindow*)window {
    UIGraphicsBeginImageContextWithOptions(mainScreen.size, NO, window.screen.scale);
    [window drawViewHierarchyInRect:mainScreen afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

@end