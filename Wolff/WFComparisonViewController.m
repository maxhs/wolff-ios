//
//  WFComparisonViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/3/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFComparisonViewController.h"
#import "Constants.h"
#import "WFAppDelegate.h"
#import "WFSlideshowSlideCell.h"
#import "WFInteractiveImageView.h"
#import "WFSlideMetadataAnimator.h"
#import "WFSlideMetadataViewController.h"

@interface WFComparisonViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate> {
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *metadataButton;
    UIImageView *artImageView2;
    UIImageView *artImageView3;
    UIView *containerView2;
    UIView *containerView3;
    UIPanGestureRecognizer *_panGesture2;
    UIPanGestureRecognizer *_panGesture3;
    UIRotationGestureRecognizer *_rotationGesture2;
    UIRotationGestureRecognizer *_rotationGesture3;
    UIPinchGestureRecognizer *_pinchGesture2;
    UIPinchGestureRecognizer *_pinchGesture3;
    UITapGestureRecognizer *_doubleTapGesture1;
    UITapGestureRecognizer *_doubleTapGesture2;
    UITapGestureRecognizer *_doubleTapGesture3;
    CGPoint savedPoint2;
    CGPoint savedPoint3;
    CGFloat lastScale;
    CGRect originalFrame2;
    CGRect originalFrame3;
    CGPoint lastPoint;
}

@end

@implementation WFComparisonViewController

@synthesize arts = _arts;

- (void)viewDidLoad {
    [super viewDidLoad];
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    metadataButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info"] style:UIBarButtonItemStylePlain target:self action:@selector(showMetadata)];
    
    self.navigationItem.rightBarButtonItem = metadataButton;
    
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.f){
        self.navigationController.hidesBarsOnTap = YES;
    }
    if (!_panGesture2) {
        _panGesture2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _panGesture3 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    }
    
    if (!_rotationGesture2) {
        _rotationGesture2 = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
        _rotationGesture3 = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    }
    
    if (!_pinchGesture2) {
        _pinchGesture2 = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        _pinchGesture3 = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    }
    
    if(!_doubleTapGesture2){
        _doubleTapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _doubleTapGesture2.numberOfTapsRequired = 2;
        _doubleTapGesture3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _doubleTapGesture3.numberOfTapsRequired = 2;
        _doubleTapGesture1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reset)];
        _doubleTapGesture1.numberOfTapsRequired = 2;
    }
    savedPoint2 = CGPointZero;
    savedPoint3 = CGPointZero;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
    // this is the global reset gesture
    [self.view addGestureRecognizer:_doubleTapGesture1];
}

- (void)showMetadata {
    WFSlideMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideMetadata"];
    [vc setArts:_arts];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

#pragma mark - Handle Gestures

- (void)handlePan:(UIPanGestureRecognizer*)gestureRecognizer {
    UIView *viewInQuestion;
    if (gestureRecognizer == _panGesture2){
        viewInQuestion = containerView2;
    } else if (gestureRecognizer == _panGesture3) {
        viewInQuestion = containerView3;
    }
    
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    CGPoint newPoint = CGPointMake(gestureRecognizer.view.center.x + translation.x, gestureRecognizer.view.center.y + translation.y);
    if (newPoint.x > 0){
        gestureRecognizer.view.center = newPoint;
    }
    [gestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}


- (void)handleRotation:(UIRotationGestureRecognizer*)gestureRecognizer {
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        [gestureRecognizer view].transform = CGAffineTransformRotate([[gestureRecognizer view] transform], [gestureRecognizer rotation]);
        [gestureRecognizer setRotation:0];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer*)gestureRecognizer {
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        lastScale = gestureRecognizer.scale;
    }
    
    const CGFloat kMaxScale = CGFLOAT_MAX;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan || gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat currentScale = [[gestureRecognizer.view.layer valueForKeyPath:@"transform.scale"] floatValue];
        const CGFloat kMinScale = .5;
        CGFloat newScale = 1 -  (lastScale - gestureRecognizer.scale);
        newScale = MIN(newScale, kMaxScale / currentScale);
        newScale = MAX(newScale, kMinScale / currentScale);
        CGAffineTransform transform = CGAffineTransformScale(gestureRecognizer.view.transform, newScale, newScale);
        gestureRecognizer.view.transform = transform;
    }
    lastScale = gestureRecognizer.scale;  // Store the previous scale factor for the next pinch gesture call
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded && lastScale < 1.f) {
        CGFloat currentScale = [[gestureRecognizer.view.layer valueForKeyPath:@"transform.scale"] floatValue];
        const CGFloat kMinScale = 1.0;
        CGFloat newScale = 1 -  (lastScale - gestureRecognizer.scale);
        newScale = MIN(newScale, kMaxScale / currentScale);
        newScale = MAX(newScale, kMinScale / currentScale);
        CGAffineTransform transform = CGAffineTransformScale(gestureRecognizer.view.transform, newScale, newScale);
        
        [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            gestureRecognizer.view.transform = transform;
        } completion:^(BOOL finished) {
            lastScale = gestureRecognizer.scale;  // Store the previous scale factor for the next pinch gesture call
        }];
    }
}

- (void)handleTap:(UITapGestureRecognizer*)gestureRecognizer {
    
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.77 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        gestureRecognizer.view.transform = CGAffineTransformIdentity;
        if (gestureRecognizer == _doubleTapGesture2){
            [gestureRecognizer.view setFrame:originalFrame2];
        } else {
            [gestureRecognizer.view setFrame:originalFrame3];
        }
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)reset {
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.7 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        artImageView2.transform = CGAffineTransformIdentity;
        artImageView2.transform = CGAffineTransformIdentity;
        [artImageView2 setFrame:originalFrame2];
        [artImageView3 setFrame:originalFrame3];
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFSlideshowSlideCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ComparisonCell" forIndexPath:indexPath];
    [cell configureForArts:_arts inSlide:nil];
    artImageView2 = cell.artImageView2;
    containerView2 = cell.containerView2;
    [cell.artImageView2 addGestureRecognizer:_panGesture2];
    [cell.artImageView2 addGestureRecognizer:_pinchGesture2];
    [cell.artImageView2 addGestureRecognizer:_doubleTapGesture2];
    [cell.artImageView2 addGestureRecognizer:_rotationGesture2];
    
    artImageView3 = cell.artImageView3;
    containerView3 = cell.containerView3;
    [cell.artImageView3 addGestureRecognizer:_panGesture3];
    [cell.artImageView3 addGestureRecognizer:_pinchGesture3];
    [cell.artImageView3 addGestureRecognizer:_doubleTapGesture3];
    [cell.artImageView3 addGestureRecognizer:_rotationGesture3];
    
    originalFrame2 = cell.artImageView2.frame;
    originalFrame3 = cell.artImageView3.frame;
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.frame.size.width,collectionView.frame.size.height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark Dismiss & Transition Methods
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    WFSlideMetadataAnimator *animator = [WFSlideMetadataAnimator new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    
    WFSlideMetadataAnimator *animator = [WFSlideMetadataAnimator new];
    return animator;
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
