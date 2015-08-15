//
//  WFSettingsAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSettingsAnimator.h"
#import "UIImage+ImageEffects.h"
#import "Constants.h"
#import "WFSettingsViewController.h"

@interface WFSettingsAnimator () {
    CGFloat width;
    CGFloat height;
    CGRect mainScreen;
}
@end

@implementation WFSettingsAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return kDefaultAnimationDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    width = screenWidth(); height = screenHeight();
    mainScreen = [UIScreen mainScreen].bounds;
    
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.presenting) {
        
        UIButton *blurredButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [blurredButton setBackgroundImage:[self blurredSnapshotForWindow:[transitionContext.containerView window]]  forState:UIControlStateNormal];
        [blurredButton setAdjustsImageWhenHighlighted:NO];
        
        //this is a little fragile, since if the view hierarchy changes, this will break
        UINavigationController *nav = (UINavigationController*)toViewController;
        [blurredButton addTarget:(WFSettingsViewController*)nav.viewControllers.firstObject action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        [blurredButton setFrame:mainScreen];
        [blurredButton setAlpha:0.0];
        [blurredButton setTag:kBlurredBackgroundConstant];
        
        [transitionContext.containerView addSubview:blurredButton];
        [transitionContext.containerView addSubview:toViewController.view];
        

        CGFloat differential = IDIOM == IPAD ? width/2 : width*.75;
        [toViewController.view setFrame:CGRectMake(width, 0, differential, height)];
        CGRect toEndFrame = toViewController.view.frame;
        toEndFrame.origin.x -= differential;
       
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [blurredButton setAlpha:1.0];
            [toViewController.view setFrame:toEndFrame];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
    else {
        UIImageView *blurredButton = (UIImageView*)[transitionContext.containerView viewWithTag:kBlurredBackgroundConstant];
        
        CGRect fromEndFrame = fromViewController.view.frame;
        fromEndFrame.origin.x = width;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [blurredButton setAlpha:0.0];
            [fromViewController.view setFrame:fromEndFrame];
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
    UIImage *blurredSnapshotImage = _dark ? [snapshotImage applyDarkEffect] : [snapshotImage applyLightEffect];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}
@end
