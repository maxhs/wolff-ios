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
#import "WFInteractiveImageView.h"
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
    Slide *currentSlide;
    
    //slideshow ivars
    WFInteractiveImageView *artImageView1;
    WFInteractiveImageView *artImageView2;
    WFInteractiveImageView *artImageView3;
    UIView *containerView1;
    UIView *containerView2;
    UIView *containerView3;
    UIPanGestureRecognizer *_panGesture;
    UIPinchGestureRecognizer *_pinchGesture;
    UITapGestureRecognizer *_doubleTapGesture;
    UIScreenEdgePanGestureRecognizer *rightScreenEdgePanGesture;
    UIScreenEdgePanGestureRecognizer *leftScreenEdgePanGesture;
    CGFloat lastScale;
    CGPoint lastPoint;
    NSTimer *titleTimer;
    
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
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
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
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGesture.delegate = self;
    [self.view addGestureRecognizer:_panGesture];
    
    _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    _pinchGesture.delegate = self;
    [self.view addGestureRecognizer:_pinchGesture];
    
    rightScreenEdgePanGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(screenEdgePan:)];
    rightScreenEdgePanGesture.edges = UIRectEdgeRight;
    [self.view addGestureRecognizer:rightScreenEdgePanGesture];
    leftScreenEdgePanGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(screenEdgePan:)];
    leftScreenEdgePanGesture.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:leftScreenEdgePanGesture];
    
    _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    _doubleTapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:_doubleTapGesture];
    
    singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    singleTap.delegate = self;
    singleTap.numberOfTapsRequired = 1;
    [_collectionView addGestureRecognizer:singleTap];
    
    // require to fail methods
    [singleTap requireGestureRecognizerToFail:_doubleTapGesture];
    [_panGesture requireGestureRecognizerToFail:rightScreenEdgePanGesture];
    [_panGesture requireGestureRecognizerToFail:leftScreenEdgePanGesture];
    
    [_slideshowTitleButtonItem setTitle:_slideshow.title];
    currentPage = _startIndex;
    if (_startIndex == 0){
        [_previousButton setEnabled:NO];
        [_slideNumberButtonItem setTitle:@""];
    } else {
        [_collectionView setContentOffset:CGPointMake(width*(_startIndex+1), 0) animated:NO]; // offset by 1 because of the title slide
        [_slideNumberButtonItem setTitle:[NSString stringWithFormat:@"Slide %ld",(long)currentPage]];
    }
    
    [_slideNumberButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0],NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [_slideshowTitleButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0],NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
}

- (void)setUpNavBar {
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    fullScreenButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(goFullScreen)];
    metadataButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"info"] style:UIBarButtonItemStylePlain target:self action:@selector(showMetadata)];
    if (currentPage > 1){
        self.navigationItem.rightBarButtonItems = @[metadataButton];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    topInset = _collectionView.contentInset.top;
    [navBarShadowView setHidden:YES];
    [toolBarShadowView setHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    titleTimer = [[NSTimer alloc] init];
    titleTimer = [NSTimer scheduledTimerWithTimeInterval:0.7f target:self selector:@selector(hideBars) userInfo:nil repeats:NO];
}

- (void)showMetadata {
    if (currentPage > 0){
        WFSlideMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideMetadata"];
        [vc setSlide:currentSlide];
        [vc setSlideshow:_slideshow];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    }
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
    NSInteger page = lround(fractionalPage);
    if (currentPage != page) {
        currentPage = page;
        if (currentPage > 0){
            [_slideNumberButtonItem setTitle:[NSString stringWithFormat:@"Slide %ld",(long)currentPage]];
            currentSlide = _slideshow.slides[currentPage-1]; // offset by 1 because the index starts at 0, not 1
            self.navigationItem.rightBarButtonItem = metadataButton;
            currentPage == _slideshow.slides.count ? [_nextButton setEnabled:NO] : [_nextButton setEnabled:YES];
            [_previousButton setEnabled:YES];
        } else {
            // we're on the title slide
            [_slideNumberButtonItem setTitle:@""];
            self.navigationItem.rightBarButtonItem = nil;
            [_previousButton setEnabled:NO];
            currentSlide = nil;
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    currentPage = page;
    if (currentPage > 0){
        // ensure the ivars are set to the ACTIVE cell AND slide
        currentSlide = _slideshow.slides[currentPage-1]; // offset by 1 because the index starts at 0, not 1
        WFSlideshowSlideCell *cell = (WFSlideshowSlideCell*)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentPage-1 inSection:1]];
        containerView1 = cell.containerView1;
        containerView2 = cell.containerView2;
        containerView3 = cell.containerView3;
        artImageView1 = cell.artImageView1;
        artImageView2 = cell.artImageView2;
        artImageView3 = cell.artImageView3;
    } else {
        currentSlide = nil;
    }
}

- (IBAction)nextSlide:(id)sender {
    CGPoint contentOffset = _collectionView.contentOffset;
    contentOffset.x += width;
    if (currentPage <= _slideshow.slides.count){
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
       
        if (!artImageView1){
            artImageView1 = cell.artImageView1;
            containerView1 = cell.containerView1;
            artImageView2 = cell.artImageView2;
            containerView2 = cell.containerView2;
            artImageView3 = cell.artImageView3;
            containerView3 = cell.containerView3;
        }
        return cell;
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
        [self hideBars];
    } else {
        [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.navigationController.navigationBar.transform = CGAffineTransformIdentity;
            self.bottomToolbar.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            barsVisible = YES;
        }];
    }
}

- (void)hideBars {
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.navigationController.navigationBar.transform = CGAffineTransformMakeTranslation(0, -self.navigationController.navigationBar.frame.size.height);
        self.bottomToolbar.transform = CGAffineTransformMakeTranslation(0, self.bottomToolbar.frame.size.height);
    } completion:^(BOOL finished) {
        barsVisible = NO;
        if (titleTimer){
            [titleTimer invalidate];
            titleTimer = nil;
        }
    }];
}

- (void)handlePan:(UIPanGestureRecognizer*)gestureRecognizer {
    CGPoint fullTranslation = [gestureRecognizer locationInView:self.view];
    CGPoint translation = [gestureRecognizer translationInView:_collectionView];
    NSIndexPath *indexPathForGesture = [_collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:_collectionView]];
    UIView *view = nil; WFSlideshowSlideCell *cell;
    if (indexPathForGesture && indexPathForGesture.section > 0){
        cell = (WFSlideshowSlideCell*)[_collectionView cellForItemAtIndexPath:indexPathForGesture];
        if (cell.slide.photos.count == 1){
            view = cell.artImageView1;
        } else if (cell.slide.photos.count > 1){
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
    if (cell){
        if (view == cell.artImageView1){
            [currentSlide setRectString1:NSStringFromCGRect(cell.artImageView1.frame)];
        } else if (view == cell.artImageView2){
            [currentSlide setRectString2:NSStringFromCGRect(cell.artImageView2.frame)];
        } else if (view == cell.artImageView3){
            [currentSlide setRectString3:NSStringFromCGRect(cell.artImageView3.frame)];
        }
    }
}

- (void)screenEdgePan:(UIScreenEdgePanGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        //NSLog(@"done panning from right");
    }
}

//- (void)handleRotation:(UIRotationGestureRecognizer*)gestureRecognizer {
//    [self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
//    
//    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged) {
//        [gestureRecognizer view].transform = CGAffineTransformRotate([[gestureRecognizer view] transform], [gestureRecognizer rotation]);
//        [gestureRecognizer setRotation:0];
//    }
//}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer forView:(UIView*)piece {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
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
    if (indexPathForGesture && indexPathForGesture.section > 0){
        cell = (WFSlideshowSlideCell*)[_collectionView cellForItemAtIndexPath:indexPathForGesture];
        if (cell.slide.photos.count == 1){
            view = cell.artImageView1;
        } else if (cell.slide.photos.count > 1){
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
            [currentSlide setRectString1:NSStringFromCGRect(cell.artImageView1.frame)];
            [cell.artImageView1 setMoved:YES];
        } else if (view == cell.artImageView2){
            [currentSlide setRectString2:NSStringFromCGRect(cell.artImageView2.frame)];
            [cell.artImageView2 setMoved:YES];
        } else if (view == cell.artImageView3){
            [currentSlide setRectString3:NSStringFromCGRect(cell.artImageView3.frame)];
            [cell.artImageView3 setMoved:YES];
        }
    }
}

- (void)doubleTap:(UITapGestureRecognizer*)gestureRecognizer {
    CGPoint absolutePoint = [gestureRecognizer locationInView:self.view];
    //NSLog(@"absolute point double tapped: %f, %f",absolutePoint.x, absolutePoint.y);
    NSIndexPath *indexPathForGesture = [_collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:_collectionView]];
    UIView *view = nil;
    
    if (indexPathForGesture && indexPathForGesture.section > 0){
        WFSlideshowSlideCell *cell = (WFSlideshowSlideCell*)[_collectionView cellForItemAtIndexPath:indexPathForGesture];
        CGPoint tappedPoint = [gestureRecognizer locationInView:self.view];
        if (cell.slide.photos.count == 1){
            view = cell.artImageView1;
        } else {
            view = tappedPoint.x < width/2 ? cell.artImageView2 : cell.artImageView3;
        }
    }
    
    if (view){
        [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            if (view == artImageView1){
                if (artImageView1.moved){
                    view.transform = CGAffineTransformIdentity;
                    [artImageView1 setFrame:kOriginalArtImageFrame1];
                    [currentSlide setRectString1:@""];
                    [artImageView1 setMoved:NO];
                } else {
                    view.transform = CGAffineTransformMakeScale(3.f, 3.f);
                    CGPoint absoluteCenterPoint;
                    absoluteCenterPoint.x = width - absolutePoint.x;
                    absoluteCenterPoint.y = height - absolutePoint.y;
                    view.center = absoluteCenterPoint;
                    [artImageView1 setMoved:YES];
                }
            } else if (view == artImageView2){
                if (artImageView2.moved){
                    view.transform = CGAffineTransformIdentity;
                    [artImageView2 setFrame:kOriginalArtImageFrame2];
                    [currentSlide setRectString2:@""];
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
                    [artImageView3 setFrame:kOriginalArtImageFrame3];
                    [currentSlide setRectString3:@""];
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

#pragma mark - Gesture Recognizer Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
