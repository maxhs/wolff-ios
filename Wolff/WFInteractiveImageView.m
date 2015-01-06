//
//  WFInteractiveImageView.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/2/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFInteractiveImageView.h"
@interface WFInteractiveImageView (){
    UILongPressGestureRecognizer *longPressGesture;
}
@property NSTimer *timer;
@end

@implementation WFInteractiveImageView

@synthesize photo = _photo;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setupGestures {
    longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:longPressGesture];
}

- (void)awakeFromNib {
    [self setupGestures];
}

- (id)initWithFrame:(CGRect)frame andPhoto:(Photo *)photo {
    self = [super initWithFrame:frame];
    if (self) {
        _photo = photo;
        [self setupGestures];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image andPhoto:(Photo *)photo {
    self = [super initWithImage:image];
    if (self) {
        _photo = photo;
        [self setupGestures];
    }
    return self;
}

- (void)longPress:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan){
        self.timer = [NSTimer scheduledTimerWithTimeInterval:.01f target:self selector:@selector(removalTimer) userInfo:nil repeats:NO];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.timer)[self.timer invalidate];
    }
}

-(void)removalTimer {
    if (self.imageViewDelegate && [self.imageViewDelegate respondsToSelector:@selector(longPressGesture:)]){
        [self.imageViewDelegate longPressGesture:longPressGesture];
    }
    [self.timer invalidate];
}

@end
