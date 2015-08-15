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
#import "WFUtilities.h"
#import "WFNoRotateNavController.h"
#import "WFTransparentBGModalAnimator.h"

NSString* const shareOption = @"Share";
NSString* const searchOption = @"Search for images";
NSString* const saveOption = @"Save";
NSString* const settingsOption = @"Slideshow settings";
NSString* const playOption = @"Play";

@interface WFSlideshowSplitViewController () <UIViewControllerTransitioningDelegate, UIAlertViewDelegate, UIActionSheetDelegate, WFSearchDelegate, WFSlideTextDelegate, WFSlideshowSettingsDelegate, UIPopoverControllerDelegate,  UITextFieldDelegate, WFImageViewDelegate, WFSaveSlideshowDelegate, WFLightTablesDelegate> {
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
    BOOL landscape;
    BOOL showSlideshow;
    BOOL showMetadata;
    BOOL transparentBG;
    UITextField *titleTextField;
    NSTimeInterval duration;
    UIViewAnimationOptions animationCurve;
    CGFloat keyboardHeight;
    UIAlertView *titlePrompt;
    UIAlertView *artImageViewPrompt;
    
    NSIndexPath *activeIndexPath;
    Slide *activeSlide;
    WFInteractiveImageView *activeImageView;
    UIAlertView *removePhotoAlertView;
    UIImageView *navBarShadowView;
    
    NSTimer *saveTimer;
}

@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) Photo *selectedPhoto;
@property (strong, nonatomic) Slide *selectedSlide;
@property (strong, nonatomic) LightTable *lightTable;
@property (nonatomic) WFInteractiveImageView *draggingView;
@property (nonatomic) CGPoint dragViewStartLocation;
@property (nonatomic) NSIndexPath *photoStartIndex;
@property (nonatomic) NSIndexPath *photoMoveToIndexPath;
@property (nonatomic) NSIndexPath *slideStartIndex;
@property (nonatomic) NSIndexPath *slideMoveToIndexPath;
@property (strong, nonatomic) AFHTTPRequestOperation *mainRequest;

@end

@implementation WFSlideshowSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (IDIOM == IPAD){
        width = screenWidth(); height = screenHeight();
    } else {
        width = screenWidth(); height = screenHeight();
    }
    landscape = self.view.frame.size.width > self.view.frame.size.height ? YES : NO;
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    
    if (self.slideshow){
        self.slideshow = [self.slideshow MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        [self setUpTitleView];
        [self setUpNavButtons];
        [self redrawSlideshow];
    } else {
        self.slideshow = [Slideshow MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        self.slideshow.user = self.currentUser;
        self.slideshow.photos = self.selectedPhotos;
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self setUpTitleView];
            [self setUpNavButtons];
            [self redrawSlideshow];
            [titleTextField becomeFirstResponder];
            [self.collectionView setUserInteractionEnabled:YES];
        }];
    }
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController.navigationBar setTranslucent:YES];
    
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:.1 alpha:23]];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.1]];
    self.tableView.rowHeight = 180.f;
    self.collectionView.alwaysBounceVertical = YES; // always stay bouncy!
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
    
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideEditMenu:) name:UIMenuControllerWillHideMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHideEditMenu:) name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
    topInset = self.navigationController.navigationBar.frame.size.height; // manually set the top inset
    self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
    [self.tableView setContentOffset:CGPointMake(0, -topInset)];
    if (IDIOM != IPAD){
        [self adjustForSize:self.view.frame.size];
    }
    [self.tableView reloadData];
    [self.collectionView reloadData];
    if (!saveTimer){
        saveTimer = [NSTimer scheduledTimerWithTimeInterval:30.f target:self selector:@selector(autosaveLocally) userInfo:nil repeats:YES];
    }
}

- (void)autosaveLocally {
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"Locally autosaved: %u",success);
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!titleTextField.text.length){
        [titleTextField becomeFirstResponder];
    }
}

- (void)refreshSlideshow {
//    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
//    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
//    [manager GET:[NSString stringWithFormat:@"slideshows/%@",self.slideshow.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        //NSLog(@"Success refreshing slideshow: %@",responseObject);
//        [self.slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
//        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
//            [self.collectionView reloadData];
//            [self.tableView reloadData];
//            [ProgressHUD dismiss];
//        }];
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        [ProgressHUD dismiss];
//        NSLog(@"Failed to refresh slideshow");
//    }];
}

#pragma mark - View Setup
- (void)setUpNavButtons {
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItems = @[dismissButton];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    if (IDIOM == IPAD){
        shareButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"shareArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(share)];
        searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search"] style:UIBarButtonItemStylePlain target:self action:@selector(startSearch)];
        saveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cloud"] style:UIBarButtonItemStylePlain target:self action:@selector(showSaveMenu)];
        settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"wrench"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
        playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playSlideshowFromStart)];
        //only show the settings buttons, and such, to the slideshow's owner
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
            if ([self.slideshow.identifier isEqualToNumber:@0]){
                self.navigationItem.rightBarButtonItems = @[playButton, settingsButton, searchButton, saveButton, shareButton];
            } else if ([self.slideshow.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
                self.navigationItem.rightBarButtonItems = @[playButton, settingsButton, searchButton, saveButton, shareButton];
            } else {
                self.navigationItem.rightBarButtonItems = @[playButton, searchButton];
            }
        } else {
            self.navigationItem.rightBarButtonItems = @[playButton, searchButton];
        }
    } else {
        UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(showSlideshowOptionsActionSheet)];
        self.navigationItem.rightBarButtonItem = menuButton;
    }
}

- (void)showSlideshowOptionsActionSheet {
    UIActionSheet *slideshowOptions = [[UIActionSheet alloc] initWithTitle:@"Slideshow options"
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:shareOption,saveOption,searchOption, settingsOption, playOption, nil];
    [slideshowOptions showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:shareOption]){
        [self share];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:saveOption]){
        [self showSaveMenu];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:searchOption]){
        [self startSearch];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:settingsOption]){
        [self showSettings];
    } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:playOption]){
        [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .5f * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self playSlideshowFromStart];
        });
        
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
    [titleTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
    [titleTextField setPlaceholder:@"Your Slideshow Title"];
    if (!self.slideshow.title.length){
        [titleTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.06]];
    }
    self.navigationItem.titleView = titleTextField;
}

- (void)redrawSlideshow {
    if (self.slideshow.photos.count){
        [_lightBoxPlaceholderLabel setHidden:YES];
    } else {
        [_lightBoxPlaceholderLabel setText:@"You don't have any slides in this light table"];
        [_lightBoxPlaceholderLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansThinItalic] size:0]];
        [_lightBoxPlaceholderLabel setTextAlignment:NSTextAlignmentCenter];
        [_lightBoxPlaceholderLabel setTextColor:[UIColor lightGrayColor]];
        [_lightBoxPlaceholderLabel setHidden:NO];
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
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
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
    
    if (selectedIndexPath.section == 0){
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
}

- (void)removeArt:(UIMenuController*)menuController {
    NSPredicate *photoSlidePredicate = [NSPredicate predicateWithFormat:@"slide.identifier == %@ and photo.identifier == %@",activeSlide.identifier, activeImageView.photo.identifier];
    PhotoSlide *photoSlide = [PhotoSlide MR_findFirstWithPredicate:photoSlidePredicate inContext:[NSManagedObjectContext MR_defaultContext]];
    if (photoSlide && activeSlide){
        [activeSlide removePhotoSlide:photoSlide];
        if (activeSlide.photos.count){
            [self.tableView reloadRowsAtIndexPaths:@[activeIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [self.tableView beginUpdates];
            [self.slideshow removeSlide:activeSlide fromIndex:activeSlide.index.integerValue];
            [activeSlide MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            
            activeSlide = nil;
            activeImageView = nil;
            activeIndexPath = nil;
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
    }
}

- (void)addText:(UIMenuController*)menuController {
    WFSlideTextViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideText"];
    vc.slideTextDelegate = self;
    [vc setSlide:activeSlide];
    [vc setSlideshow:self.slideshow];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)editText:(UIMenuController*)menuController {
    WFSlideTextViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideText"];
    vc.slideTextDelegate = self;
    [vc setSlide:activeSlide];
    [vc setSlideshow:self.slideshow];
    [vc setSlideText:activeSlide.slideTexts.firstObject];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)createdSlideText:(SlideText *)slideText {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.slideshow.slides indexOfObject:activeSlide] inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)updatedSlideText:(SlideText *)slideText {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.slideshow.slides indexOfObject:activeSlide] inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

// UIMenuController requires that we can become first responder or it won't display
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)slideDoubleTap:(UITapGestureRecognizer*)gestureRecognizer {
    CGPoint loc = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForRowAtPoint:loc];
    [self playSlideshow:@(selectedIndexPath.row)];
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

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    [self redrawSlideshow];
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return self.slideshow.photos.count;
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
    Photo *photo = [self.slideshow.photos objectAtIndex:indexPath.item];
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
    CGPoint photoLoc;
    if (IDIOM == IPAD || landscape){
        photoLoc = CGPointMake(loc.x - kSidebarWidth, loc.y + self.collectionView.contentOffset.y);
    } else {
        photoLoc = CGPointMake(loc.x, loc.y + self.collectionView.contentOffset.y);
    }
    CGPoint slideLoc = CGPointMake(loc.x, loc.y + self.tableView.contentOffset.y);
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        //NSLog(@"loc x: %f, loc y: %f", loc.x,loc.y);
        
        BOOL iPadBool = (loc.x > kSidebarWidth && self.slideshow.photos.count);
        
        if ((IDIOM == IPAD && iPadBool) || (IDIOM != IPAD && self.slideshow.photos.count)) {
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
            if (self.slideStartIndex && self.slideStartIndex.section != 1) {
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
                    [self addSlideIntoSidebar];
                    return;
                } else {
                    // adding to existing slide
                    Slide *slide = [self.slideshow.slides objectAtIndex:indexPathForSlideCell.row];
                    
                    PhotoSlide *photoSlide = [PhotoSlide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    [photoSlide setPhoto:self.selectedPhoto];
                    if (!slide.photos.count){
                        [slide addPhotoSlide:photoSlide];
                    } else if (loc.x > (kSidebarWidth/2) && slide.photos.count){
                        [slide replacePhotoSlideAtIndex:1 withPhotoSlide:photoSlide];
                    } else {
                        [slide replacePhotoSlideAtIndex:0 withPhotoSlide:photoSlide];
                    }
                
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        [self.tableView reloadRowsAtIndexPaths:@[indexPathForSlideCell] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }];
                    [self endPressAnimation];
                    return;
                }
            } else if (loc.y > self.tableView.contentSize.height && loc.x < kSidebarWidth){
                [self addSlideIntoSidebar];
                return;
            }
        }
        
        if (self.draggingView) {
            if (_selectedPhoto){
                if (loc.x > kSidebarWidth)  {
                    if (loc.y <= 0 || loc.y >= (self.view.frame.size.height - 23.f)){
                        [self removePhoto];
                        //[self confirmRemovePhoto];
                    } else if (loc.x >= (self.view.frame.size.width - 23.f)){
                        [self removePhoto];;
                        //[self confirmRemovePhoto];
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
                        //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                        [self.tableView reloadData];
                        [self.draggingView removeFromSuperview];
                        self.draggingView = nil;
                        self.slideStartIndex = nil;
                    }];
                } else {  // reorder the slides
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
                        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait]; // make sure to save the new order
                        
                        [UIView animateWithDuration:.23f animations:^{
                            self.draggingView.transform = CGAffineTransformIdentity;
                        } completion:^(BOOL finished) {
                            //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
                            [self.tableView reloadData];
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

- (void)addSlideIntoSidebar {
    Slide *slide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    PhotoSlide *photoSlide = [PhotoSlide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [photoSlide setPhoto:self.selectedPhoto];
    
    [slide addPhotoSlide:photoSlide];
    [slide setIndex:@(self.slideshow.slides.count)];
    [self.tableView beginUpdates];
    [self.slideshow addSlide:slide atIndex:slide.index.integerValue];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(slide.index.integerValue) inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }];
    [self endPressAnimation];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    width = size.width;
    height = size.height;
    landscape = size.width > size.height ? YES : NO;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (IDIOM != IPAD){
            if (landscape){
                CGRect tableFrame = self.tableView.frame;
                tableFrame.origin.x = 0;
                tableFrame.size.width = width/2;
                [self.tableView setFrame:tableFrame];
                
                CGRect collectionFrame = self.collectionView.frame;
                collectionFrame.origin.x = width/2;
                collectionFrame.size.width = width/2;
                [self.collectionView setFrame:collectionFrame];
            } else {
                CGRect tableFrame = self.tableView.frame;
                tableFrame.origin.x = 0;
                tableFrame.size.width = 0;
                [self.tableView setFrame:tableFrame];
                
                CGRect collectionFrame = self.collectionView.frame;
                collectionFrame.origin.x = 0;
                collectionFrame.size.width = width;
                [self.collectionView setFrame:collectionFrame];
            }
            
            [self.collectionView reloadData];
            [self.tableView reloadData];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
}

- (void)adjustForSize:(CGSize)size {
    if (size.width > size.height){
        
    } else {
        
    }
}

- (void)confirmRemovePhoto {
    removePhotoAlertView = [[UIAlertView alloc] initWithTitle:@"Please confirm" message:[NSString stringWithFormat:@"Are you sure you want to remove \"%@\" from this slideshow?",self.selectedPhoto.art.title] delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove",nil];
    removePhotoAlertView.delegate = self;
    [removePhotoAlertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == removePhotoAlertView){
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Remove"]){
            [self removePhoto];
        } else {
            [self endPressAnimation];
        }
    }
}

- (void)removePhoto {
    [self.slideshow removePhoto:self.selectedPhoto];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[self.photoStartIndex]];
    } completion:^(BOOL finished) {
        
    }];
    [self removePhotoAnimation];
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
    WFSaveMenuViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SaveMenu"];
    vc.saveDelegate = self;
    if (IDIOM == IPAD){
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        vc.preferredContentSize = CGSizeMake(230, 128);
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:saveButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else {
        [self resetTransitionBooleans];
        transparentBG = YES;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    }
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
    if (self.mainRequest) return;
    
    if (self.popover) [self.popover dismissPopoverAnimated:YES];
    if (titleTextField.isEditing) [titleTextField resignFirstResponder];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    if (self.slideshow.title.length){
        [parameters setObject:self.slideshow.title forKey:@"title"];
    }
    if (self.slideshow.slideshowDescription.length){
        [parameters setObject:self.slideshow.slideshowDescription forKey:@"description"];
    }
    [parameters setObject:self.slideshow.showTitleSlide forKey:@"show_title_slide"];
    [parameters setObject:self.slideshow.showMetadata forKey:@"show_metadata"];
    
    NSMutableArray *slideshowPhotoArray = [NSMutableArray arrayWithCapacity:self.slideshow.photos.count];
    [self.slideshow.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
        [slideshowPhotoArray addObject:photo.identifier];
    }];
    [parameters setObject:slideshowPhotoArray forKey:@"photo_ids"];
    
    [self.slideshow.slides enumerateObjectsUsingBlock:^(Slide *slide, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *slideObject = [NSMutableDictionary dictionary];
        if (slide && ![slide.identifier isEqualToNumber:@0]){
            [slideObject setObject:slide.identifier forKey:@"slide_id"];
        }
        if (slide.photoSlides.count){
            NSMutableArray *photoSlides = [NSMutableArray arrayWithCapacity:slide.photoSlides.count];
            [slide.photoSlides enumerateObjectsUsingBlock:^(PhotoSlide *photoSlide, NSUInteger idx, BOOL *stop) {
                NSMutableDictionary *photoSlideObject = [NSMutableDictionary dictionary];
                [photoSlideObject setObject:photoSlide.photo.identifier forKey:@"photo_id"];
                if (photoSlide.positionX)[photoSlideObject setObject:photoSlide.positionX forKey:@"position_x"];
                if (photoSlide.positionY)[photoSlideObject setObject:photoSlide.positionY forKey:@"position_y"];
                if (photoSlide.width)[photoSlideObject setObject:photoSlide.width forKey:@"width"];
                if (photoSlide.height)[photoSlideObject setObject:photoSlide.height forKey:@"height"];
                [photoSlideObject setObject:@(idx) forKey:@"index"]; // how the photo slides are ordered
                [photoSlides addObject:photoSlideObject];
            }];
            [slideObject setObject:photoSlides forKey:@"photo_slides"];
        } else if (slide.slideTexts.count){
            NSMutableArray *slideTexts = [NSMutableArray arrayWithCapacity:slide.slideTexts.count];
            [slide.slideTexts enumerateObjectsUsingBlock:^(SlideText *slideText, NSUInteger idx, BOOL *stop) {
                NSMutableDictionary *slideTextDict = [NSMutableDictionary dictionary];
                if (![slideText.identifier isEqualToNumber:@0]){
                    [slideTextDict setObject:slideText.identifier forKey:@"id"];
                }
                if (slideText.body.length){
                    [slideTextDict setObject:slideText.body forKey:@"body"];
                }

                [slideTexts addObject:slideTextDict];
            }];
            [slideObject setObject:slideTexts forKey:@"slide_texts"];
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
        
        self.mainRequest = [manager POST:[NSString stringWithFormat:@"slideshows"] parameters:@{@"slideshow":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success creating a slideshow: %@",responseObject);
            [self.slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (self.lightTable){
                    [self lightTableSelected:self.lightTable];
                } else {
                    [ProgressHUD dismiss];
                }
                if (self.slideshowDelegate && [self.slideshowDelegate respondsToSelector:@selector(slideshowCreated:)]){
                    [self.slideshowDelegate slideshowCreated:self.slideshow];
                }
                self.mainRequest = nil;
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to create a slideshow: %@",error.description);
            [WFAlert show:@"Sorry, but something went wrong while saving your slideshow to the cloud.\n\nWe've saved it locally in the meantime." withTime:3.7f];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            [ProgressHUD dismiss];
            self.mainRequest = nil;
        }];
    } else {
        [ProgressHUD show:@"Saving..."];
        self.mainRequest = [manager PATCH:[NSString stringWithFormat:@"slideshows/%@",self.slideshow.identifier] parameters:@{@"slideshow":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success saving a slideshow: %@",responseObject);
            [self.slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                [self.collectionView reloadData];
                [self.tableView reloadData];
                [WFAlert show:@"Saved" withTime:3.7f];
                self.mainRequest = nil;
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to save a slideshow: %@",error.description);
            [WFAlert show:@"Sorry, but something went wrong while saving your slideshow to the cloud.\n\nWe've saved it locally in the meantime." withTime:3.7f];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            [ProgressHUD dismiss];
            self.mainRequest = nil;
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
    WFLightTablesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"LightTables"];
    vc.lightTableDelegate = self;
    vc.slideshowShareMode = YES;
    [vc setSlideshow:self.slideshow];
    [vc setLightTables:self.currentUser.lightTables.array.mutableCopy];
    if (IDIOM == IPAD){
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        CGFloat vcHeight = self.currentUser.lightTables.count*54.f > 260.f ? 260 : (self.currentUser.lightTables.count)*54.f;
        vc.preferredContentSize = CGSizeMake(420, vcHeight + 34.f); // add the header height
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:shareButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self resetTransitionBooleans];
        transparentBG = YES;
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    }
}

- (void)lightTableSelected:(LightTable *)l {
    LightTable *lightTable = [l MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    
    if ([self.slideshow.identifier isEqualToNumber:@0]){
        self.lightTable = lightTable;
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

- (void)lightTableDeselected:(LightTable *)l {
    LightTable *lightTable = [l MR_inContext:[NSManagedObjectContext MR_defaultContext]];
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

- (void)shareToLightTable:(LightTable*)lightTable {
    [lightTable addSlideshow:self.slideshow];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
       
    }];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    [parameters setObject:self.slideshow.identifier forKey:@"slideshow_id"];
    [manager POST:[NSString stringWithFormat:@"light_tables/%@/add_slideshow",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success adding slideshow to light table: %@",responseObject);
        [WFAlert show:[NSString stringWithFormat:@"\"%@\" dropped to \"%@\"",self.slideshow.title, lightTable.name] withTime:3.3f];
        if (self.slideshowDelegate && [self.slideshowDelegate respondsToSelector:@selector(slideshow:droppedToLightTable:)]){
            [self.slideshowDelegate slideshow:self.slideshow droppedToLightTable:lightTable];
        }
        [ProgressHUD dismiss];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to add slideshow to light table: %@",error.description);
        [WFAlert show:@"Sorry, but something went wrong while trying to share this slideshow.\n\nPlease try again soon." withTime:3.3f];
        [ProgressHUD dismiss];
    }];
}

- (void)startSearch {
    WFSearchResultsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SearchResults"];
    [vc setSlideshowPhotos:self.slideshow.photos.mutableCopy];
    vc.shouldShowSearchBar = YES;
    vc.shouldShowTiles = YES;
    vc.searchDelegate = self;
    if (IDIOM == IPAD){
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        vc.preferredContentSize = CGSizeMake(400, 500);
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        self.popover.delegate = self;
        [self.popover setBackgroundColor:[UIColor blackColor]];
        [self.popover presentPopoverFromBarButtonItem:searchButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    }
}

- (void)searchDidSelectPhoto:(Photo *)p {
    Photo *photo = [p MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    self.slideshow = [self.slideshow MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    
    BOOL add; NSIndexPath *indexPathToReload;
    if ([self.slideshow.photos containsObject:photo]){
        indexPathToReload = [NSIndexPath indexPathForItem:[self.slideshow.photos indexOfObject:photo] inSection:0];
        [self.slideshow removePhoto:photo];
        add = NO;
    } else {
        [self.slideshow addPhoto:photo];
        indexPathToReload = [NSIndexPath indexPathForItem:0 inSection:0];
        add = YES;
    }
    
    NSLog(@"slideshow photo count: %lu",(unsigned long)self.slideshow.photos.count);
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (IDIOM == IPAD){
            [self.collectionView performBatchUpdates:^{
                if (add){
                    [self.collectionView insertItemsAtIndexPaths:@[indexPathToReload]];
                } else {
                    [self.collectionView deleteItemsAtIndexPaths:@[indexPathToReload]];
                }
            } completion:^(BOOL finished) {
                if (add) [self.collectionView scrollToItemAtIndexPath:indexPathToReload atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
            }];
        } else {
            [self.collectionView reloadData];
        }
    }];
}

- (void)endSearch {
    [self.view endEditing:YES];
    [self.popover dismissPopoverAnimated:YES];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popover = nil; // ensure it's really gone
}

- (void)showSettings {
    WFSlideshowSettingsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideshowSettings"];
    vc.settingsDelegate = self;
    [vc setSlideshow:self.slideshow];
    if (IDIOM == IPAD){
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        vc.preferredContentSize = CGSizeMake(270, 162); // height is 54 * 2
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:settingsButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self resetTransitionBooleans];
        transparentBG = YES;
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    }
}

- (void)didUpdateSlideshow {
    [self save];
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
}

- (void)didDeleteSlideshow {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    [self deleteSlideshow];
}

- (void)playSlideshowFromStart{
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    [self playSlideshow:nil];
}

- (void)resetTransitionBooleans {
    showMetadata = NO;
    showSlideshow = NO;
    transparentBG = NO;
}

- (void)playSlideshow:(NSNumber*)startIndex {
    if (self.slideshow.slides.count){
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        [self resetTransitionBooleans];
        showSlideshow = YES;
        
        WFSlideshowViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Slideshow"];
        [vc setStartIndex:startIndex];
        [vc setSlideshow:self.slideshow];
        
        if (IDIOM == IPAD){
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            nav.transitioningDelegate = self;
            nav.modalPresentationStyle = UIModalPresentationCustom;
            [self presentViewController:nav animated:YES completion:^{
                
            }];
        } else {
            WFNoRotateNavController *nav = [[WFNoRotateNavController alloc] initWithRootViewController:vc];
            NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .5f * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self presentViewController:nav animated:YES completion:^{
                    
                }];
            });
        }
    
    } else {
        [WFAlert show:@"Remember to add at least one slide before playing your slideshow." withTime:3.3f];
    }
}

- (void)showMetadata:(Photo*)photo{
    WFArtMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ArtMetadata"];
    [vc setPhoto:photo];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self resetTransitionBooleans];
    nav.view.clipsToBounds = YES;
    if (IDIOM == IPAD){
        showMetadata = YES;
    } else {
        transparentBG = YES;
    }
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)dismissMetadata {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    if (showSlideshow){
        [self cancelAutosave];
        WFSlideshowFocusAnimator *animator = [WFSlideshowFocusAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (transparentBG){
        WFTransparentBGModalAnimator *animator = [WFTransparentBGModalAnimator new];
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
    } else if (transparentBG){
        WFTransparentBGModalAnimator *animator = [WFTransparentBGModalAnimator new];
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

- (void)saveSlideshowWithUI:(BOOL)showHUD {
    if (showHUD) [ProgressHUD show:@"Saving..."];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        //NSLog(@"Success saving slideshow? %u",success);
        [ProgressHUD dismiss];
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
        if (self.slideshowDelegate && [self.slideshowDelegate respondsToSelector:@selector(shouldReloadSlideshows)]){
            [self.slideshowDelegate shouldReloadSlideshows];
        }
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
    [self saveSlideshowWithUI:NO];
}

- (void)cancelAutosave {
    NSLog(@"cancel autosave");
    [saveTimer invalidate];
    saveTimer = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self cancelAutosave];
    if (!self.slideshow.slides.count && !self.slideshow.photos.count && !self.slideshow.title.length){
        [self.slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [self saveSlideshowWithUI:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
