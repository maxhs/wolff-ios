//
//  WFSlideMetadataAnimator.h
//  Wolff
//
//  Created by Max Haines-Stiles on 1/4/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WFSlideMetadataAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isPresenting) BOOL presenting;


@end
