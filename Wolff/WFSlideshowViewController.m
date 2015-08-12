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
#import "WFProfileViewController.h"
#import "WFPartnerProfileViewController.h"

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
    
    UIPanGestureRecognizer *_panGesture;
    UIPinchGestureRecognizer *_pinchGesture;
    UITapGestureRecognizer *_doubleTapGesture;
    UIScreenEdgePanGestureRecognizer *rightScreenEdgePanGesture;
    UIScreenEdgePanGestureRecognizer *leftScreenEdgePanGesture;
    UIScreenEdgePanGestureRecognizer *bottomEdgePanGesture;
    CGFloat lastScale;
    CGPoint lastPoint;
    
    NSInteger currentPage;
    UIImageView *navBarShadowView;
    UIImageView *toolBarShadowView;
    UIBarButtonItem *slideshowTitleButtonItem;
    UIBarButtonItem *nextButton;
    UIBarButtonItem *previousButton;
    UIBarButtonItem *slideNumberButtonItem;
    UITapGestureRecognizer *metadataTap;
    CGFloat metadataTitleY;
    CGFloat metadataTitleHeight;
    CGFloat metadataComponentsY;
    CGFloat metadataComponentsHeight;
    
    //slideshow ivars
    WFInteractiveImageView *artImageView1;
    WFInteractiveImageView *artImageView2;
    WFInteractiveImageView *artImageView3;
    UIView *containerView1;
    UIView *containerView2;
    UIView *containerView3;
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
    [self.view setBackgroundColor:[UIColor blackColor]];
    if (self.slideshow) self.slideshow = [self.slideshow MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    
    barsVisible = NO; // by default
    metadataExpanded = NO; // by default
    [self setUpNavBar];
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    
    [self setupGestureRecognizers];
    [self setupMetadataContainer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self calculateImageFrames];
    topInset = self.collectionView.contentInset.top;
    [navBarShadowView setHidden:YES];
    [toolBarShadowView setHidden:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    self.navigationController.navigationBar.transform = CGAffineTransformMakeTranslation(0, -self.navigationController.navigationBar.frame.size.height);
    if (IDIOM != IPAD){
        if (self.slideshow) {
            NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
        } else {
            [self.collectionView setAlpha:0.0];
        }
    }
    
    if (self.slideshow){
        [self determinePageNumbers];
        NSLog(@"current page after determining page numbers: %ld",(long)currentPage);
    }
    [self.metadataCollectionView reloadData];
    [self adjustMetadataPosition];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (IDIOM != IPAD && !self.slideshow){
        // only applies for iphones on non slideshow presentations
        [artImageView1 setFrame:kOriginalArtImageFrame1];
        [artImageView1 setMoved:NO];
        artImageView1.transform = CGAffineTransformIdentity;
        
        [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
            [self.collectionView setAlpha:1.0];
        }];
    }
}

- (void)calculateImageFrames {
    //calculate the "home position" geometry for slides at runtime
    CGFloat frameHeight = (IDIOM == IPAD) ? 660.f : 300.f;
    CGFloat singleWidth = (IDIOM == IPAD) ? 900.f : 460.f;
    CGFloat splitWidth = (IDIOM == IPAD) ? 480.f : 260.f;
    kOriginalArtImageFrame1 = CGRectMake((width/2-singleWidth/2), (height/2-frameHeight/2), singleWidth, frameHeight);
    kOriginalArtImageFrame2 = CGRectMake((width/4-splitWidth/2), (height/2-frameHeight/2), splitWidth, frameHeight);
    kOriginalArtImageFrame3 = CGRectMake((width/4-splitWidth/2), (height/2-frameHeight/2), splitWidth, frameHeight);
}

- (void)setupMetadataContainer {
    metadataTitleHeight = 0.f; // default
    metadataComponentsHeight = 0.f;
    [self.slideMetadataContainerView setFrame:CGRectMake(0, height, width, height)];
    
    UIToolbar *toolbarBackground = [[UIToolbar alloc] initWithFrame:self.view.frame];
    [toolbarBackground setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [toolbarBackground setBarStyle:UIBarStyleBlackTranslucent];
    [toolbarBackground setTranslucent:YES];
    toolbarBackground.clipsToBounds = YES; // hide the thin border line on the UIToolbar
    [self.slideMetadataContainerView addSubview:toolbarBackground];
    [self.slideMetadataContainerView sendSubviewToBack:toolbarBackground];
    
    if (!metadataTap){
        metadataTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleMetadata)];
        metadataTap.numberOfTapsRequired = 1;
        metadataTap.delegate = self;
        [self.metadataCollectionView addGestureRecognizer:metadataTap];
    }
    
    [self.metadataCollectionView setBackgroundColor:[UIColor clearColor]];
}

- (void)adjustMetadataPosition {
    if (self.slideshow){
        __block CGFloat slideTitleMetadataHeight = 0;
        __block CGFloat slideTitleMetadataY = 0;
        __block CGFloat slideComponentsMetadataHeight = 0;
        __block CGFloat slideComponentsMetadataY = 0;
        [currentSlide.photoSlides enumerateObjectsUsingBlock:^(PhotoSlide *photoSlide, NSUInteger idx, BOOL *stop) {
            if (photoSlide.metadataTitleHeight.floatValue > slideTitleMetadataHeight){
                slideTitleMetadataHeight = photoSlide.metadataTitleHeight.floatValue;
                slideTitleMetadataY = photoSlide.metadataTitleY.floatValue;
            }
            if (photoSlide.metadataComponentsHeight.floatValue > slideComponentsMetadataHeight){
                slideComponentsMetadataHeight = photoSlide.metadataComponentsHeight.floatValue;
                slideComponentsMetadataY = photoSlide.metadataComponentsY.floatValue;
            }
        }];
        metadataTitleHeight = slideTitleMetadataHeight;
        metadataTitleY = slideTitleMetadataY;
        metadataComponentsHeight = slideComponentsMetadataHeight;
        metadataComponentsY = slideComponentsMetadataY;
    }

    CGFloat adjustmentHeight = metadataExpanded ? (metadataTitleHeight + metadataTitleY + metadataComponentsHeight + 7.f) : (metadataTitleHeight + metadataTitleY);
    if (self.photos.count || barsVisible || [self.slideshow.showMetadata isEqualToNumber:@YES]){
        [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
            [self.slideMetadataContainerView setFrame:CGRectMake(0, height - adjustmentHeight, width, height)];
        }];
    }
}

- (void)setUpNavBar {
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    if (self.slideshow){
        previousButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"leftArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(previousSlide:)];
        nextButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"rightArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(nextSlide:)];
        slideNumberButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
        slideshowTitleButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.slideshow.title style:UIBarButtonItemStylePlain target:self action:nil];
        
        [slideNumberButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0],NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
        [slideshowTitleButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0],NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
        
        self.navigationItem.leftBarButtonItems = @[dismissButton, slideshowTitleButtonItem];
        self.navigationItem.rightBarButtonItems = @[nextButton, slideNumberButtonItem, previousButton];
    } else {
        self.navigationItem.leftBarButtonItem = dismissButton;
    }
    
    [self determinePageNumbers];
}

- (void)determinePageNumbers {
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
        CGFloat titleOffset = [self.slideshow.showTitleSlide isEqualToNumber:@YES] ? width : 0;
        [self.collectionView setContentOffset:CGPointMake(titleOffset, 0) animated:NO]; // offset by 1 because of the title slide
        [slideNumberButtonItem setTitle:[NSString stringWithFormat:@"%ld of %lu",(long)currentPage,(unsigned long)self.slideshow.slides.count]];
        currentPage = _startIndex.integerValue + 1;
    } else {
        NSInteger titleOffset = [self.slideshow.showTitleSlide isEqualToNumber:@YES] ? 1 : 0;
        [self.collectionView setContentOffset:CGPointMake(width * (_startIndex.integerValue + titleOffset), 0) animated:NO]; // offset by 1 because of the title slide
        [slideNumberButtonItem setTitle:[NSString stringWithFormat:@"%ld of %lu",(long)currentPage,(unsigned long)self.slideshow.slides.count]];
        currentPage = _startIndex.integerValue + 1;
    }
    //NSLog(@"start index: %@",_startIndex);
}

- (void)toggleMetadata {
    metadataExpanded = !metadataExpanded;
    CGFloat adjustmentHeight = metadataExpanded ? (metadataTitleHeight + metadataTitleY + metadataComponentsHeight + 7.f) : (metadataTitleHeight + metadataTitleY);
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.77 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.slideMetadataContainerView setFrame:CGRectMake(0, height - adjustmentHeight, width, height)];
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
            [slideNumberButtonItem setTitle:@""];
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
    [self adjustMetadataPosition];
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
        return self.slideshow ? 2 : 1;
    } else {
        if (self.photos.count){
            return 1; // one-off comparison
        } else {
            return self.slideshow.slides.count + 1; // add a title slide
        }
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.collectionView){ // slideshow collectionView
        if (self.photos.count){
            return 1; // one-off comparison
        } else if (section == 0) {
            return [self.slideshow.showTitleSlide isEqualToNumber:@YES] ? 1 : 0;
        } else {
            return self.slideshow.slides.count;
        }
    } else { // metadata collectionView
        if (self.photos.count){
            return self.photos.count; // one-off comparison
        } else if (section == 0){
            return [self.slideshow.showTitleSlide isEqualToNumber:@YES] ? 1 : 0; // the title slide
        } else {
            Slide *slide = self.slideshow.slides[section-1];
            return slide.photoSlides.count < 2 && slide.slideTexts.count < 2 ? 1 : 2;
        }
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.collectionView){
        if (self.photos.count){
            WFSlideshowSlideCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SlideCell" forIndexPath:indexPath];
            [cell configureForPhotos:self.photos.mutableCopy inSlide:nil];
            
            // temporary
            [cell.artImageView1 setFrame:kOriginalArtImageFrame1];
            [cell.artImageView2 setFrame:kOriginalArtImageFrame2];
            [cell.artImageView3 setFrame:kOriginalArtImageFrame3];
            
            [self assignViewsForCell:cell];
            
            return cell;
        } else if (indexPath.section == 0){
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
        if (indexPath.section > 0) currentSlide = self.slideshow.slides[indexPath.section - 1];
    
        PhotoSlide *photoSlide;
        CGRect titleLabelFrame = cell.titleLabel.frame;
        CGRect componentsLabelFrame = cell.metadataComponentsLabel.frame;
        
        if (self.photos.count){
            [cell configureForPhoto:self.photos[indexPath.item] withPhotoCount:self.photos.count];
            if (self.photos.count <= 1){
                titleLabelFrame.size.width = width-70;
                componentsLabelFrame.size.width = width-70;
            } else {
                titleLabelFrame.size.width = (width-70)/2;
                componentsLabelFrame.size.width = (width-70)/2;
            }
        } else if (self.slideshow && [self.slideshow.showTitleSlide isEqualToNumber:@YES] && indexPath.section == 0){
            [cell.titleLabel setAttributedText:nil]; // title slide, so don't do anything
            [cell.metadataComponentsLabel setAttributedText:nil];
        } else if (currentSlide.slideTexts.count) {
            [cell.titleLabel setAttributedText:nil]; // slide text slide, so don't do anything
            [cell.metadataComponentsLabel setAttributedText:nil];
        } else if (currentSlide) {
    
            photoSlide = currentSlide.photoSlides[indexPath.item];
            [cell configureForPhoto:photoSlide.photo withPhotoCount:currentSlide.photoSlides.count];
            if (currentSlide.photoSlides.count < 2 && currentSlide.slideTexts.count < 2){
                titleLabelFrame.size.width = width-70;
                componentsLabelFrame.size.width = width-70;
            } else {
                titleLabelFrame.size.width = (width-70)/2;
                componentsLabelFrame.size.width = (width-70)/2;
            }
        }
        
        // frame the stuff
        CGSize titleSize = [cell.titleLabel sizeThatFits:CGSizeMake(titleLabelFrame.size.width, CGFLOAT_MAX)];
        titleLabelFrame.size.height = titleSize.height;
        CGSize componentsSize = [cell.metadataComponentsLabel sizeThatFits:CGSizeMake(componentsLabelFrame.size.width, CGFLOAT_MAX)];
        componentsLabelFrame.size.height = componentsSize.height;
        componentsLabelFrame.origin.x = titleLabelFrame.origin.x;
        componentsLabelFrame.origin.y = titleLabelFrame.origin.y + titleLabelFrame.size.height + 7.f;
        
        [cell.titleLabel setFrame:titleLabelFrame];
        [cell.metadataComponentsLabel setFrame:componentsLabelFrame];
        if (self.photos.count){
            metadataTitleHeight = titleLabelFrame.size.height;
            metadataTitleY = titleLabelFrame.origin.y + 7.f;
            metadataComponentsHeight = componentsSize.height;
            metadataComponentsY = componentsLabelFrame.origin.y;
        } else if (photoSlide) {
            photoSlide.metadataTitleHeight = @(titleLabelFrame.size.height);
            photoSlide.metadataTitleY = @(titleLabelFrame.origin.y + 7.f);
            photoSlide.metadataComponentsHeight = @(componentsSize.height);
            photoSlide.metadataComponentsY = @(componentsLabelFrame.origin.y + 7.f);
        }
        if (!cell.postedByButton){
            cell.postedByButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [cell.contentView addSubview:cell.postedByButton];
        }
        [cell.postedByButton setFrame:componentsLabelFrame];
        [cell.postedByButton setTag:indexPath.item];
        [cell.postedByButton addTarget:self action:@selector(showProfile:) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }
}

- (void)showProfile:(UIButton*)button {
    Photo *photo;
    if (self.photos.count){
        photo = self.photos[button.tag];
    } else {
        PhotoSlide *ps = currentSlide.photoSlides[button.tag];
        photo = ps.photo;
    }
    
    if (photo.partners.count){
        WFPartnerProfileViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"PartnerProfile"];
        [vc setPartner:(Partner*)photo.partners.firstObject];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:NULL];
    } else if (photo.user) {
        WFProfileViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
        [vc setUser:photo.user];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:NULL];
    }
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat fullWidth = collectionView.frame.size.width;
    CGFloat fullHeight = collectionView.frame.size.height;
    if (collectionView == self.collectionView){
        return CGSizeMake(fullWidth,fullHeight);
    } else {
        if (self.photos.count){
            if (self.photos.count == 1){
                return CGSizeMake(fullWidth,fullHeight);
            } else {
                return CGSizeMake(fullWidth/2,fullHeight);
            }
        } else if (indexPath.section == 0){
            return CGSizeMake(fullWidth,fullHeight);
        } else {
            Slide *slide = self.slideshow.slides[indexPath.section - 1];
            if (slide.photoSlides.count <= 1 && slide.slideTexts.count <= 1){
                return CGSizeMake(fullWidth,fullHeight);
            } else {
                return CGSizeMake(fullWidth/2,fullHeight);
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
        [self toggleMetadata];
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
        CGFloat adjustmentHeight = metadataExpanded ? (metadataTitleHeight + metadataTitleY + metadataComponentsHeight + 7.f) : (metadataTitleY + metadataTitleHeight);
        [self.slideMetadataContainerView setFrame:CGRectMake(0, height - adjustmentHeight, width, height)];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hideBars {
    barsVisible = NO;
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.925 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.navigationController.navigationBar.transform = CGAffineTransformMakeTranslation(0, -self.navigationController.navigationBar.frame.size.height);
        if (![self.slideshow.showMetadata isEqualToNumber:@YES]){
            [self.slideMetadataContainerView setFrame:CGRectMake(0, height, width, height)];
        }
    } completion:^(BOOL finished) {
       
    }];
}

- (void)handlePan:(UIPanGestureRecognizer*)gestureRecognizer {
    CGPoint fullTranslation = [gestureRecognizer locationInView:self.view];
    if (metadataExpanded) return;
    CGPoint translation = [gestureRecognizer translationInView:self.collectionView];
    NSIndexPath *indexPathForGesture = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
    if (self.slideshow && [self.slideshow.showTitleSlide isEqualToNumber:@YES] && indexPathForGesture.section == 0) return;
    UIView *view = nil; WFSlideshowSlideCell *cell;
    if (indexPathForGesture){
        cell = (WFSlideshowSlideCell*)[self.collectionView cellForItemAtIndexPath:indexPathForGesture];
        if (cell.slide.photos.count == 1 || self.photos.count == 1){
            view = cell.artImageView1;
        } else if (cell.slide.photos.count > 1 || self.photos.count > 1){
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
    
    if (cell && gestureRecognizer.state == UIGestureRecognizerStateEnded){
        if (currentSlide && currentSlide.photoSlides.count){
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
        } else if (self.photos.count) {
            [(WFInteractiveImageView*)view setMoved:YES];
        }
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
    
    if (self.slideshow && [self.slideshow.showTitleSlide isEqualToNumber:@YES] && indexPathForGesture.section == 0) return;
    
    UIView *view = nil; WFSlideshowSlideCell *cell;
    if (indexPathForGesture){
        cell = (WFSlideshowSlideCell*)[self.collectionView cellForItemAtIndexPath:indexPathForGesture];
        if (cell.slide.photos.count == 1 || self.photos.count == 1){
            view = cell.artImageView1;
        } else if (cell.slide.photos.count > 1 || self.photos.count > 1){
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
    NSIndexPath *indexPathForGesture = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
    UIView *view = nil;
    if (self.slideshow && [self.slideshow.showTitleSlide isEqualToNumber:@YES] && indexPathForGesture.section == 0) return;
    
    if (indexPathForGesture){
        WFSlideshowSlideCell *cell = (WFSlideshowSlideCell*)[self.collectionView cellForItemAtIndexPath:indexPathForGesture];
        CGPoint tappedPoint = [gestureRecognizer locationInView:self.view];
        if (cell.slide.photos.count == 1 || self.photos.count == 1){
            view = cell.artImageView1;
        } else if (cell.slide.photos.count > 1 || self.photos.count > 1) {
            view = tappedPoint.x < width/2 ? cell.artImageView2 : cell.artImageView3;
        }
    }
    
    if (view){
        [UIView animateWithDuration:kSlideResetAnimationDuration delay:0 usingSpringWithDamping:.975 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            if (view == artImageView1){
                if (artImageView1.moved){
                    NSLog(@"art image 1 moved");
                    artImageView1.transform = CGAffineTransformIdentity;
                    [artImageView1 setFrame:kOriginalArtImageFrame1];
                    if (currentSlide){
                        PhotoSlide *photoSlide = currentSlide.photoSlides[0];
                        [photoSlide resetFrame];
                    }
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
                NSLog(@"art image 2");
                if (artImageView2.moved){
                    artImageView2.transform = CGAffineTransformIdentity;
                    [artImageView2 setFrame:kOriginalArtImageFrame2];
                    if (currentSlide){
                        PhotoSlide *photoSlide = currentSlide.photoSlides[0];
                        [photoSlide resetFrame];
                    }
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
                NSLog(@"art image 3");
                if (artImageView3.moved){
                    NSLog(@"art image 3 moved");
                    artImageView3.transform = CGAffineTransformIdentity;
                    [artImageView3 setFrame:kOriginalArtImageFrame3];
                    if (currentSlide){
                        PhotoSlide *photoSlide = currentSlide.photoSlides[1];
                        [photoSlide resetFrame];
                    }
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
            if (currentSlide){
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
            }
        }];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    width = size.width; height = size.height;
    [self calculateImageFrames];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        [self.metadataCollectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        [self adjustMetadataPosition];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (self.photos.count == 1){
            [artImageView1 setFrame:kOriginalArtImageFrame1];
            [artImageView1 setMoved:NO];
            artImageView1.transform = CGAffineTransformIdentity;
        }
    }];
}

#pragma mark - Gesture Recognizer Delegate

- (void)setupGestureRecognizers {
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
    _doubleTapGesture.delegate = self;
    [self.view addGestureRecognizer:_doubleTapGesture];
    
    singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    singleTap.delegate = self;
    singleTap.numberOfTapsRequired = 1;
    [self.collectionView addGestureRecognizer:singleTap];
    
    if (self.photos.count){
        [self.collectionView setScrollEnabled:NO];
        [self.collectionView setCanCancelContentTouches:NO];
        [singleTap requireGestureRecognizerToFail:_doubleTapGesture];
    } else {
        [self.collectionView setDelaysContentTouches:NO];
        [self.collectionView setCanCancelContentTouches:YES];
        [singleTap requireGestureRecognizerToFail:_doubleTapGesture];
        [_panGesture requireGestureRecognizerToFail:rightScreenEdgePanGesture];
        [_panGesture requireGestureRecognizerToFail:leftScreenEdgePanGesture];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:self.metadataCollectionView] && metadataExpanded) {
        return NO; // ignore the touch
    }
    return YES; // handle the touch
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
