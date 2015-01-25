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
#import "WFArtMetadataViewController.h"
#import "WFUtilities.h"

@interface WFComparisonViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate> {
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *metadataButton;
    UIImageView *artImageView1;
    UIImageView *artImageView2;
    UIImageView *artImageView3;
    UIView *containerView1;
    UIView *containerView2;
    UIView *containerView3;
    UIPanGestureRecognizer *_panGesture1;
    UIPanGestureRecognizer *_panGesture2;
    UIPanGestureRecognizer *_panGesture3;
    /*UIRotationGestureRecognizer *_rotationGesture1;
    UIRotationGestureRecognizer *_rotationGesture2;
    UIRotationGestureRecognizer *_rotationGesture3;*/
    UIPinchGestureRecognizer *_pinchGesture1;
    UIPinchGestureRecognizer *_pinchGesture2;
    UIPinchGestureRecognizer *_pinchGesture3;
    UITapGestureRecognizer *_doubleTapGesture1;
    UITapGestureRecognizer *_doubleTapGesture2;
    UITapGestureRecognizer *_doubleTapGesture3;
    
    CGFloat lastScale;
    CGRect originalFrame1;
    CGRect originalFrame2;
    CGRect originalFrame3;
    CGPoint lastPoint;
    
    CGFloat width;
    CGFloat height;
    BOOL iOS8;
    UIImageView *navBarShadowView;
}

@end

@implementation WFComparisonViewController

@synthesize photos = _photos;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    metadataButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info"] style:UIBarButtonItemStylePlain target:self action:@selector(showMetadata)];
    self.navigationItem.rightBarButtonItem = metadataButton;
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
        self.navigationController.hidesBarsOnTap = YES;
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
    }
    
    if (_photos.count == 1){
        _panGesture1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        _pinchGesture1 = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        /*_rotationGesture1 = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
        [_rotationGesture1 requireGestureRecognizerToFail:_pinchGesture1];*/
    } else {
        if (!_panGesture2) {
            _panGesture2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
            _panGesture3 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        }
        
        /*if (!_rotationGesture2) {
            _rotationGesture2 = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
            _rotationGesture3 = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
        }*/
        
        if (!_pinchGesture2) {
            _pinchGesture2 = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
            _pinchGesture3 = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        }
        /*[_rotationGesture2 requireGestureRecognizerToFail:_pinchGesture2];
        [_rotationGesture3 requireGestureRecognizerToFail:_pinchGesture3];*/
    }
    
    if(!_doubleTapGesture2){
        _doubleTapGesture1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _doubleTapGesture1.numberOfTapsRequired = 2;
        _doubleTapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _doubleTapGesture2.numberOfTapsRequired = 2;
        _doubleTapGesture3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _doubleTapGesture3.numberOfTapsRequired = 2;
    }
    
    /*[_rotationGesture2 requireGestureRecognizerToFail:_panGesture2];
    [_rotationGesture3 requireGestureRecognizerToFail:_panGesture3];
    [_rotationGesture2 requireGestureRecognizerToFail:_pinchGesture2];
    [_rotationGesture3 requireGestureRecognizerToFail:_pinchGesture3];*/
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
    [navBarShadowView setHidden:YES];
    // this is the global reset gesture
    [self.view addGestureRecognizer:_doubleTapGesture1];
}

- (void)showMetadata {
    WFSlideMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideMetadata"];
    [vc setPhotos:_photos];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

#pragma mark - Handle Gestures

- (void)handlePan:(UIPanGestureRecognizer*)gestureRecognizer {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    CGPoint newPoint = CGPointMake(gestureRecognizer.view.center.x + translation.x, gestureRecognizer.view.center.y + translation.y);
    gestureRecognizer.view.center = newPoint;
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
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.87 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        gestureRecognizer.view.transform = CGAffineTransformIdentity;
        if (gestureRecognizer == _doubleTapGesture1){
            [gestureRecognizer.view setFrame:originalFrame1];
        } else if (gestureRecognizer == _doubleTapGesture2){
            [gestureRecognizer.view setFrame:originalFrame2];
        } else {
            [gestureRecognizer.view setFrame:originalFrame3];
        }
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)reset {
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.87 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [artImageView1 setFrame:originalFrame1];
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
    [cell configureForPhotos:_photos inSlide:nil];
    
    if (_photos.count == 1){
        artImageView1 = cell.artImageView1;
        containerView1 = cell.containerView1;
        [artImageView1 addGestureRecognizer:_panGesture1];
        [artImageView1 addGestureRecognizer:_pinchGesture1];
        [artImageView1 addGestureRecognizer:_doubleTapGesture1];
        //[artImageView1 addGestureRecognizer:_rotationGesture1];
        originalFrame1 = cell.artImageView1.frame;
    } else {
        artImageView2 = cell.artImageView2;
        containerView2 = cell.containerView2;
        [cell.artImageView2 addGestureRecognizer:_panGesture2];
        [cell.artImageView2 addGestureRecognizer:_pinchGesture2];
        [cell.artImageView2 addGestureRecognizer:_doubleTapGesture2];
        //[cell.artImageView2 addGestureRecognizer:_rotationGesture2];
        originalFrame2 = cell.artImageView2.frame;
    
        artImageView3 = cell.artImageView3;
        containerView3 = cell.containerView3;
        [cell.artImageView3 addGestureRecognizer:_panGesture3];
        [cell.artImageView3 addGestureRecognizer:_pinchGesture3];
        [cell.artImageView3 addGestureRecognizer:_doubleTapGesture3];
        //[cell.artImageView3 addGestureRecognizer:_rotationGesture3];
        originalFrame3 = cell.artImageView3.frame;
    }
    
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
    animator.orientation = self.interfaceOrientation;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    WFSlideMetadataAnimator *animator = [WFSlideMetadataAnimator new];
    animator.orientation = self.interfaceOrientation;
    return animator;
}

- (void)dismiss {
    if (!iOS8){
        [self.presentingViewController.view setFrame:CGRectMake(-212, 0, height, width)];
    }
    if ([self.presentingViewController isKindOfClass:[WFArtMetadataViewController class]]){
        WFArtMetadataViewController *vc = (WFArtMetadataViewController*)self.presentingViewController;
        if (!iOS8){
            [vc.tableView setFrame:CGRectMake(212, 0, kMetadataWidth, height)];
        }
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
