//
//  WFTransparentBGModalAnimator.h
//  Wolff
//
//  Created by Max Haines-Stiles on 4/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WFTransparentBGModalAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property BOOL dark;
@property (nonatomic, assign, getter = isPresenting) BOOL presenting;

@end
