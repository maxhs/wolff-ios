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
#import "PhotoSlide+helper.h"
#import "WFSlideMetadataCollectionCell.h"

@interface WFSlideshowViewController () <UIToolbarDelegate, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate> {
    CGFloat width;
    CGFloat height;
    BOOL iOS8;
    UIBarButtonItem *dismissButton;
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat topInset;
    UITapGestureRecognizer *singleTap;
    BOOL barsVisible;
    BOOL metadataExpanded;
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
    UIScreenEdgePanGestureRecognizer *bottomEdgePanGesture;
    CGFloat lastScale;
    CGPoint lastPoint;
    NSTimer *titleTimer;
    
    NSInteger currentPage;
    UIImageView *navBarShadowView;
    UIImageView *toolBarShadowView;
    UIBarButtonItem *slideshowTitleButtonItem;
    UIBarButtonItem *nextButton;
    UIBarButtonItem *previousButton;
    UIBarButtonItem *slideNumberButtonItem;
    UIButton *metadataButton;
    
    CGRect kOriginalArtImageFrame1;
    CGRect kOriginalArtImageFrame2;
    CGRect kOriginalArtImageFrame3;
}

@end

@implementation WFSlideshowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    if (SYSTEM_VERSION >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
    }
    
    //calculate the "home position" geometry for slides at runtime
    CGFloat frameheight = (IDIOM == IPAD) ? 660.f : 300.f;
    CGFloat singleWidth = (IDIOM == IPAD) ? 900.f : 460.f;
    CGFloat splitWidth = (IDIOM == IPAD) ? 480.f : 260.f;
    kOriginalArtImageFrame1 = CGRectMake((width/2-singleWidth/2), (height/2-frameheight/2), singleWidth, frameheight);
    kOriginalArtImageFrame2 = CGRectMake((width/4-splitWidth/2), (height/2-frameheight/2), splitWidth, frameheight);
    kOriginalArtImageFrame3 = CGRectMake((width/4-splitWidth/2), (height/2-frameheight/2), splitWidth, frameheight);
    
    [self setUpNavBar];

    barsVisible = YES;
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    
    [self.collectionView setDelaysContentTouches:NO];
    [self.collectionView setCanCancelContentTouches:YES];
    if ([self.slideshow.showMetadata isEqualToNumber:@NO]){
        CGRect metadataCollectionFrame = self.metadataCollectionView.frame;
        metadataCollectionFrame.origin.y = height;
        [self.metadataCollectionView setFrame:metadataCollectionFrame];
    }
    
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
    bottomEdgePanGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(screenEdgePan:)];
    bottomEdgePanGesture.edges = UIRectEdgeBottom;
    [self.view addGestureRecognizer:bottomEdgePanGesture];
    
    _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    _doubleTapGesture.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:_doubleTapGesture];
    
    singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    singleTap.delegate = self;
    singleTap.numberOfTapsRequired = 1;
    [self.collectionView addGestureRecognizer:singleTap];
    
    // require to fail methods
    [singleTap requireGestureRecognizerToFail:_doubleTapGesture];
    [_panGesture requireGestureRecognizerToFail:rightScreenEdgePanGesture];
    [_panGesture requireGestureRecognizerToFail:leftScreenEdgePanGesture];
    
    [self setupMetadataContainer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    topInset = self.collectionView.contentInset.top;
    [navBarShadowView setHidden:YES];
    [toolBarShadowView setHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    if (IDIOM != IPAD) {
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
    if ([self.slideshow.showMetadata isEqualToNumber:@YES]){
        [self.metadataCollectionView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    titleTimer = [[NSTimer alloc] init];
    titleTimer = [NSTimer scheduledTimerWithTimeInterval:1.7f target:self selector:@selector(hideBars) userInfo:nil repeats:NO];
}

- (void)setupMetadataContainer {
    CGFloat y = [self.slideshow.showMetadata isEqualToNumber:@YES] ? height-self.navigationController.navigationBar.frame.size.height : height;
    [self.slideMetadataContainerView setFrame:CGRectMake(0, y, width, height)];
    
    UIToolbar *toolbarBackground = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [toolbarBackground setBarStyle:UIBarStyleBlackTranslucent];
    [toolbarBackground setTranslucent:YES];
    toolbarBackground.clipsToBounds = YES; // hide the thin border line on the UIToolbar
    [self.slideMetadataContainerView addSubview:toolbarBackground];
    [self.slideMetadataContainerView sendSubviewToBack:toolbarBackground];
    
    metadataButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [metadataButton setImage:[UIImage imageNamed:@"info"] forState:UIControlStateNormal];
    [metadataButton addTarget:self action:@selector(showMetadata) forControlEvents:UIControlEventTouchUpInside];
    [self.slideMetadataContainerView addSubview:metadataButton];
    [metadataButton setFrame:CGRectMake(width-44, 0, 44, 44)];
    
    [self.metadataCollectionView setBackgroundColor:[UIColor clearColor]];
    metadataExpanded = NO;
}

- (void)setUpNavBar {
    previousButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"leftArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(previousSlide:)];
    nextButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"rightArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(nextSlide:)];
    slideNumberButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    slideshowTitleButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.slideshow.title style:UIBarButtonItemStylePlain target:self action:nil];
    
    if (!_startIndex){
        [previousButton setEnabled:NO];
        if ([self.slideshow.showTitleSlide isEqualToNumber:@YES]){
            currentPage = 0;
            [slideNumberButtonItem setTitle:@""];
        } else {
            currentPage = 1;
            [slideNumberButtonItem setTitle:[NSString stringWithFormat:@"%ld of %lu",(long)currentPage,(unsigned long)self.slideshow.slides.count]];
        }
    } else if (_startIndex == 0){
        [self.collectionView setContentOffset:CGPointMake(width, 0) animated:NO]; // offset by 1 because of the title slide
        [slideNumberButtonItem setTitle:[NSString stringWithFormat:@"%ld of %lu",(long)currentPage,(unsigned long)self.slideshow.slides.count]];
        currentPage = _startIndex.integerValue;
    } else {
        [self.collectionView setContentOffset:CGPointMake(width * (_startIndex.integerValue+1), 0) animated:NO]; // offset by 1 because of the title slide
        [slideNumberButtonItem setTitle:[NSString stringWithFormat:@"%ld of %lu",(long)currentPage,(unsigned long)self.slideshow.slides.count]];
        currentPage = _startIndex.integerValue;
    }
    
    [slideNumberButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSansSemibold] size:0],NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [slideshowTitleButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSans] size:0],NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItems = @[dismissButton, slideshowTitleButtonItem];
    self.navigationItem.rightBarButtonItems = @[nextButton, slideNumberButtonItem, previousButton];
}

- (void)showMetadata {
    CGRect metadataFrame = self.slideMetadataContainerView.frame;
    if (metadataExpanded){
        if ([self.slideshow.showMetadata isEqualToNumber:@YES]){
            metadataFrame.origin.y = height - 44.f;
        } else {
            metadataFrame.origin.y = height;
        }
    } else {
        metadataFrame.origin.y = height/2;
    }
    
    metadataExpanded = !metadataExpanded;
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.77 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.slideMetadataContainerView setFrame:metadataFrame];
    } completion:^(BOOL finished) {
        
    }];
}

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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    if (scrollView == self.collectionView){
        [self.metadataCollectionView setContentOffset:CGPointMake(scrollView.contentOffset.x, self.metadataCollectionView.contentOffset.y) animated:NO];
    }
    /*if (scrollView == self.metadataCollectionView){
        [self.collectionView setContentOffset:CGPointMake(scrollView.contentOffset.x, self.collectionView.contentOffset.y) animated:NO];
    }*/
    
    if ([self.slideshow.showTitleSlide isEqualToNumber:@NO]){
        page ++;
    }
    if (currentPage != page) {
        currentPage = page;
        if (currentPage > 0){
            [slideNumberButtonItem setTitle:[NSString stringWithFormat:@"%ld of %lu",(long)currentPage,(unsigned long)self.slideshow.slides.count]];
            currentSlide = self.slideshow.slides[currentPage-1]; // offset by 1 because the index starts at 0, not 1
            WFSlideshowSlideCell *cell = (WFSlideshowSlideCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentPage-1 inSection:1]];
            currentPage == self.slideshow.slides.count ? [nextButton setEnabled:NO] : [nextButton setEnabled:YES];
            [previousButton setEnabled:YES];
            [self.collectionView setCanCancelContentTouches:NO];
            [self assignViewsForCell:cell];
        } else {
            // we're on the title slide
            //[slideNumberButtonItem setTitle:@""];
            [previousButton setEnabled:NO];
            currentSlide = nil;
            [self.collectionView setCanCancelContentTouches:YES];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    if ([self.slideshow.showTitleSlide isEqualToNumber:@NO]){
        page ++; // if we're not showing a title side, we need to offset the slide numbers
    }
    currentPage = page;
    if (currentPage > 0){
        // ensure the ivars are set to the ACTIVE cell AND slide
        currentSlide = self.slideshow.slides[currentPage-1]; // offset by 1 because the index starts at 0, not 1
        WFSlideshowSlideCell *cell = (WFSlideshowSlideCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentPage-1 inSection:1]];
        [self assignViewsForCell:cell];
    } else {
        currentSlide = nil;
    }
}

- (void)assignViewsForCell:(WFSlideshowSlideCell*)cell {
    containerView1 = cell.containerView1;
    containerView2 = cell.containerView2;
    containerView3 = cell.containerView3;
    artImageView1 = cell.artImageView1;
    artImageView2 = cell.artImageView2;
    artImageView3 = cell.artImageView3;
}

- (void)nextSlide:(id)sender {
    CGPoint contentOffset = self.collectionView.contentOffset;
    contentOffset.x += width;
    if (currentPage <= self.slideshow.slides.count){
        [self.collectionView setContentOffset:contentOffset animated:YES];
        [self.metadataCollectionView setContentOffset:contentOffset animated:YES];
    }
}

- (void)previousSlide:(id)sender {
    CGPoint contentOffset = self.collectionView.contentOffset;
    contentOffset.x -= width;
    if (contentOffset.x >= 0.f){
        [self.collectionView setContentOffset:contentOffset animated:YES];
        [self.metadataCollectionView setContentOffset:contentOffset animated:YES];
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (collectionView == self.collectionView){
        return 2;
    } else {
        if ([self.slideshow.showMetadata isEqualToNumber:@YES]){
            return self.slideshow.slides.count + 1;
        } else {
            return self.slideshow.slides.count;
        }
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.collectionView){
        if (section == 0) {
            if ([self.slideshow.showTitleSlide isEqualToNumber:@YES]){
                return 1;
            } else {
                return 0;
            }
        } else return self.slideshow.slides.count;
    } else {
        if ([self.slideshow.showMetadata isEqualToNumber:@YES] && section == 0){
            return 1;
        } else {
            Slide *slide = self.slideshow.slides[[self.slideshow.showMetadata isEqualToNumber:@YES] ? section - 1 : section];
            return slide.photoSlides.count;
        }
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.collectionView){
        if (indexPath.section == 0){
            WFSlideshowTitleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TitleCell" forIndexPath:indexPath];
            [cell configureForSlideshow:self.slideshow];
            return cell;
        } else {
            WFSlideshowSlideCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SlideCell" forIndexPath:indexPath];
            currentSlide = self.slideshow.slides[indexPath.item];
            [cell configureForPhotos:currentSlide.photos.mutableCopy inSlide:currentSlide];
            
            // temporary
            [cell.artImageView1 setFrame:kOriginalArtImageFrame1];
            [cell.artImageView2 setFrame:kOriginalArtImageFrame2];
            [cell.artImageView3 setFrame:kOriginalArtImageFrame3];
            
            [self assignViewsForCell:cell];
            return cell;
        }
    } else {
        WFSlideMetadataCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SlideMetadataCell" forIndexPath:indexPath];
        
        if ([self.slideshow.showMetadata isEqualToNumber:@YES] && indexPath.section == 0){
            // title slide, so don't do anything
            [cell.titleLabel setAttributedText:[[NSAttributedString alloc] initWithString:@"" attributes:nil]];
        } else {
            if ([self.slideshow.showMetadata isEqualToNumber:@YES]){
                currentSlide = self.slideshow.slides[indexPath.section-1];
            } else {
                currentSlide = self.slideshow.slides[indexPath.section];
            }
            
            PhotoSlide *photoSlide = currentSlide.photoSlides[indexPath.item];
            [cell configureForPhotoSlide:photoSlide];
            
            CGRect titleLabelFrame = cell.titleLabel.frame;
            if (currentSlide.photoSlides.count == 1 || currentSlide.slideTexts.count == 1){
                titleLabelFrame.size.width = width-70;
            } else {
                titleLabelFrame.size.width = (width-70)/2;
            }
            CGSize titleSize = [cell.titleLabel sizeThatFits:CGSizeMake(titleLabelFrame.size.width, CGFLOAT_MAX)];
            titleLabelFrame.size.height = titleSize.height;
            [cell.titleLabel setFrame:titleLabelFrame];
        }
        return cell;
    }
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.collectionView){
        return CGSizeMake(collectionView.frame.size.width,collectionView.frame.size.height);
    } else {
        if ([self.slideshow.showMetadata isEqualToNumber:@YES] && indexPath.section == 0){
            return CGSizeMake(collectionView.frame.size.width,collectionView.frame.size.height);
        } else {
            Slide *slide = self.slideshow.slides[[self.slideshow.showMetadata isEqualToNumber:@YES] ? indexPath.section - 1 : indexPath.section];
            if (slide.photoSlides.count == 1 || slide.slideTexts.count == 1){
                return CGSizeMake(collectionView.frame.size.width,collectionView.frame.size.height);
            } else {
                return CGSizeMake(collectionView.frame.size.width/2,collectionView.frame.size.height);
            }
        }
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - Handle Gestures
- (void)singleTap:(UIGestureRecognizer*)gestureRecognizer {
    if (metadataExpanded){
        [self showMetadata];
    } else if (barsVisible){
        [self hideBars];
    } else {
        [self showBars];
    }
}

- (void)showBars {
    barsVisible = YES;
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.925 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.navigationController.navigationBar.transform = CGAffineTransformIdentity;
        self.slideMetadataContainerView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideBars {
    barsVisible = NO;
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.925 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.navigationController.navigationBar.transform = CGAffineTransformMakeTranslation(0, -self.navigationController.navigationBar.frame.size.height);
        self.slideMetadataContainerView.transform = CGAffineTransformMakeTranslation(0, self.navigationController.navigationBar.frame.size.height);
    } completion:^(BOOL finished) {
        if (titleTimer){
            [titleTimer invalidate];
            titleTimer = nil;
        }
    }];
}

- (void)handlePan:(UIPanGestureRecognizer*)gestureRecognizer {
    if (metadataExpanded) return;
    CGPoint fullTranslation = [gestureRecognizer locationInView:self.view];
    CGPoint translation = [gestureRecognizer translationInView:self.collectionView];
    NSIndexPath *indexPathForGesture = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
    UIView *view = nil; WFSlideshowSlideCell *cell;
    if (indexPathForGesture && indexPathForGesture.section > 0){
        cell = (WFSlideshowSlideCell*)[self.collectionView cellForItemAtIndexPath:indexPathForGesture];
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
    [gestureRecognizer setTranslation:CGPointMake(0, 0) inView:self.collectionView];

    if (view && cell){
        if (gestureRecognizer.state == UIGestureRecognizerStateBegan){
            [self.collectionView setScrollEnabled:NO];
        } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            [self.collectionView setScrollEnabled:YES];
        }
    }
    
    if (cell && gestureRecognizer.state == UIGestureRecognizerStateEnded && currentSlide && currentSlide.photoSlides.count){
        [(WFInteractiveImageView*)view setMoved:YES]; //offset and/or save pre-position
        PhotoSlide *photoSlide;
        if (view == cell.artImageView1){
            photoSlide = currentSlide.photoSlides[0];
        } else if (view == cell.artImageView2){
            photoSlide = currentSlide.photoSlides[0];
        } else if (view == cell.artImageView3){
            photoSlide = currentSlide.photoSlides[1];
        }
        [photoSlide setPositionX:@(view.frame.origin.x)];
        [photoSlide setPositionY:@(view.frame.origin.y)];
        [photoSlide setWidth:@(view.frame.size.width)];
        [photoSlide setHeight:@(view.frame.size.height)];
        [photoSlide setScale:@([[view.layer valueForKeyPath:@"transform.scale"] floatValue])];
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"slide photo after save: %@, %@, %@, %@ and scale: %@",photoSlide.positionX, photoSlide.positionY, photoSlide.width, photoSlide.height, photoSlide.scale);
        }];
    }
}

- (void)screenEdgePan:(UIScreenEdgePanGestureRecognizer*)gestureRecognizer {
    
    if (gestureRecognizer == bottomEdgePanGesture){
        NSLog(@"Bottom edge pan");
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (gestureRecognizer == rightScreenEdgePanGesture){
            //NSLog(@"done panning from right");
        } else if (gestureRecognizer == leftScreenEdgePanGesture){
            //NSLog(@"done panning from left");
        }
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
    if (metadataExpanded) return;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        lastScale = gestureRecognizer.scale;
        [self.collectionView setScrollEnabled:NO];
    }
    
    CGPoint pointInView = [gestureRecognizer locationInView:self.view];
    CGPoint gesturePoint = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *indexPathForGesture = [self.collectionView indexPathForItemAtPoint:gesturePoint];
    
    UIView *view = nil; WFSlideshowSlideCell *cell;
    if (indexPathForGesture && indexPathForGesture.section > 0){
        cell = (WFSlideshowSlideCell*)[self.collectionView cellForItemAtIndexPath:indexPathForGesture];
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
            const CGFloat kMinScale = .5;
            CGFloat newScale = 1 -  (lastScale - gestureRecognizer.scale);
            newScale = MIN(newScale, kMaxScale / currentScale);
            newScale = MAX(newScale, kMinScale / currentScale);
            CGAffineTransform transform = CGAffineTransformScale(view.transform, newScale, newScale);
            
            [UIView animateWithDuration:kSlowAnimationDuration delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                view.transform = transform;
            } completion:^(BOOL finished) {
                lastScale = gestureRecognizer.scale;  // Store the previous scale factor for the next pinch gesture call
            }];
        }
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        [self.collectionView setScrollEnabled:YES];
        if (cell && currentSlide && currentSlide.photoSlides.count){
            PhotoSlide *photoSlide;
            if (view == cell.artImageView1){
                photoSlide = currentSlide.photoSlides[0];
            } else if (view == cell.artImageView2){
                photoSlide = currentSlide.photoSlides[0];
            } else if (view == cell.artImageView3){
                photoSlide = currentSlide.photoSlides[1];
            }
            [photoSlide setPositionX:@(view.frame.origin.x)];
            [photoSlide setPositionY:@(view.frame.origin.y)];
            [photoSlide setWidth:@(view.frame.size.width)];
            [photoSlide setHeight:@(view.frame.size.height)];
            [photoSlide setScale:@(gestureRecognizer.scale)];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                NSLog(@"slide photo after save: %@, %@, %@, %@ and scale: %@",photoSlide.positionX, photoSlide.positionY, photoSlide.width, photoSlide.height, photoSlide.scale);
            }];
        }
    }
}

- (void)doubleTap:(UITapGestureRecognizer*)gestureRecognizer {
    CGPoint absolutePoint = [gestureRecognizer locationInView:self.view];
    //NSLog(@"absolute point double tapped: %f, %f",absolutePoint.x, absolutePoint.y);
    NSIndexPath *indexPathForGesture = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
    UIView *view = nil;
    
    if (indexPathForGesture && indexPathForGesture.section > 0){
        WFSlideshowSlideCell *cell = (WFSlideshowSlideCell*)[self.collectionView cellForItemAtIndexPath:indexPathForGesture];
        CGPoint tappedPoint = [gestureRecognizer locationInView:self.view];
        if (cell.slide.photos.count == 1){
            view = cell.artImageView1;
        } else {
            view = tappedPoint.x < width/2 ? cell.artImageView2 : cell.artImageView3;
        }
    }
    
    if (view && currentSlide && currentSlide.photoSlides.count){
        [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.7 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (view == artImageView1){
                if (artImageView1.moved){
                    view.transform = CGAffineTransformIdentity;
                    [artImageView1 setFrame:kOriginalArtImageFrame1];
                    PhotoSlide *photoSlide = currentSlide.photoSlides[0];
                    [photoSlide resetFrame];
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
                    PhotoSlide *photoSlide = currentSlide.photoSlides[0];
                    [photoSlide resetFrame];
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
                    PhotoSlide *photoSlide = currentSlide.photoSlides[1];
                    [photoSlide resetFrame];
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
            PhotoSlide *photoSlide;
            if (view == artImageView1){
                photoSlide = currentSlide.photoSlides[0];
            } else if (view == artImageView2){
                photoSlide = currentSlide.photoSlides[0];
            } else if (view == artImageView3){
                photoSlide = currentSlide.photoSlides[1];
            }
            [photoSlide setPositionX:@(view.frame.origin.x)];
            [photoSlide setPositionY:@(view.frame.origin.y)];
            [photoSlide setWidth:@(view.frame.size.width)];
            [photoSlide setHeight:@(view.frame.size.height)];
            [photoSlide setScale:@([[view.layer valueForKeyPath:@"transform.scale"] floatValue])];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                NSLog(@"slide photo after save: %@, %@, %@, %@ and scale: %@",photoSlide.positionX, photoSlide.positionY, photoSlide.width, photoSlide.height, photoSlide.scale);
            }];
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
