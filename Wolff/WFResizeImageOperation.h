//
//  WFResizeImageOperation.h
//  Wolff
//
//  Created by Max Haines-Stiles on 8/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^WFResizeImageCompletionBlock)(UIImage *image);

@interface WFResizeImageOperation : NSOperation
@property (strong, nonatomic) UIImage *image;
@property (nonatomic, copy) void (^doneBlock)(UIImage * image);
- (id) initWithImage:(UIImage *)image;
@end
