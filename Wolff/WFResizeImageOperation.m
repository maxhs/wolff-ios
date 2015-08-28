//
//  WFResizeImageOperation.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/26/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFResizeImageOperation.h"

@implementation WFResizeImageOperation

-(id) initWithImage:(UIImage *)image
{
    self = [super init];
    self.image = image;
    return self;
}

-(void)main {
    @autoreleasepool {
        [self resizeImageIfNecessary];
    }
}

- (void)resizeImageIfNecessary {
    NSData  *imageData    = UIImageJPEGRepresentation(self.image, 1);
    double   factor       = 1;
    double   adjustment   = .5;  // or use 0.8 or whatever you want
    UIImage *currentImage = self.image;
    
    while (imageData.length > 4000000 && !self.isCancelled) {
        if (self.isCancelled) return;
        factor *= adjustment;
        imageData = UIImageJPEGRepresentation(currentImage, factor);
        currentImage = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
        NSLog(@"New, smaller image size: %lu",(unsigned long)imageData.length);
    }
    if (self.isCancelled) {
        NSLog(@"Op was canceled. Returning");
        return;
    }
    if (self.doneBlock != nil) {
        self.doneBlock(currentImage);
    }
}

@end
