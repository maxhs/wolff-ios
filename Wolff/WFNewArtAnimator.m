//
//  WFNewArtAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFNewArtAnimator.h"
#import "Constants.h"
#import "WFNewArtViewController.h"

@interface WFNewArtAnimator () {
    CGFloat width;
    CGFloat height;
    CGRect mainScreen;
}

@end

@implementation WFNewArtAnimator
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {

    width = screenWidth(); height = screenHeight();
    mainScreen = [UIScreen mainScreen].bounds;

    // Grab the from and to view controllers from the context
    UIViewController *fromViewController, *toViewController;
    fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    
    if (self.presenting) {
        
        UIButton *darkBackground = [UIButton buttonWithType:UIButtonTypeCustom];
        [darkBackground setBackgroundColor:[UIColor colorWithWhite:.1 alpha:.5]];
        [darkBackground setAlpha:0.0];
        [darkBackground setFrame:mainScreen];
        [darkBackground setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [darkBackground setTag:kDarkBackgroundConstant];
        [darkBackground addTarget:(WFNewArtViewController*)toViewController action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
        
        [transitionContext.containerView addSubview:darkBackground];
        [transitionContext.containerView addSubview:toViewController.view];
        [toViewController.view setAlpha:0.0];
        
        UIToolbar *toolbarBackground; // set the new art view background here, becuase we're resetting the framing (and it's not reflects in either the viewDidLoad or viewWillAppear methods
        CGRect newArtStartFrame = CGRectMake(0, 0, width, height);
        toViewController.view.frame = newArtStartFrame;
        toolbarBackground = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, toViewController.view.frame.size.width, toViewController.view.frame.size.height)];
     
        [toolbarBackground setBarStyle:UIBarStyleBlackTranslucent];
        [toolbarBackground setTranslucent:YES];
        [toViewController.view addSubview:toolbarBackground];
        [toViewController.view sendSubviewToBack:toolbarBackground];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.875 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [toViewController.view setAlpha:1.0];
            [darkBackground setAlpha:1.0];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else {
        UIButton *darkBackground = (UIButton*)[transitionContext.containerView viewWithTag:kDarkBackgroundConstant];
        toViewController.view.userInteractionEnabled = YES;
        
        NSTimeInterval outDuration = [self transitionDuration:transitionContext]*.7;
        [UIView animateWithDuration:outDuration delay:0 usingSpringWithDamping:.8 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            fromViewController.view.transform = CGAffineTransformMakeScale(.87, .87);
            [fromViewController.view setAlpha:0.0];
            [darkBackground setAlpha:0.0];
        } completion:^(BOOL finished) {
            [darkBackground removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }
}
@end
