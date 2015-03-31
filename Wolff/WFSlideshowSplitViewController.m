//
//  WFSlideshowSplitViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFAppDelegate.h"
#import "WFSlideshowSplitViewController.h"
#import "WFSlideTableCell.h"
#import "WFNewSlideTableCell.h"
#import "WFSlideDetailViewController.h"
#import "WFSlideshowViewController.h"
#import "WFSlideAnimator.h"
#import "WFSlideshowFocusAnimator.h"
#import "WFSearchResultsViewController.h"
#import "WFPhotoCell.h"
#import "WFArtMetadataAnimator.h"
#import "WFArtMetadataViewController.h"
#import "WFSlideshowSettingsViewController.h"
#import "WFInteractiveImageView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "WFSaveMenuViewController.h"
#import "WFAlert.h"
#import "WFLightTablesViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "WFSlideTextViewController.h"

@interface WFSlideshowSplitViewController () <UIViewControllerTransitioningDelegate, UIAlertViewDelegate, WFSearchDelegate,WFSlideshowSettingsDelegate, UIPopoverControllerDelegate,  UITextFieldDelegate, WFImageViewDelegate, WFSaveSlideshowDelegate, WFLightTablesDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *playButton;
    UIBarButtonItem *searchButton;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *shareButton;
    UIBarButtonItem *settingsButton;
    CGFloat topInset;
    BOOL showSlideshow;
    BOOL showMetadata;
    UITextField *titleTextField;
    NSTimeInterval duration;
    UIViewAnimationOptions animationCurve;
    CGFloat keyboardHeight;
    UIAlertView *titlePrompt;
    UIAlertView *artImageViewPrompt;
    
    NSNumber *_lightTableId;
    NSIndexPath *activeIndexPath;
    Slide *activeSlide;
    WFInteractiveImageView *activeImageView;
    UIAlertView *removePhotoAlertView;
}

@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) Photo *selectedPhoto;
@property (strong, nonatomic) Slide *selectedSlide;
@property (nonatomic) WFInteractiveImageView *draggingView;
@property (nonatomic) CGPoint dragViewStartLocation;
@property (nonatomic) NSIndexPath *photoStartIndex;
@property (nonatomic) NSIndexPath *photoMoveToIndexPath;
@property (nonatomic) NSIndexPath *slideStartIndex;
@property (nonatomic) NSIndexPath *slideMoveToIndexPath;

@end

@implementation WFSlideshowSplitViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    if (IDIOM == IPAD){
        if (SYSTEM_VERSION >= 8.f){
            width = screenWidth(); height = screenHeight();
        } else {
            width = screenHeight(); height = screenWidth();
        }
    }
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController.navigationBar setTranslucent:YES];
    
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:.1 alpha:23]];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.1]];
    self.tableView.rowHeight = 180.f;
    
    [self registerKeyboardNotifications];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(slideSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    [self.tableView addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(slideDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.tableView addGestureRecognizer:doubleTap];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    longPressRecognizer.minimumPressDuration = .23;
    [self.view addGestureRecognizer:longPressRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideEditMenu:) name:UIMenuControllerWillHideMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHideEditMenu:) name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // manually set the top inset
    topInset = self.navigationController.navigationBar.frame.size.height;
    self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
    [self.tableView setContentOffset:CGPointMake(0, -topInset)];
    
    if (self.slideshowId){
        self.slideshow = [Slideshow MR_findFirstByAttribute:@"identifier" withValue:self.slideshowId inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!self.slideshow){
            [ProgressHUD show:@"Refreshing slideshow..."];
            [self refreshSlideshow];
        }
        [self setUpTitleView];
        [self setUpNavButtons];
        [self redrawSlideshow];
    } else if (!self.slideshow) {
        Slideshow *newSlideshow = [Slideshow MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        self.slideshow = newSlideshow;
        self.slideshow.user = self.currentUser;
        [self.collectionView setUserInteractionEnabled:NO];
        NSMutableOrderedSet *thePhotos = [NSMutableOrderedSet orderedSetWithOrderedSet:self.selectedPhotos];
        self.slideshow.photos = thePhotos;
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self setUpTitleView];
            [self setUpNavButtons];
            [self redrawSlideshow];
            [titleTextField becomeFirstResponder];
            [self.collectionView setUserInteractionEnabled:YES];
        }];
    } else if (self.slideshow) {
        NSManagedObjectID *objectID = self.slideshow.objectID;
        self.slideshow = (Slideshow*)[[NSManagedObjectContext MR_defaultContext] existingObjectWithID:objectID error:NULL];
        [self setUpTitleView];
        [self setUpNavButtons];
        [self redrawSlideshow];
        if (!self.slideshow.title.length){
            [titleTextField becomeFirstResponder];
        }
    }
}

- (void)refreshSlideshow {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [manager GET:[NSString stringWithFormat:@"slideshows/%@",self.slideshowId] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success refreshing slideshow: %@",responseObject);
        [self.slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self.collectionView reloadData];
            [self.tableView reloadData];
            [ProgressHUD dismiss];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [ProgressHUD dismiss];
        NSLog(@"Failed to refersh slideshow");
    }];
}

#pragma mark - View Setup
- (void)setUpNavButtons {
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItems = @[dismissButton];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    shareButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"shareArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(share)];
    searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search"] style:UIBarButtonItemStylePlain target:self action:@selector(startSearch)];
    saveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cloud"] style:UIBarButtonItemStylePlain target:self action:@selector(showSaveMenu)];
    settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"wrench"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
    playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playSlideshowFromStart)];
    
    //only show the settings buttons, and such, to the slideshow's owner
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        if ([self.slideshow.identifier isEqualToNumber:@0]){
            self.navigationItem.rightBarButtonItems = @[playButton, /*settingsButton,*/ searchButton, saveButton, shareButton];
        } else if ([self.slideshow.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
            self.navigationItem.rightBarButtonItems = @[playButton, /*settingsButton,*/ searchButton, saveButton, shareButton];
        } else {
            self.navigationItem.rightBarButtonItems = @[playButton, searchButton];
        }
    } else {
        self.navigationItem.rightBarButtonItems = @[playButton, searchButton];
    }
}

- (void)setUpTitleView {
    titleTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 26, width, 32)];
    [titleTextField setKeyboardAppearance:UIKeyboardAppearanceDark];
    [titleTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    titleTextField.returnKeyType = UIReturnKeyDone;
    titleTextField.delegate = self;
    titleTextField.layer.cornerRadius = 4.f;
    titleTextField.clipsToBounds = YES;
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 7, 20)];
    titleTextField.leftView = paddingView;
    titleTextField.leftViewMode = UITextFieldViewModeAlways;
    [titleTextField setText:self.slideshow.title];
    [titleTextField setTextColor:[UIColor whiteColor]];
    [titleTextField setTextAlignment:NSTextAlignmentCenter];
    [titleTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]];
    [titleTextField setPlaceholder:@"Your Slideshow Title"];
    if (!self.slideshow.title.length){
        [titleTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.06]];
    }
    self.navigationItem.titleView = titleTextField;
}

- (void)redrawSlideshow {
    if (!self.slideshow.photos.count){
        [_lightBoxPlaceholderLabel setText:@"You don't have any slides in this light table"];
        [_lightBoxPlaceholderLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansThinItalic] size:0]];
        [_lightBoxPlaceholderLabel setTextAlignment:NSTextAlignmentCenter];
        [_lightBoxPlaceholderLabel setTextColor:[UIColor lightGrayColor]];
        [_lightBoxPlaceholderLabel setHidden:NO];
    } else {
        [_lightBoxPlaceholderLabel setHidden:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return self.slideshow.slides.count;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        WFSlideTableCell *cell = (WFSlideTableCell *)[tableView dequeueReusableCellWithIdentifier:@"SlideTableCell"];
        [cell.contentView setAlpha:1.0]; // ensure the cell is fully lit up since we're dimmming on drag
        Slide *slide = self.slideshow.slides[indexPath.row];
        cell.artImageView1.imageViewDelegate = self;
        cell.artImageView2.imageViewDelegate = self;
        cell.artImageView3.imageViewDelegate = self;
        [cell configureForSlide:slide withSlideNumber:indexPath.row + 1];
        
        return cell;
    } else {
        WFNewSlideTableCell *cell = (WFNewSlideTableCell *)[tableView dequeueReusableCellWithIdentifier:@"NewSlideCell"];
        [cell.addPromptButton addTarget:self action:@selector(addNewSlide) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
}

- (void)addNewSlide {
    NSInteger slideCount = self.slideshow.slides.count;
    Slide *newSlide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [newSlide setSlideshow:self.slideshow];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self.tableView beginUpdates];
    NSIndexPath *indexPathForNewSlide = [NSIndexPath indexPathForRow:slideCount inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPathForNewSlide] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

- (void)slideSingleTap:(UITapGestureRecognizer*)gestureRecognizer {
    CGPoint loc = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForRowAtPoint:loc];
    [self becomeFirstResponder];
    activeIndexPath = selectedIndexPath;
    activeSlide = self.slideshow.slides[selectedIndexPath.row];
    
    WFSlideTableCell *cell = (WFSlideTableCell*)[self.tableView cellForRowAtIndexPath:selectedIndexPath];
    if (activeSlide.photos.count > 1){
        if (loc.x <= 150.f){
            activeImageView = cell.artImageView2;
        } else {
            activeImageView = cell.artImageView3;
        }
    } else if (activeSlide.photos.count == 1) {
        activeImageView = cell.artImageView1;
    }
    
    NSString *addTextItemTitle = NSLocalizedString(@"Add text", @"Add text to slide");
    UIMenuItem *addTextItem = [[UIMenuItem alloc] initWithTitle:addTextItemTitle action:@selector(addText:)];
    NSString *editTextItemTitle = NSLocalizedString(@"Edit text", @"Edit slide text");
    UIMenuItem *editTextItem = [[UIMenuItem alloc] initWithTitle:editTextItemTitle action:@selector(editText:)];
    NSString *removeItemTitle = NSLocalizedString(@"Remove", @"Remove art from slide");
    UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:removeItemTitle action:@selector(removeArt:)];
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    if (activeSlide.photos.count){
        [menuController setMenuItems:@[resetMenuItem]];
    } else if (activeSlide.slideTexts.count) {
        [menuController setMenuItems:@[editTextItem, resetMenuItem]];
    } else {
        [menuController setMenuItems:@[addTextItem]];
    }
    
    CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
    CGRect menuLocation = CGRectMake(location.x, location.y, 0, 0);
    [menuController setTargetRect:menuLocation inView:[gestureRecognizer view]];
    [menuController setMenuVisible:YES animated:YES];
}

- (void)removeArt:(UIMenuController*)menuController {
    [activeSlide removePhoto:activeImageView.photo];
    if (activeSlide.photos.count){
        [self.tableView reloadRowsAtIndexPaths:@[activeIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView beginUpdates];
        [self.slideshow removeSlide:activeSlide fromIndex:activeSlide.index.integerValue];
        [activeSlide MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
        
        activeSlide = nil;
        activeImageView = nil;
        activeIndexPath = nil;
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
    }];
}

- (void)addText:(UIMenuController*)menuController {
    WFSlideTextViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideText"];
    [vc setSlide:activeSlide];
    [vc setSlideshow:self.slideshow];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)editText:(UIMenuController*)menuController {
    WFSlideTextViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideText"];
    [vc setSlide:activeSlide];
    [vc setSlideshow:self.slideshow];
    [vc setSlideText:activeSlide.slideTexts.firstObject];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

// UIMenuController requires that we can become first responder or it won't display
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)slideDoubleTap:(UITapGestureRecognizer*)gestureRecognizer {
    CGPoint loc = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForRowAtPoint:loc];
    [self playSlideshow:selectedIndexPath.row];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    Slide *slide = self.slideshow.slides[fromIndexPath.row];
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.slideshow.slides];
    [tempSet removeObject:slide];
    [tempSet insertObject:slide atIndex:toIndexPath.row];
    self.slideshow.slides = tempSet;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES; // Return NO if you do not want the item to be re-orderable.
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return CGSizeMake((width-kSidebarWidth)/3,(width-kSidebarWidth)/3);
    } else {
        return CGSizeMake(width/2,width/2);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return self.slideshow.photos.count;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    [self redrawSlideshow];
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SlideshowArtCell" forIndexPath:indexPath];
    [cell.contentView setAlpha:1.0];
    Photo *photo = self.slideshow.photos[indexPath.item];
    [cell configureForPhoto:photo];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (kind == UICollectionElementKindSectionHeader){
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
        [headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        return headerView;
    } else {
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        return footerView;
    }
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Photo *photo = self.slideshow.photos[indexPath.item];
    [self showMetadata:photo];
}

- (void)showSlideDetail:(Slide*)slide {
    showSlideshow = NO;
    WFSlideDetailViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Slide"];
    [vc setSlide:slide];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)longPressed:(UILongPressGestureRecognizer*)gestureRecognizer {
    CGPoint loc = [gestureRecognizer locationInView:self.view];
    CGPoint photoLoc = CGPointMake(loc.x - kSidebarWidth, loc.y + self.collectionView.contentOffset.y);
    CGPoint slideLoc = CGPointMake(loc.x, loc.y + self.tableView.contentOffset.y);
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        //NSLog(@"loc x: %f, loc y: %f", loc.x,loc.y);
        
        if (loc.x > kSidebarWidth && self.slideshow.photos.count) {
            self.photoStartIndex = [self.collectionView indexPathForItemAtPoint:photoLoc];
            if (self.photoStartIndex) {
                WFPhotoCell *cell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.photoStartIndex];
                self.selectedPhoto = self.slideshow.photos[self.photoStartIndex.item];
                self.draggingView = [[WFInteractiveImageView alloc] initWithImage:[cell getRasterizedImageCopy] andPhoto:self.selectedPhoto];
                
                [cell.contentView setAlpha:0.1f];
                [self.view addSubview:self.draggingView];
                self.draggingView.center = loc;
                self.dragViewStartLocation = self.draggingView.center;
                [self.view bringSubviewToFront:self.draggingView];
                
                [UIView animateWithDuration:.23f animations:^{
                    CGAffineTransform transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                    self.draggingView.transform = transform;
                }];
            }
        } else if (loc.x < kSidebarWidth && self.slideshow.slides.count){
            self.slideStartIndex = [self.tableView indexPathForRowAtPoint:slideLoc];
            if (self.slideStartIndex) {
                WFSlideTableCell *cell = (WFSlideTableCell*)[self.tableView cellForRowAtIndexPath:self.slideStartIndex];
                self.selectedSlide = self.slideshow.slides[self.slideStartIndex.row];
                self.draggingView = [[WFInteractiveImageView alloc] initWithImage:[cell getRasterizedImageCopy] andPhoto:nil];
                
                [cell.contentView setAlpha:0.1f];
                [self.view addSubview:self.draggingView];
                self.draggingView.center = loc;
                self.dragViewStartLocation = self.draggingView.center;
                [self.view bringSubviewToFront:self.draggingView];
                
                [UIView animateWithDuration:.23f animations:^{
                    CGAffineTransform transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                    self.draggingView.transform = transform;
                }];
            }
        }
    }
    
    if (self.draggingView && gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.draggingView.center = loc;
        if (loc.x <= kSidebarWidth) {
            if (loc.y < 100.f && self.tableView.contentOffset.y > -topInset){
                [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y - 14) animated:NO];
            } else if (loc.y > self.view.frame.size.height - 100.f && self.tableView.contentOffset.y < self.tableView.contentSize.height){
                [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y + 14) animated:NO];
            }
        }
    }
    
    if (self.draggingView && gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint tableViewPoint = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPathForSlideCell = [self.tableView indexPathForRowAtPoint:tableViewPoint];
        
        if (_selectedPhoto){
            if (indexPathForSlideCell){  //cell was dropped in the left sidebar
                if (indexPathForSlideCell.section == 1){ // this means we should add a new slide
                    Slide *slide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [slide addPhoto:self.selectedPhoto];
                    [slide setIndex:@(self.slideshow.slides.count)];
                    [self.tableView beginUpdates];
                    [self.slideshow addSlide:slide atIndex:slide.index.integerValue];
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(slide.index.integerValue) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableView endUpdates];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                    }];
                    [self endPressAnimation];
                    return;
                } else {
                    Slide *slide = [self.slideshow.slides objectAtIndex:indexPathForSlideCell.row];
                    if (loc.x > -(kSidebarWidth/2) || slide.photos.count == 1){
                        if (slide.photos.count > 1){
                            [slide replacePhotoAtIndex:1 withPhoto:self.selectedPhoto];
                        } else {
                            [slide addPhoto:self.selectedPhoto];
                        }
                    } else {
                        [slide replacePhotoAtIndex:0 withPhoto:self.selectedPhoto];
                    }
                    [self.tableView reloadRowsAtIndexPaths:@[indexPathForSlideCell] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self endPressAnimation];
                    return;
                }
            }
        }
        
        if (self.draggingView) {
            if (_selectedPhoto){
                if (loc.x > kSidebarWidth)  {
                    if (loc.y <= 0 || loc.y >= (self.view.frame.size.height - 23.f)){
                        [self confirmRemovePhoto];
                    } else if (loc.x >= (self.view.frame.size.width - 23.f)){
                        [self confirmRemovePhoto];
                    } else {
                        [self endPressAnimation];
                    }
                } else {
                    [self endPressAnimation];
                }
                
            } else if (self.selectedSlide) {
                if (loc.x > kSidebarWidth){  //removing the slides
                    Slide *slide = [self.slideshow.slides objectAtIndex:self.slideStartIndex.row];
                    [UIView animateWithDuration:kFastAnimationDuration animations:^{
                        [self.slideshow removeSlide:slide fromIndex:self.slideStartIndex.row];
                        [self.tableView deleteRowsAtIndexPaths:@[self.slideStartIndex] withRowAnimation:UITableViewRowAnimationNone];
                        self.draggingView.transform = CGAffineTransformIdentity;
                        [self.draggingView setAlpha:.77f];
                    } completion:^(BOOL finished) {
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                        [self.draggingView removeFromSuperview];
                        self.draggingView = nil;
                        self.slideStartIndex = nil;
                    }];
                } else {  // reoder the slides
                    self.slideMoveToIndexPath = [self.tableView indexPathForRowAtPoint:slideLoc];
                    if (self.slideMoveToIndexPath && self.slideMoveToIndexPath.section == 0) {
                        //update date source
                        NSNumber *thisNumber = [self.slideshow.slides objectAtIndex:self.slideStartIndex.row];
                        NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.slideshow.slides];
                        [tempSet removeObjectAtIndex:self.slideStartIndex.row];
                        if (self.slideMoveToIndexPath.row < self.slideStartIndex.row) {
                            [tempSet insertObject:thisNumber atIndex:self.slideMoveToIndexPath.row];
                        } else {
                            [tempSet insertObject:thisNumber atIndex:self.slideMoveToIndexPath.row];
                        }
                        [self.slideshow setSlides:tempSet];
                        
                        [UIView animateWithDuration:.23f animations:^{
                            self.draggingView.transform = CGAffineTransformIdentity;
                        } completion:^(BOOL finished) {
                            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                            [self.draggingView removeFromSuperview];
                            self.draggingView = nil;
                            self.slideStartIndex = nil;
                        }];
                        
                    } else {
                        [self endPressAnimation];
                    }
                }
            } else {
                [self endPressAnimation];
            }
        }
    }
    loc = CGPointZero;
}

- (void)confirmRemovePhoto {
    removePhotoAlertView = [[UIAlertView alloc] initWithTitle:@"Please confirm" message:[NSString stringWithFormat:@"Are you sure you want to remove \"%@\" from this slideshow?",self.selectedPhoto.art.title] delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove",nil];
    removePhotoAlertView.delegate = self;
    [removePhotoAlertView show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == removePhotoAlertView){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove"]){
            [self.slideshow removePhoto:self.selectedPhoto];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            [self.collectionView performBatchUpdates:^{
                [self.collectionView deleteItemsAtIndexPaths:@[self.photoStartIndex]];
            } completion:^(BOOL finished) {

            }];
            [self removePhotoAnimation];
        } else {
            [self endPressAnimation];
        }
        
    }
}

- (void)endPressAnimation {
    [UIView animateWithDuration:.23f animations:^{
        self.draggingView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        if (self.photoStartIndex){
            WFPhotoCell *cell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.photoStartIndex];
            [cell.contentView setAlpha:1.f];
        } else if (self.slideStartIndex) {
            WFSlideTableCell *cell = (WFSlideTableCell*)[self.tableView cellForRowAtIndexPath:self.slideStartIndex];
            [cell.contentView setAlpha:1.f];
        }
        [self resetDragObjects];
    }];
}

- (void)resetDragObjects {
    [self.draggingView removeFromSuperview];
    self.draggingView = nil;
    self.photoStartIndex = nil;
    self.slideStartIndex = nil;
    self.selectedSlide = nil;
    self.selectedPhoto = nil;
}

- (void)removePhotoAnimation {
    [UIView animateWithDuration:.23f animations:^{
        self.draggingView.transform = CGAffineTransformMakeScale(.77, .77);
        [self.draggingView setAlpha:0.0];
    } completion:^(BOOL finished) {
        [self resetDragObjects];
    }];
}

- (void)showSaveMenu {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    WFSaveMenuViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SaveMenu"];
    vc.saveDelegate = self;
    vc.preferredContentSize = CGSizeMake(230, 108);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover presentPopoverFromBarButtonItem:saveButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)enableOfflineMode {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
    [WFAlert show:@"We're still working on these feature.\n\nBut don't worry, you can still save all your slideshows to the cloud." withTime:3.7f];
}

- (void)save {
    if (self.slideshow.title.length) {
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self post];
        }];
    } else {
        titlePrompt = [[UIAlertView alloc] initWithTitle:@"No title!" message:@"Please make sure you've titled this slideshow before saving." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [titlePrompt show];
    }
}

- (void)post {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    if (titleTextField.isEditing){
        [titleTextField resignFirstResponder];
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    if (self.slideshow.title.length){
        [parameters setObject:self.slideshow.title forKey:@"title"];
    }
    if (self.slideshow.slideshowDescription.length){
        [parameters setObject:self.slideshow.slideshowDescription forKey:@"description"];
    }
    
    NSMutableArray *slideshowPhotos = [NSMutableArray arrayWithCapacity:self.slideshow.photos.count];
    for (Photo *photo in self.slideshow.photos){
        [slideshowPhotos addObject:photo.identifier];
    }
    [parameters setObject:slideshowPhotos forKey:@"photo_ids"];
    
    [self.slideshow.slides enumerateObjectsUsingBlock:^(Slide *slide, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *slideObject = [NSMutableDictionary dictionary];
        if (slide && ![slide.identifier isEqualToNumber:@0]){
            [slideObject setObject:slide.identifier forKey:@"slide_id"];
        }
        if (slide.photos.count){
            NSMutableArray *artIds = [NSMutableArray arrayWithCapacity:slide.photos.count];
            [slide.photos enumerateObjectsUsingBlock:^(Art *art, NSUInteger idx, BOOL *stop) {
                [artIds addObject:art.identifier];
            }];
            [slideObject setObject:artIds forKey:@"photo_ids"];
        } else if (slide.slideTexts.count){
            [slide.slideTexts enumerateObjectsUsingBlock:^(SlideText *slideText, NSUInteger idx, BOOL *stop) {
                NSMutableDictionary *slideTextDict = [NSMutableDictionary dictionary];
                if (![slideText.identifier isEqualToNumber:@0]){
                    [slideTextDict setObject:slideText.identifier forKey:@"id"];
                }
                if (slideText.body.length){
                    [slideTextDict setObject:slideText.body forKey:@"body"];
                }

                [slideObject setObject:slideTextDict forKey:@"slide_text"];
            }];
        } else {
            [slideObject setObject:@"" forKey:@"text"];
        }
        
        [parameters setObject:slideObject forKey:[NSString stringWithFormat:@"slides[%lu]",(unsigned long)idx]];
    }];
    
    if ([self.slideshow.identifier isEqualToNumber:@0]){
        if (self.slideshow.title.length){
            [ProgressHUD show:[NSString stringWithFormat:@"Creating \"%@\"...",self.slideshow.title]];
        } else {
            [ProgressHUD show:@"Creating your slideshow..."];
        }
        
        [manager POST:[NSString stringWithFormat:@"slideshows"] parameters:@{@"slideshow":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success creating a slideshow: %@",responseObject);
            [self.slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (_lightTableId){
                    [self lightTableSelected:_lightTableId];
                } else {
                    [WFAlert show:@"Slideshow saved" withTime:2.3f];
                    [ProgressHUD dismiss];
                }
                if (self.slideshowDelegate && [self.slideshowDelegate respondsToSelector:@selector(slideshowCreatedWithId:)]){
                    [self.slideshowDelegate slideshowCreatedWithId:self.slideshow.identifier];
                }
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to create a slideshow: %@",error.description);
            [WFAlert show:@"Sorry, but something went wrong while saving your slideshow to the cloud.\n\nWe've saved it locally in the meantime." withTime:3.7f];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            [ProgressHUD dismiss];
        }];
    } else {
        [ProgressHUD show:@"Saving..."];
        [manager PATCH:[NSString stringWithFormat:@"slideshows/%@",self.slideshow.identifier] parameters:@{@"slideshow":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success saving a slideshow: %@",responseObject);
            [self.slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [WFAlert show:@"Slideshow saved" withTime:2.3f];
                [ProgressHUD dismiss];
                [self.collectionView reloadData];
                [self.tableView reloadData];
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to save a slideshow: %@",error.description);
            [WFAlert show:@"Sorry, but something went wrong while saving your slideshow to the cloud.\n\nWe've saved it locally in the meantime." withTime:3.7f];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            [ProgressHUD dismiss];
        }];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == titlePrompt){
        [titleTextField becomeFirstResponder];
    }
}

- (void)cloudDownload {
    NSLog(@"Should be downloading");
}

- (void)share {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    WFLightTablesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"LightTables"];
    vc.lightTableDelegate = self;
    vc.slideshowShareMode = YES;
    [vc setSlideshow:self.slideshow];
    [vc setLightTables:self.currentUser.lightTables.array.mutableCopy];
    CGFloat vcHeight = self.currentUser.lightTables.count*54.f > 260.f ? 260 : (self.currentUser.lightTables.count)*54.f;
    vc.preferredContentSize = CGSizeMake(420, vcHeight + 34.f); // add the header height
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover presentPopoverFromBarButtonItem:shareButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)lightTableSelected:(NSNumber *)lightTableId {
    Table *lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:lightTableId inContext:[NSManagedObjectContext MR_defaultContext]];
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    
    if ([self.slideshow.identifier isEqualToNumber:@0]){
        _lightTableId = lightTableId;
        [self save];
        return;
    } else {
        if (lightTable.identifier && ![lightTable.identifier isEqualToNumber:@0]){
            [self shareToLightTable:lightTable];
        } else {
            [lightTable addSlideshow:self.slideshow];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [WFAlert show:[NSString stringWithFormat:@"Dropped to \"%@\"",lightTable.name] withTime:2.7f];
            }];
        }
    }
}

- (void)lightTableDeselected:(NSNumber *)lightTableId {
    Table *lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:lightTableId inContext:[NSManagedObjectContext MR_defaultContext]];
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    if (lightTable.identifier && ![lightTable.identifier isEqualToNumber:@0]){
        [lightTable removeSlideshow:self.slideshow];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [parameters setObject:self.slideshow.identifier forKey:@"slideshow_id"];
        [manager DELETE:[NSString stringWithFormat:@"light_tables/%@/remove_slideshow",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success removing slideshow from light table: %@",responseObject);
            [WFAlert show:[NSString stringWithFormat:@"\"%@\" removed from \"%@\"",self.slideshow.title, lightTable.name] withTime:3.3f];
            [ProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to remove slideshow from light table: %@",error.description);
            [WFAlert show:@"Sorry, but something went wrong while trying to unshare this slideshow.\n\nPlease try again soon." withTime:3.3f];
            [ProgressHUD dismiss];
        }];
    } else {
        [lightTable removeSlideshow:self.slideshow];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [WFAlert show:[NSString stringWithFormat:@"\"%@\" removed",lightTable.name] withTime:2.7f];
        }];
    }
}

- (void)shareToLightTable:(Table*)lightTable {
    [lightTable addSlideshow:self.slideshow];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
       
    }];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    [parameters setObject:self.slideshow.identifier forKey:@"slideshow_id"];
    [manager POST:[NSString stringWithFormat:@"light_tables/%@/add_slideshow",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success adding slideshow to light table: %@",responseObject);
        [WFAlert show:[NSString stringWithFormat:@"\"%@\" dropped to \"%@\"",self.slideshow.title, lightTable.name] withTime:3.3f];
        if (self.slideshowDelegate && [self.slideshowDelegate respondsToSelector:@selector(slideshowWithId:droppedToLightTableWithId:)]){
            [self.slideshowDelegate slideshowWithId:self.slideshow.identifier droppedToLightTableWithId:lightTable.identifier];
        }
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to add slideshow to light table: %@",error.description);
        [WFAlert show:@"Sorry, but something went wrong while trying to share this slideshow.\n\nPlease try again soon." withTime:3.3f];
        [ProgressHUD dismiss];
    }];
}

- (void)startSearch {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    WFSearchResultsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SearchResults"];
    [vc setPhotos:_photos];
    vc.shouldShowSearchBar = YES;
    vc.shouldShowTiles = YES;
    vc.searchDelegate = self;
    vc.preferredContentSize = CGSizeMake(400, 500);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover setBackgroundColor:[UIColor blackColor]];
    [self.popover presentPopoverFromBarButtonItem:searchButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)searchDidSelectPhotoWithId:(NSNumber *)photoId {
    Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:photoId inContext:[NSManagedObjectContext MR_defaultContext]];
    BOOL add; NSIndexPath *indexPathToReload;
    if ([self.slideshow.photos containsObject:photo]){
        indexPathToReload = [NSIndexPath indexPathForItem:[self.slideshow.photos indexOfObject:photo] inSection:0];
        [self.slideshow removePhoto:photo];
        add = NO;
    } else {
        [self.slideshow addPhoto:photo];
        add = YES;
        indexPathToReload = [NSIndexPath indexPathForItem:0 inSection:0];
    }
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (add){
            [self.collectionView insertItemsAtIndexPaths:@[indexPathToReload]];
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        } else {
            [self.collectionView deleteItemsAtIndexPaths:@[indexPathToReload]];
        }
    }];
}

- (void)endSearch {
    [self.view endEditing:YES];
    [self.popover dismissPopoverAnimated:YES];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    // ensure it's really gone
    self.popover = nil;
}

- (void)showSettings {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    WFSlideshowSettingsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideshowSettings"];
    vc.settingsDelegate = self;
    vc.preferredContentSize = CGSizeMake(270, 330);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover setBackgroundColor:[UIColor blackColor]];
    [self.popover presentPopoverFromBarButtonItem:settingsButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)playSlideshowFromStart{
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    [self playSlideshow:0];
}

- (void)playSlideshow:(NSInteger)startIndex {
    if (self.slideshow.slides.count){
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        showSlideshow = YES;
        showMetadata = NO;
        WFSlideshowViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Slideshow"];
        [vc setStartIndex:startIndex];
        [vc setSlideshow:self.slideshow];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    } else {
        [WFAlert show:@"Remember to add at least one slide before playing your slideshow." withTime:3.3f];
    }
}

- (void)showMetadata:(Photo*)photo{
    WFArtMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ArtMetadata"];
    [vc setPhoto:photo];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    showSlideshow = NO;
    showMetadata = YES;
    
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

- (void)dismissMetadata {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    if (showSlideshow){
        WFSlideshowFocusAnimator *animator = [WFSlideshowFocusAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (showMetadata){
        WFArtMetadataAnimator *animator = [WFArtMetadataAnimator new];
        animator.presenting = YES;
        return animator;
    } else {
        WFSlideAnimator *animator = [WFSlideAnimator new];
        animator.presenting = YES;
        return animator;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if (showSlideshow){
        WFSlideshowFocusAnimator *animator = [WFSlideshowFocusAnimator new];
        return animator;
    } else if (showMetadata){
        WFArtMetadataAnimator *animator = [WFArtMetadataAnimator new];
        return animator;
    } else {
        WFSlideAnimator *animator = [WFSlideAnimator new];
        return animator;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == titleTextField) {
        [textField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.2]];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == titleTextField) {
        if (titleTextField.text.length){
            [self.slideshow setTitle:titleTextField.text];
            [textField setBackgroundColor:[UIColor colorWithWhite:1 alpha:0]];
        } else {
            [textField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.06]];
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == titleTextField && [string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)willShowKeyboard:(NSNotification*)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue *keyboardValue = keyboardInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
    keyboardHeight = convertedKeyboardFrame.size.height;
    duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, keyboardHeight+44, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, keyboardHeight+44, 0);
                     }
                     completion:NULL];
}

- (void)willHideKeyboard:(NSNotification *)notification {
    duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, 0, 0);
                     }
                     completion:NULL];
}

- (void)saveSlideshow {
    [ProgressHUD show:@"Saving..."];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"Success saving slideshow? %u",success);
        [ProgressHUD showSuccess:@"Saved"];
    }];
}

- (void)deleteSlideshow {
    [ProgressHUD show:@"Deleting..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    [manager DELETE:[NSString stringWithFormat:@"slideshows/%@",self.slideshow.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success deleting this slideshow: %@",responseObject);
        [self deleteAndMoveOn];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to delete slideshow: %@", error.description);
        [self deleteAndMoveOn];
    }];
}

- (void)updateSlideshow {
    NSLog(@"Should be updating slideshow");
}

- (void)deleteAndMoveOn {
    [self.slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [ProgressHUD dismiss];
        [self dismiss];
    }];
}

- (void)willHideEditMenu:(id)sender {
    
}

- (void)didHideEditMenu:(id)sender {
    [self resignFirstResponder];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.popover && self.popover.isPopoverVisible){
        [self.popover dismissPopoverAnimated:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (!self.slideshow.slides.count && !self.slideshow.photos.count && !self.slideshow.title.length){
        [self.slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"Success deleting a phantom slideshow: %u",success);
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
