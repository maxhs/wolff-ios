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
#import "WFInteractiveImageView.h"

@interface WFComparisonViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, UIViewControllerTransitioningDelegate> {
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *metadataButton;
    WFInteractiveImageView *artImageView1;
    WFInteractiveImageView *artImageView2;
    WFInteractiveImageView *artImageView3;
    UIView *containerView1;
    UIView *containerView2;
    UIView *containerView3;
    UIPanGestureRecognizer *_panGesture;
    UIRotationGestureRecognizer *_rotationGesture;
    UIPinchGestureRecognizer *_pinchGesture;
    UITapGestureRecognizer *_singleTapGesture;
    UITapGestureRecognizer *_doubleTapGesture;
    
    CGFloat lastScale;
    CGPoint lastPoint;
    
    CGFloat width;
    CGFloat height;
    BOOL iOS8;
    BOOL barsVisible;
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
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
    }
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:_panGesture];
    _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [self.view addGestureRecognizer:_pinchGesture];
    _rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    [self.view addGestureRecognizer:_rotationGesture];
    _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    _singleTapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:_singleTapGesture];
    _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    _doubleTapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:_doubleTapGesture];
    
    // require to fail methods
    [_singleTapGesture requireGestureRecognizerToFail:_doubleTapGesture];
    //[_rotationGesture requireGestureRecognizerToFail:_panGesture];
    //[_rotationGesture requireGestureRecognizerToFail:_pinchGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
    [navBarShadowView setHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
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
    CGPoint fullTranslation = [gestureRecognizer locationInView:self.view];
    CGPoint translation = [gestureRecognizer translationInView:_collectionView];
    NSIndexPath *indexPathForGesture = [_collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:_collectionView]];
    UIView *view = nil; WFSlideshowSlideCell *cell;
    if (indexPathForGesture){
        cell = (WFSlideshowSlideCell*)[_collectionView cellForItemAtIndexPath:indexPathForGesture];
        if (cell.photos.count == 1){
            view = cell.artImageView1;
        } else if (cell.photos.count > 1){
            if (fullTranslation.x < width/2){
                view = cell.artImageView2;
            } else {
                view = cell.artImageView3;
            }
        }
    }
    
    CGPoint newPoint = CGPointMake(view.center.x + translation.x, view.center.y + translation.y);
    view.center = newPoint;
    [gestureRecognizer setTranslation:CGPointMake(0, 0) inView:_collectionView];
    
    //offset and/or save pre-position
    [(WFInteractiveImageView*)view setMoved:YES];
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer forView:(UIView*)piece {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

- (void)handleRotation:(UIRotationGestureRecognizer*)gestureRecognizer {
    CGPoint gesturePoint = [gestureRecognizer locationInView:_collectionView];
    CGPoint pointInView = [gestureRecognizer locationInView:self.view];
    NSIndexPath *indexPathForGesture = [_collectionView indexPathForItemAtPoint:gesturePoint];
    
    UIView *view = nil; WFSlideshowSlideCell *cell;
    if (indexPathForGesture){
        cell = (WFSlideshowSlideCell*)[_collectionView cellForItemAtIndexPath:indexPathForGesture];
        if (cell.photos.count == 1){
            view = cell.artImageView1;
        } else if (cell.photos.count > 1){
            view = pointInView.x < width/2 ? cell.artImageView2 : cell.artImageView3;
        }
    }
    //[self adjustAnchorPointForGestureRecognizer:gestureRecognizer forView:view];
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        view.transform = CGAffineTransformRotate(view.transform, [gestureRecognizer rotation]);
        [gestureRecognizer setRotation:0];
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        lastScale = gestureRecognizer.scale;
        [_collectionView setScrollEnabled:NO];
    }
    
    CGPoint pointInView = [gestureRecognizer locationInView:self.view];
    CGPoint gesturePoint = [gestureRecognizer locationInView:_collectionView];
    NSIndexPath *indexPathForGesture = [_collectionView indexPathForItemAtPoint:gesturePoint];
    
    UIView *view = nil; WFSlideshowSlideCell *cell;
    if (indexPathForGesture){
        cell = (WFSlideshowSlideCell*)[_collectionView cellForItemAtIndexPath:indexPathForGesture];
        if (cell.photos.count == 1){
            view = cell.artImageView1;
        } else if (cell.photos.count > 1){
            view = pointInView.x < width/2 ? cell.artImageView2 : cell.artImageView3;
        }
        
        //offset
        [(WFInteractiveImageView*)view setMoved:YES];
        [self adjustAnchorPointForGestureRecognizer:gestureRecognizer forView:view];
        
        const CGFloat kMaxScale = CGFLOAT_MAX;
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan || gestureRecognizer.state == UIGestureRecognizerStateChanged) {
            CGFloat currentScale = [[view.layer valueForKeyPath:@"transform.scale"] floatValue];
            const CGFloat kMinScale = .5;
            CGFloat newScale = 1 -  (lastScale - gestureRecognizer.scale);
            newScale = MIN(newScale, kMaxScale / currentScale);
            newScale = MAX(newScale, kMinScale / currentScale);
            CGAffineTransform transform = CGAffineTransformScale(view.transform, newScale, newScale);
            view.transform = transform;
        }
        lastScale = gestureRecognizer.scale;  // Store the previous scale factor for the next pinch gesture call
        
        if (gestureRecognizer.state == UIGestureRecognizerStateEnded && lastScale < 1.f) {
            CGFloat currentScale = [[view.layer valueForKeyPath:@"transform.scale"] floatValue];
            const CGFloat kMinScale = 1.0;
            CGFloat newScale = 1 -  (lastScale - gestureRecognizer.scale);
            newScale = MIN(newScale, kMaxScale / currentScale);
            newScale = MAX(newScale, kMinScale / currentScale);
            CGAffineTransform transform = CGAffineTransformScale(view.transform, newScale, newScale);
            
            [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                view.transform = transform;
            } completion:^(BOOL finished) {
                lastScale = gestureRecognizer.scale;  // Store the previous scale factor for the next pinch gesture call
            }];
        }
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        [_collectionView setScrollEnabled:YES];
    }
    if (cell){
        if (view == cell.artImageView1){
            [cell.artImageView1 setMoved:YES];
        } else if (view == cell.artImageView2){
            [cell.artImageView2 setMoved:YES];
        } else if (view == cell.artImageView3){
            [cell.artImageView3 setMoved:YES];
        }
    }
}

- (void)singleTap:(UIGestureRecognizer*)gestureRecognizer {
    if (barsVisible){
        [self hideBars];
    } else {
        [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.navigationController.navigationBar.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            barsVisible = YES;
        }];
    }
}

- (void)hideBars {
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.navigationController.navigationBar.transform = CGAffineTransformMakeTranslation(0, -self.navigationController.navigationBar.frame.size.height);
    } completion:^(BOOL finished) {
        barsVisible = NO;
    }];
}

- (void)doubleTap:(UITapGestureRecognizer*)gestureRecognizer {
    CGPoint absolutePoint = [gestureRecognizer locationInView:self.view];
    NSIndexPath *indexPathForGesture = [_collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:_collectionView]];
    UIView *view = nil;
    WFSlideshowSlideCell *cell;
    
    if (indexPathForGesture){
        cell = (WFSlideshowSlideCell*)[_collectionView cellForItemAtIndexPath:indexPathForGesture];
        CGPoint tappedPoint = [gestureRecognizer locationInView:self.view];
        if (cell.photos.count == 1){
            view = cell.artImageView1;
        } else {
            view = tappedPoint.x < width/2 ? cell.artImageView2 : cell.artImageView3;
        }
    }
    
    if (view && cell){
        [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.77 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            if (view == artImageView1){
                if (artImageView1.moved){
                    view.transform = CGAffineTransformIdentity;
                    [cell recenterView:artImageView1];
                    [artImageView1 setMoved:NO];
                } else {
                    CGPoint absoluteCenterPoint;
                    absoluteCenterPoint.x = width - absolutePoint.x;
                    absoluteCenterPoint.y = height - absolutePoint.y;
                    view.center = absoluteCenterPoint;
                    view.transform = CGAffineTransformMakeScale(3.f, 3.f);
                    [artImageView1 setMoved:YES];
                }
            } else if (view == artImageView2){
                if (artImageView2.moved){
                    view.transform = CGAffineTransformIdentity;
                    [cell recenterView:artImageView2];
                    [artImageView2 setMoved:NO];
                } else {
                    CGPoint absolutePoint2 = [gestureRecognizer locationInView:containerView2];
                    absolutePoint2.x = containerView2.frame.size.width - absolutePoint2.x;
                    absolutePoint2.y = containerView2.frame.size.height - absolutePoint2.y;
                    view.center = absolutePoint2;
                    view.transform = CGAffineTransformMakeScale(3.f, 3.f);
                    [artImageView2 setMoved:YES];
                }
            } else if (view == artImageView3){
                if (artImageView3.moved){
                    view.transform = CGAffineTransformIdentity;
                    [cell recenterView:artImageView3];
                    [artImageView3 setMoved:NO];
                } else {
                    view.transform = CGAffineTransformMakeScale(3.f, 3.f);
                    CGPoint absolutePoint3 = [gestureRecognizer locationInView:containerView3];
                    absolutePoint3.x = containerView3.frame.size.width - absolutePoint3.x;
                    absolutePoint3.y = containerView3.frame.size.height - absolutePoint3.y;
                    view.center = absolutePoint3;
                    [artImageView3 setMoved:YES];
                }
            }
        } completion:^(BOOL finished) {
            
        }];
    }
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
    
    artImageView1 = cell.artImageView1;
    containerView1 = cell.containerView1;
    artImageView2 = cell.artImageView2;
    containerView2 = cell.containerView2;
    artImageView3 = cell.artImageView3;
    containerView3 = cell.containerView3;
    
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
