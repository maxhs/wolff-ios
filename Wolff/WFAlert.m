//
//  WFAlert.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/3/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFAlert.h"
#import "Constants.h"
#import "UIImage+ImageEffects.h"
#import "WFAppDelegate.h"

@interface WFAlert () {
    CGFloat dismissTime;
    CGFloat width;
    CGFloat height;
    UITapGestureRecognizer *dismissGesture;
}
@end

@implementation WFAlert

@synthesize window, background, label;

+ (WFAlert *)shared {
    static dispatch_once_t once = 0;
    static WFAlert *alert;
    dispatch_once(&once, ^{ alert = [[WFAlert alloc] init]; });
    return alert;
}

+ (void)dismiss {
    [[self shared] hideAlert];
}

+ (void)show:(NSString *)status withTime:(CGFloat)time {
    [[self shared] make:status spin:YES hide:NO withTime:time];
}

+ (void)show:(NSString *)status withTime:(CGFloat)time andOffset:(CGPoint)centerOffset {
    [[self shared] make:status spin:YES hide:NO withTime:time];
}

+ (void)showSuccess:(NSString *)status {
    //[[self shared] make:status imgage:HUD_IMAGE_SUCCESS spin:NO hide:YES];
}

+ (void)showError:(NSString *)status {
    //[[self shared] make:status imgage:HUD_IMAGE_ERROR spin:NO hide:YES];
}

- (id)init {
    self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
    id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate respondsToSelector:@selector(window)])
        window = [delegate performSelector:@selector(window)];
    else window = [[UIApplication sharedApplication] keyWindow];
    background = nil; label = nil;
    self.alpha = 0;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        width = screenHeight();
        height = screenWidth();
    }
    
    dismissGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideAlert)];
    dismissGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:dismissGesture];
    
    return self;
}

- (void)make:(NSString *)status spin:(BOOL)spin hide:(BOOL)hide withTime:(CGFloat)time {
    dismissTime = time;
    [self create];
    label.text = status;
    label.hidden = (status == nil) ? YES : NO;
    [self orient];
    [self showAlert];
}

- (void)create {
    if (background == nil) {
        
        background = [[UIImageView alloc] initWithImage:[self blurredSnapshotForWindow]];
        [background setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [background setFrame:self.window.frame];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [self addSubview:background];
    }
    
    if (label == nil) {
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0];
        [label setTextColor:[UIColor whiteColor]];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.numberOfLines = 0;
        [background addSubview:label];
        [label setFrame:CGRectMake(10, background.frame.size.height/2-160, background.frame.size.width-20, 320)];
    }
}

-(UIImage *)blurredSnapshotForWindow {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [UIScreen mainScreen].scale);
    [window drawViewHierarchyInRect:CGRectMake(0, 0, width, height) afterScreenUpdates:NO];
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
    UIGraphicsEndImageContext();
    return blurredSnapshotImage;
}

- (void)rotate:(NSNotification *)notification {
    [self orient];
}

- (void)orient {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        
    } else {
        CGFloat rotate;
        UIInterfaceOrientation orient;
        
        if (IDIOM == IPAD){
            orient = self.window.rootViewController.interfaceOrientation;
        } else {
            orient = [[UIApplication sharedApplication] statusBarOrientation];
        }
        if (orient == UIInterfaceOrientationPortrait)                   rotate = 0.0;
        else if (orient == UIInterfaceOrientationPortraitUpsideDown)	rotate = M_PI;
        else if (orient == UIInterfaceOrientationLandscapeLeft)         rotate = - M_PI_2;
        else if (orient == UIInterfaceOrientationLandscapeRight)		rotate = + M_PI_2;
        else rotate = 0.0;
        background.transform = CGAffineTransformMakeRotation(rotate);
    }
}

- (void)showAlert {
    [self.window addSubview:self];
    if (self.alpha == 0) {
        self.alpha = 1;
        background.alpha = 0;
        NSUInteger options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut;
        [UIView animateWithDuration:0.3 delay:0 options:options animations:^{
            background.alpha = 1;
        } completion:^(BOOL finished){
            [self performSelector:@selector(hideAlert) withObject:nil afterDelay:dismissTime];
        }];
    }
}

- (void)hideAlert {
    if (self.alpha == 1) {
        NSUInteger options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseIn;
        [UIView animateWithDuration:0.3 delay:0 options:options animations:^{
            background.alpha = 0;
        } completion:^(BOOL finished) {
            [self destroy];
            self.alpha = 0;
        }];
    }
}

- (void)destroy {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [label removeFromSuperview];	label = nil;
    [background removeFromSuperview];	background = nil;
}

- (void)timedHide {
    @autoreleasepool
    {
        double length = label.text.length;
        NSTimeInterval sleep = length * 0.04 + 0.5;
        
        [NSThread sleepForTimeInterval:sleep];
        [self hideAlert];
    }
}


@end
