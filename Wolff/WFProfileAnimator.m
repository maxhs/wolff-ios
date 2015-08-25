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
#import "WFArtMetadataViewController.h"

@interface WFProfileAnimator (){
    CGFloat width;
    CGFloat height;
    CGRect mainScreen;
}

@end
@implementation WFProfileAnimator

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
        [transitionContext.containerView addSubview:toViewController.view];
        
        CGRect startFrame = mainScreen;
        startFrame.origin.y += height;
        toViewController.view.frame = startFrame;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseIn animations:^{
            toViewController.view.frame = mainScreen;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    
    } else {
        
        UINavigationController *nav = (UINavigationController*)toViewController;
        if ([nav.viewControllers.firstObject isKindOfClass:[WFArtMetadataViewController class]]){
            WFArtMetadataViewController *artvc = (WFArtMetadataViewController*)nav.viewControllers.firstObject;
            CGFloat offset = height/2-350;
            UITableView *metadataTableView = artvc.tableView;
            [metadataTableView setContentInset:UIEdgeInsetsMake(offset, 0, offset, 0)];
            [metadataTableView setContentOffset:CGPointMake(0, -offset)];
            int lowerBound = 1; int upperBound = 3;
            int rndValue = lowerBound + arc4random() % (upperBound - lowerBound);
            CGFloat xOffset = rndValue == 1 ? width : -width;
            
            CGRect metadataStartFrame = CGRectMake((width/2-kMetadataWidth/2)-xOffset, 0, kMetadataWidth, height);
            toViewController.view.frame = metadataStartFrame;
        }
        
        CGRect endFrame = mainScreen;
        endFrame.origin.y = height;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            fromViewController.view.frame = endFrame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
