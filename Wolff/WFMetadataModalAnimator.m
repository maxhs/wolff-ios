//
//  WFMetadataModalAnimator.m
//  Wolff
//
//  Created by Max Haines-Stiles on 2/21/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFMetadataModalAnimator.h"
#import "Constants.h"
#import "WFArtMetadataViewController.h"

@implementation WFMetadataModalAnimator
- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return .75f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    CGFloat width, height;
    width = screenWidth(); height = screenHeight();
    
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController, *toViewController;
    fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Set our ending frame. We'll modify this later if we have to
    CGRect endFrame = [UIScreen mainScreen].bounds;
    
    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        [transitionContext.containerView addSubview:toViewController.view];
        
        CGRect startFrame = endFrame;
        startFrame.origin.y -= height;
        
        CGRect originEndFrame = fromViewController.view.frame;
        originEndFrame.origin.y += height;
        
        toViewController.view.frame = startFrame;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.975 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toViewController.view.frame = endFrame;
            fromViewController.view.frame = originEndFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else {
        toViewController.view.userInteractionEnabled = YES;
        
        CGRect metadataFrame = CGRectMake(width/2-kMetadataWidth/2, 0, kMetadataWidth, height);
        metadataFrame.origin.y = 10;
        metadataFrame.origin.x -= 100;
        metadataFrame.size.width += 200;
        CGRect modalEndFrame = fromViewController.view.frame;
        modalEndFrame.origin.y -= height;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            toViewController.view.frame = metadataFrame;
            fromViewController.view.frame = modalEndFrame;
            [toViewController.view setAlpha:1.0];
            
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}
@end
