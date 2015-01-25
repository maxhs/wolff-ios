//
//  WFSlideshowViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideshowViewController.h"
#import "WFSlideshowSlideCell.h"
#import "WFAppDelegate.h"
#import "WFSlideMetadataViewController.h"
#import "WFSlideMetadataAnimator.h"
#import "WFUtilities.h"
#import "WFSlideshowTitleCell.h"

@interface WFSlideshowViewController () <UIToolbarDelegate, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate> {
    CGFloat width;
    CGFloat height;
    BOOL iOS8;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *fullScreenButton;
    UIBarButtonItem *metadataButton;
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat topInset;
    UITapGestureRecognizer *singleTap;
    BOOL barsVisible;
    BOOL originalsAreSet;
    Slide *currentSlide;
    
    //slideshow ivars
    UIImageView *artImageView1;
    UIImageView *artImageView2;
    UIImageView *artImageView3;
    UIView *containerView1;
    UIView *containerView2;
    UIView *containerView3;
    UIPanGestureRecognizer *_panGesture1;
    UIPanGestureRecognizer *_panGesture2;
    UIPanGestureRecognizer *_panGesture3;
    /*UIRotationGestureRecognizer *_rotateGesture1;
    UIRotationGestureRecognizer *_rotateGesture2;
    UIRotationGestureRecognizer *_rotateGesture3;*/
    UIPinchGestureRecognizer *_pinchGesture1;
    UIPinchGestureRecognizer *_pinchGesture2;
    UIPinchGestureRecognizer *_pinchGesture3;
    UITapGestureRecognizer *_doubleTapGesture1;
    UITapGestureRecognizer *_doubleTapGesture2;
    UITapGestureRecognizer *_doubleTapGesture3;
    UIScreenEdgePanGestureRecognizer *rightScreenEdgePanGesture;
    UIScreenEdgePanGestureRecognizer *leftScreenEdgePanGesture;
    CGFloat lastScale;
    CGRect originalFrame1;
    CGRect originalFrame2;
    CGRect originalFrame3;
    CGPoint lastPoint;
    
    NSInteger currentPage;
    UIImageView *navBarShadowView;
    UIImageView *toolBarShadowView;
}
@property (weak, nonatomic) IBOutlet UIBarButtonItem *slideshowTitleButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *slideNumberButtonItem;
@end

@implementation WFSlideshowViewController

@synthesize slideshow = _slideshow;
@synthesize startIndex = _startIndex;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        iOS8 = YES;
        width = screenWidth();
        height = screenHeight();
    } else {
        iOS8 = NO;
        width = screenHeight();
        height = screenWidth();
    }
    
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [_bottomToolbar setTintColor:[UIColor whiteColor]];
    [self setUpNavBar];

    barsVisible = YES;
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    toolBarShadowView = [WFUtilities findNavShadow:self.bottomToolbar];
    [_bottomToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [_bottomToolbar setTranslucent:YES];
    
    [_collectionView setDelaysContentTouches:NO];
    [_collectionView setCanCancelContentTouches:NO];
    
    _panGesture1 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGesture1.delegate = self;
    _panGesture2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGesture2.delegate = self;
    _panGesture3 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGesture3.delegate = self;
    
    _pinchGesture1 = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    _pinchGesture1.delegate = self;
    _pinchGesture2 = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    _pinchGesture2.delegate = self;
    _pinchGesture3 = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    _pinchGesture3.delegate = self;
    
    rightScreenEdgePanGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(screenEdgePan:)];
    rightScreenEdgePanGesture.edges = UIRectEdgeRight;
    [self.view addGestureRecognizer:rightScreenEdgePanGesture];
    leftScreenEdgePanGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(screenEdgePan:)];
    leftScreenEdgePanGesture.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:leftScreenEdgePanGesture];
    
//    [_panGesture1 requireGestureRecognizerToFail:_collectionView.panGestureRecognizer];
//    [_panGesture1 requireGestureRecognizerToFail:_collectionView.panGestureRecognizer];
//    [_panGesture1 requireGestureRecognizerToFail:_collectionView.panGestureRecognizer];
    
    /*_rotateGesture1 = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    _rotateGesture2 = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    _rotateGesture3 = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];*/
    
    _doubleTapGesture1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _doubleTapGesture1.numberOfTapsRequired = 2;
    _doubleTapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _doubleTapGesture2.numberOfTapsRequired = 2;
    _doubleTapGesture3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _doubleTapGesture3.numberOfTapsRequired = 2;
    
    singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    singleTap.delegate = self;
    singleTap.numberOfTapsRequired = 1;
    [_collectionView addGestureRecognizer:singleTap];
    [singleTap requireGestureRecognizerToFail:_doubleTapGesture1];
    [singleTap requireGestureRecognizerToFail:_doubleTapGesture2];
    [singleTap requireGestureRecognizerToFail:_doubleTapGesture3];
    
    [_slideshowTitleButtonItem setTitle:_slideshow.title];
    currentPage = 1+_startIndex;
    [_collectionView setContentOffset:CGPointMake(width*_startIndex, 0) animated:NO];
    
    [_slideNumberButtonItem setTitle:[NSString stringWithFormat:@"Slide %ld",(long)currentPage]];
    [_slideNumberButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0],NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [_slideshowTitleButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0],NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
}

- (void)setUpNavBar {
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    fullScreenButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(goFullScreen)];
    metadataButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info"] style:UIBarButtonItemStylePlain target:self action:@selector(showMetadata)];
    self.navigationItem.rightBarButtonItems = @[metadataButton/*, fullScreenButton*/];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    topInset = _collectionView.contentInset.top;
    [navBarShadowView setHidden:YES];
    [toolBarShadowView setHidden:YES];
}

- (void)showMetadata {
    WFSlideMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideMetadata"];
    [vc setSlide:currentSlide];
    [vc setSlideshow:_slideshow];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)goFullScreen {
    NSLog(@"Should be going full screen");
}

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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage)+1; // offset since we're starting on page 1
    if (currentPage != page) {
        currentPage = page;
        [_slideNumberButtonItem setTitle:[NSString stringWithFormat:@"Slide %ld",(long)currentPage]];
        currentSlide = _slideshow.slides[currentPage-2]; // offset by 2 because the index starts at 0, not 1, and there's always a title slide
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section == 0) return 1;
    else return _slideshow.slides.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        WFSlideshowTitleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TitleCell" forIndexPath:indexPath];
        [cell configureForSlideshow:_slideshow];
        return cell;
    } else {
        WFSlideshowSlideCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SlideCell" forIndexPath:indexPath];
        currentSlide = _slideshow.slides[indexPath.item];
        [cell configureForPhotos:currentSlide.photos.mutableCopy inSlide:currentSlide];
       
        // set/reset gesture recognizers
        if (currentSlide.photos.count == 1){
            artImageView1 = cell.artImageView1;
            containerView1 = cell.containerView1;
            [artImageView1 addGestureRecognizer:_panGesture1];
            [artImageView1 addGestureRecognizer:_pinchGesture1];
            [artImageView1 addGestureRecognizer:_doubleTapGesture1];
            
        } else {
            artImageView2 = cell.artImageView2;
            containerView2 = cell.containerView2;
            [artImageView2 addGestureRecognizer:_panGesture2];
            [artImageView2 addGestureRecognizer:_pinchGesture2];
            [artImageView2 addGestureRecognizer:_doubleTapGesture2];
            
            artImageView3 = cell.artImageView3;
            containerView3 = cell.containerView3;
            [artImageView3 addGestureRecognizer:_panGesture3];
            [artImageView3 addGestureRecognizer:_pinchGesture3];
            [artImageView3 addGestureRecognizer:_doubleTapGesture3];
        }
        
        if (!originalsAreSet){
            originalFrame1 = cell.artImageView1.frame;
            originalFrame2 = cell.artImageView2.frame;
            originalFrame3 = cell.artImageView3.frame;
            originalsAreSet = YES;
        }
        
    //    [_collectionView.panGestureRecognizer requireGestureRecognizerToFail:_panGesture1];
    //    [_collectionView.panGestureRecognizer requireGestureRecognizerToFail:_panGesture2];
    //    [_collectionView.panGestureRecognizer requireGestureRecognizerToFail:_panGesture3];
    //    
    //    [_collectionView.panGestureRecognizer requireGestureRecognizerToFail:_pinchGesture1];
    //    [_collectionView.panGestureRecognizer requireGestureRecognizerToFail:_pinchGesture2];
    //    [_collectionView.panGestureRecognizer requireGestureRecognizerToFail:_pinchGesture3];
        
        return cell;
    }
}

- (IBAction)nextSlide:(id)sender {
    CGPoint contentOffset = _collectionView.contentOffset;
    contentOffset.x += width;
    if (currentPage < _slideshow.slides.count){
        [_collectionView setContentOffset:contentOffset animated:YES];
    }
}

- (IBAction)previousSlide:(id)sender {
    CGPoint contentOffset = _collectionView.contentOffset;
    contentOffset.x -= width;
    if (contentOffset.x >= 0.f){
        [_collectionView setContentOffset:contentOffset animated:YES];
    }
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.frame.size.width,collectionView.frame.size.height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

#pragma mark - Handle Gestures
- (void)singleTap:(UIGestureRecognizer*)gestureRecognizer {
    if (barsVisible){
        [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.navigationController.navigationBar.transform = CGAffineTransformMakeTranslation(0, -self.navigationController.navigationBar.frame.size.height);
            self.bottomToolbar.transform = CGAffineTransformMakeTranslation(0, self.bottomToolbar.frame.size.height);
        } completion:^(BOOL finished) {
            barsVisible = NO;
        }];
    } else {
        [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.navigationController.navigationBar.transform = CGAffineTransformIdentity;
            self.bottomToolbar.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            barsVisible = YES;
        }];
    }
}

- (void)handlePan:(UIPanGestureRecognizer*)gestureRecognizer {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    CGPoint newPoint = CGPointMake(gestureRecognizer.view.center.x + translation.x, gestureRecognizer.view.center.y + translation.y);
    if (newPoint.x > 0){
        gestureRecognizer.view.center = newPoint;
    }
    [gestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}

- (void)screenEdgePan:(UIScreenEdgePanGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        //NSLog(@"done panning from right");
    }
}

- (void)handleRotation:(UIRotationGestureRecognizer*)gestureRecognizer {
    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
        [gestureRecognizer view].transform = CGAffineTransformRotate([[gestureRecognizer view] transform], [gestureRecognizer rotation]);
        [gestureRecognizer setRotation:0];
    }
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

- (void)handleTap:(UITapGestureRecognizer*)sender {
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.77 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        sender.view.transform = CGAffineTransformIdentity;
        if (sender == _doubleTapGesture1){
            [sender.view setFrame:originalFrame1];
        } else if (sender == _doubleTapGesture2){
            [sender.view setFrame:originalFrame2];
        } else {
            [sender.view setFrame:originalFrame3];
        }
        
    } completion:^(BOOL finished) {
        
    }];
}

//- (void)reset {
//    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.7 initialSpringVelocity:.01 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        artImageView1.transform = CGAffineTransformIdentity;
//        artImageView2.transform = CGAffineTransformIdentity;
//        artImageView3.transform = CGAffineTransformIdentity;
//        [artImageView1 setFrame:originalFrame1];
//        [artImageView2 setFrame:originalFrame2];
//        [artImageView3 setFrame:originalFrame3];
//    } completion:^(BOOL finished) {
//        
//    }];
//}

#pragma mark - Gesture Recognizer Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    //NSLog(@"simultaneously recognize");
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
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
