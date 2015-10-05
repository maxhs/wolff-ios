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
#import "WFPhotoTileCell.h"
#import "WFArtMetadataAnimator.h"
#import "WFArtMetadataViewController.h"
#import "WFSlideshowSettingsViewController.h"
#import "WFInteractiveImageView.h"
#import "WFSaveMenuViewController.h"
#import "WFAlert.h"
#import "WFLightTablesViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "WFSlideTextViewController.h"
#import "WFUtilities.h"
#import "WFNoRotateNavController.h"
#import "WFTransparentBGModalAnimator.h"
#import "WFTracking.h"

NSString* const shareOption = @"Share";
NSString* const searchOption = @"Select images";
NSString* const saveOption = @"Save";
NSString* const settingsOption = @"Settings";
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
@property (strong, nonatomic) SlideshowPhoto *selectedSlideshowPhoto;
@property (strong, nonatomic) Slide *selectedSlide;
@property (strong, nonatomic) LightTable *lightTable;
@property (nonatomic) WFInteractiveImageView *draggingView;
@property (nonatomic) CGPoint dragViewStartLocation;
@property (nonatomic) NSIndexPath *photoStartIndex;
@property (nonatomic) NSIndexPath *photoMoveToIndexPath;
@property (nonatomic) NSIndexPath *slideStartIndex;
@property (nonatomic) NSIndexPath *slideMoveToIndexPath;
@property (strong, nonatomic) AFHTTPRequestOperation *mainRequest;
@property (strong, nonatomic) AFHTTPRequestOperation *deleteRequest;

@end

@implementation WFSlideshowSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    width = screenWidth();
    height = screenHeight();
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
        self.slideshow = [Slideshow MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
        self.slideshow.owner = self.currentUser;
        
        //add photos to slideshow
        [self.selectedPhotos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL * stop) {
            SlideshowPhoto *slideshowPhoto = [SlideshowPhoto MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
            slideshowPhoto.slideshow = self.slideshow;
            slideshowPhoto.photo = [photo MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        }];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        
        [self setUpTitleView];
        [self setUpNavButtons];
        [self redrawSlideshow];
        [titleTextField becomeFirstResponder];
        [self.collectionView setUserInteractionEnabled:YES];
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
    
    topInset = self.navigationController.navigationBar.frame.size.height; // manually set the top inset
    self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
    [self.tableView setContentOffset:CGPointMake(0, -topInset)];
    [self.collectionView setBackgroundColor:[UIColor whiteColor]];
    if (IDIOM != IPAD){
        [self.tableView setFrame:CGRectMake(0, 0, kSidebarWidth, height)];
        [self.collectionView setFrame:CGRectMake(kSidebarWidth, 0, width-kSidebarWidth, height)];
    }
    
    NSMutableDictionary *trackingParameters = [WFTracking generateTrackingPropertiesForSlideshow:self.slideshow];
    [WFTracking trackEvent:@"Slideshow Make View" withProperties:trackingParameters];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
    
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
            } else if ([self.slideshow.owner.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
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
    UIActionSheet *slideshowOptions = [[UIActionSheet alloc] initWithTitle:@"Your slideshow options"
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:searchOption, saveOption, shareOption, settingsOption, playOption, nil];
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
    if (self.slideshow.slideshowPhotos.count){
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
    Slide *newSlide = [Slide MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
    [newSlide setSlideshow:[self.slideshow MR_inContext:[NSManagedObjectContext MR_defaultContext]]];
    NSIndexPath *indexPathForNewSlide = [NSIndexPath indexPathForRow:self.slideshow.slides.count-1 inSection:0];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPathForNewSlide] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:NULL];
}

// only applies to left tableView
- (void)slideSingleTap:(UITapGestureRecognizer*)gestureRecognizer {
    CGPoint loc = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForRowAtPoint:loc];
    
    if (selectedIndexPath.section == 0 && self.slideshow.slides.count){
        [self becomeFirstResponder];
        activeIndexPath = selectedIndexPath;
        activeSlide = self.slideshow.slides[selectedIndexPath.row];
        
        WFSlideTableCell *cell = (WFSlideTableCell*)[self.tableView cellForRowAtIndexPath:selectedIndexPath];
        if (activeSlide.photoSlides.count > 1){
            activeImageView = loc.x <= 150.f ? cell.artImageView2 : cell.artImageView3;
        } else if (activeSlide.photoSlides.count) {
            activeImageView = cell.artImageView1;
        }
        
        NSString *addTextItemTitle = NSLocalizedString(@"Add text", @"Add text to slide");
        UIMenuItem *addTextItem = [[UIMenuItem alloc] initWithTitle:addTextItemTitle action:@selector(addText:)];
        NSString *editTextItemTitle = NSLocalizedString(@"Edit text", @"Edit slide text");
        UIMenuItem *editTextItem = [[UIMenuItem alloc] initWithTitle:editTextItemTitle action:@selector(editText:)];
        NSString *removeItemTitle = NSLocalizedString(@"Remove", @"Remove art from slide");
        UIMenuItem *removeMenuItem = [[UIMenuItem alloc] initWithTitle:removeItemTitle action:@selector(removeArt:)];
        NSString *newSlideTitle = NSLocalizedString(@"Add blank slide", @"Add a new slide");
        UIMenuItem *newSlideMenuItem = [[UIMenuItem alloc] initWithTitle:newSlideTitle action:@selector(newSlide:)];
        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        if (activeSlide.photoSlides.count){
            [menuController setMenuItems:@[removeMenuItem, newSlideMenuItem]];
        } else if (activeSlide.slideTexts.count) {
            [menuController setMenuItems:@[removeMenuItem, editTextItem, newSlideMenuItem]];
        } else {
            [menuController setMenuItems:@[removeMenuItem, addTextItem, newSlideMenuItem]];
        }
        
        CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
        CGRect menuLocation = CGRectMake(location.x, location.y, 0, 0);
        [menuController setTargetRect:menuLocation inView:[gestureRecognizer view]];
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (void)removeArt:(UIMenuController*)menuController {
    if (!activeSlide) return;
    
    NSPredicate *photoSlidePredicate = [NSPredicate predicateWithFormat:@"slide.identifier == %@ and photo.identifier == %@",activeSlide.identifier, activeImageView.photo.identifier];
    PhotoSlide *photoSlide = [PhotoSlide MR_findFirstWithPredicate:photoSlidePredicate inContext:[NSManagedObjectContext MR_defaultContext]];

    if (photoSlide){
        [activeSlide removePhotoSlide:photoSlide];
    }
    
    if (activeSlide.photoSlides.count){
//        [self.tableView beginUpdates];
//        [self.tableView reloadRowsAtIndexPaths:@[activeIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//        [self.tableView endUpdates];
    } else {
        [self.slideshow removeSlide:activeSlide fromIndex:activeSlide.index.integerValue];
        [activeSlide MR_deleteEntityInContext:[NSManagedObjectContext MR_defaultContext]];
//        [self.tableView beginUpdates];
//        [self.tableView deleteRowsAtIndexPaths:@[activeIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//        [self.tableView endUpdates];
        activeSlide = nil;
    }

    [self.tableView reloadData];
    activeImageView = nil;
    activeIndexPath = nil;
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:NULL];
}

- (void)newSlide:(UIMenuController*)menuController {
    Slide *newSlide = [Slide MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
//    NSIndexPath *indexPathToInsert = [NSIndexPath indexPathForRow:activeSlide.index.integerValue + 1 inSection:0];
    [self.slideshow addSlide:newSlide atIndex:activeSlide.index.integerValue + 1];
    
//    [self.tableView beginUpdates];
//    [self.tableView insertRowsAtIndexPaths:@[indexPathToInsert] withRowAnimation:UITableViewRowAnimationAutomatic];
//    [self.tableView endUpdates];
//    [self redrawSlideshowWithDelay];
    
    [self.tableView reloadData];
    activeImageView = nil;
    activeIndexPath = nil;
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
    [self.tableView reloadData];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.slideshow.slides indexOfObject:activeSlide] inSection:0];
//    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//    [self redrawSlideshowWithDelay];
}

- (void)updatedSlideText:(SlideText *)slideText {
    [self.tableView reloadData];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.slideshow.slides indexOfObject:activeSlide] inSection:0];
//    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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
        CGFloat newWidth = ((width-kSidebarWidth)/2)-1;
        return CGSizeMake(newWidth,newWidth);
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
    return self.slideshow.slideshowPhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SlideshowPhoto *slideshowPhoto = self.slideshow.slideshowPhotos[indexPath.item];
    if (IDIOM == IPAD){
        WFPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SlideshowArtCell" forIndexPath:indexPath];
        [cell.contentView setAlpha:1.0];
        [cell configureForPhoto:slideshowPhoto.photo];
        return cell;
    } else {
        WFPhotoTileCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SlideshowArtCell" forIndexPath:indexPath];
        [cell.contentView setAlpha:1.0];
        [cell configureForPhoto:slideshowPhoto.photo];
        return cell;
    }
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
    Photo *photo = [(SlideshowPhoto*)[self.slideshow.slideshowPhotos objectAtIndex:indexPath.item] photo];
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
        
        if (loc.x > kSidebarWidth && self.slideshow.slideshowPhotos.count) {
            // user has a slide from the slideshow light box
            self.photoStartIndex = [self.collectionView indexPathForItemAtPoint:photoLoc];
            if (self.photoStartIndex && self.photoStartIndex.item < self.slideshow.slideshowPhotos.count) {
                self.selectedSlideshowPhoto = self.slideshow.slideshowPhotos[self.photoStartIndex.item];
                
                if (IDIOM == IPAD){
                    WFPhotoCell *cell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.photoStartIndex];
                    self.draggingView = [[WFInteractiveImageView alloc] initWithImage:[cell getRasterizedImageCopy] andPhoto:self.selectedSlideshowPhoto.photo];
                    [cell.contentView setAlpha:0.1f];
                } else {
                    WFPhotoTileCell *cell = (WFPhotoTileCell*)[self.collectionView cellForItemAtIndexPath:self.photoStartIndex];
                    self.draggingView = [[WFInteractiveImageView alloc] initWithImage:[cell getRasterizedImageCopy] andPhoto:self.selectedSlideshowPhoto.photo];
                    [cell.contentView setAlpha:0.1f];
                }
                
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
            // user has a slide from the make slideshow tableView
            self.slideStartIndex = [self.tableView indexPathForRowAtPoint:slideLoc];
            if (self.slideStartIndex && self.slideStartIndex.section != 1 && self.slideStartIndex.row < self.slideshow.slides.count) {
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
        
        if (self.selectedSlideshowPhoto){
            if (indexPathForSlideCell){
                //cell was dropped in the left sidebar
                
                if (indexPathForSlideCell.section == 1){
                    // this means we should add a new slide
                    [self addSlideIntoSidebar];
                    
                    return;
                } else if (indexPathForSlideCell.row < self.slideshow.slides.count) {
                    // adding to existing slide
                    Slide *slide = [self.slideshow.slides objectAtIndex:indexPathForSlideCell.row];
                    
                    //dont do anything if it's already got text
                    if (slide.slideTexts.count){
                        [self endPressAnimation];
                        return;
                    }
                    
                    PhotoSlide *photoSlide = [PhotoSlide MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
                    [photoSlide setPhoto:self.selectedSlideshowPhoto.photo];
                    if (!slide.photos.count){
                        [slide addPhotoSlide:photoSlide];
                    } else if (loc.x > (kSidebarWidth/2) && slide.photos.count){
                        [slide replacePhotoSlideAtIndex:1 withPhotoSlide:photoSlide];
                    } else {
                        [slide replacePhotoSlideAtIndex:0 withPhotoSlide:photoSlide];
                    }
                    [self.tableView reloadData];
                    [self endPressAnimation];
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                    return;
                }
            } else if (loc.y > self.tableView.contentSize.height && loc.x < kSidebarWidth){
                [self addSlideIntoSidebar];
                return;
            }
        }
        
        if (self.draggingView) {
            if (self.selectedSlideshowPhoto){
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
    // create the slide and fill it up with delicious photos
    PhotoSlide *photoSlide = [PhotoSlide MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
    [photoSlide setPhoto:self.selectedSlideshowPhoto.photo];
    Slide *slide = [Slide MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
    [slide addPhotoSlide:photoSlide];
    [slide setIndex:@(self.slideshow.slides.count)];
    [self.slideshow addSlide:slide atIndex:slide.index.integerValue];
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self.tableView reloadData];
    [self endPressAnimation];
}

- (BOOL)shouldAutorotate {
    return NO;
}

//- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//    width = size.width;
//    height = size.height;
//    landscape = size.width > size.height ? YES : NO;
//    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//        if (IDIOM != IPAD){
//            if (landscape){
//                CGRect tableFrame = self.tableView.frame;
//                tableFrame.origin.x = 0;
//                tableFrame.size.width = width/2;
//                [self.tableView setFrame:tableFrame];
//                
//                CGRect collectionFrame = self.collectionView.frame;
//                collectionFrame.origin.x = width/2;
//                collectionFrame.size.width = width/2;
//                [self.collectionView setFrame:collectionFrame];
//            } else {
//                CGRect tableFrame = self.tableView.frame;
//                tableFrame.origin.x = 0;
//                tableFrame.size.width = 0;
//                [self.tableView setFrame:tableFrame];
//                
//                CGRect collectionFrame = self.collectionView.frame;
//                collectionFrame.origin.x = 0;
//                collectionFrame.size.width = width;
//                [self.collectionView setFrame:collectionFrame];
//            }
//            
//            [self.collectionView reloadData];
//            [self.tableView reloadData];
//        }
//    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
//        
//    }];
//}

- (void)confirmRemovePhoto {
    removePhotoAlertView = [[UIAlertView alloc] initWithTitle:@"Please confirm" message:[NSString stringWithFormat:@"Are you sure you want to remove \"%@\" from this slideshow?",self.selectedSlideshowPhoto.photo.art.title] delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Remove",nil];
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
    [self.slideshow removeSlideshowPhoto:self.selectedSlideshowPhoto];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[self.photoStartIndex]];
    } completion:^(BOOL finished) {
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:NULL];
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
    self.selectedSlideshowPhoto = nil;
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

- (NSMutableDictionary *)generateParameters {
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
    
    NSMutableArray *slideshowPhotoArray = [NSMutableArray arrayWithCapacity:self.slideshow.slideshowPhotos.count];
    [self.slideshow.slideshowPhotos enumerateObjectsUsingBlock:^(SlideshowPhoto *slideshowPhoto, NSUInteger idx, BOOL *stop) {
        [slideshowPhotoArray addObject:slideshowPhoto.photo.identifier];
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
                [slideTextDict setObject:slideText.alignment forKey:@"alignment"];
                [slideTexts addObject:slideTextDict];
            }];
            [slideObject setObject:slideTexts forKey:@"slide_texts"];
        } else {
            [slideObject setObject:@"" forKey:@"text"];
        }
        
        [parameters setObject:slideObject forKey:[NSString stringWithFormat:@"slides[%lu]",(unsigned long)idx]];
    }];
    return parameters;
}

- (void)post {
    if (self.mainRequest || !self.slideshow) return;
    if (self.popover) [self.popover dismissPopoverAnimated:YES];
    if (titleTextField.isEditing) [titleTextField resignFirstResponder];
    
    NSDictionary *parameters = [self generateParameters];
    
    if ([self.slideshow.identifier isEqualToNumber:@0]){
        [ProgressHUD show:self.slideshow.title.length ? [NSString stringWithFormat:@"Creating \"%@\"...",self.slideshow.title] : @"Creating your slideshow..."];
        
        self.mainRequest = [manager POST:[NSString stringWithFormat:@"slideshows"] parameters:@{@"slideshow":parameters,@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success creating a slideshow: %@",responseObject);
            [self.slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
            self.mainRequest = nil;
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            if (self.lightTable){
                [self lightTableSelected:self.lightTable];
            } else {
                [ProgressHUD dismiss];
            }
            [WFAlert show:[NSString stringWithFormat:@"\"%@\" created",self.slideshow.title] withTime:3.7f];
            if (self.slideshowDelegate && [self.slideshowDelegate respondsToSelector:@selector(slideshowCreated:)]){
                [self.slideshowDelegate slideshowCreated:self.slideshow];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to create a slideshow: %@",error.description);
            [WFAlert show:@"Sorry, but something went wrong while saving your slideshow to the cloud.\n\nWe've saved it locally in the meantime." withTime:3.7f];
            
            [ProgressHUD dismiss];
            self.mainRequest = nil;
        }];
    } else {
        [ProgressHUD show:@"Saving..."];
        self.mainRequest = [manager PATCH:[NSString stringWithFormat:@"slideshows/%@",self.slideshow.identifier] parameters:@{@"slideshow":parameters, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success saving a slideshow: %@",responseObject);
            [self.slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
            
            [ProgressHUD dismiss];
            [WFAlert show:[NSString stringWithFormat:@"\"%@\" saved",self.slideshow.title] withTime:3.7f];
            [self.tableView reloadData];
            [self.collectionView reloadData];
            self.mainRequest = nil;
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
    NSLog(@"Should be cloud downloading");
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
            [WFAlert show:[NSString stringWithFormat:@"Dropped to \"%@\"",lightTable.name] withTime:2.7f];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:NULL];
        }
    }
}

- (void)lightTableDeselected:(LightTable *)l {
    LightTable *lightTable = [l MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    if (lightTable.identifier && ![lightTable.identifier isEqualToNumber:@0]){
        if (self.deleteRequest) return;
        
        [lightTable removeSlideshow:self.slideshow];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [parameters setObject:self.slideshow.identifier forKey:@"slideshow_id"];
        self.deleteRequest = [manager DELETE:[NSString stringWithFormat:@"light_tables/%@/remove_slideshow",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success removing slideshow from light table: %@",responseObject);
            [WFAlert show:[NSString stringWithFormat:@"\"%@\" removed from \"%@\"",self.slideshow.title, lightTable.name] withTime:3.3f];
            [ProgressHUD dismiss];
            self.deleteRequest = nil;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to remove slideshow from light table: %@",error.description);
            [WFAlert show:@"Sorry, but something went wrong while trying to unshare this slideshow.\n\nPlease try again soon." withTime:3.3f];
            [ProgressHUD dismiss];
            self.deleteRequest = nil;
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
    NSMutableOrderedSet *photos = [NSMutableOrderedSet orderedSet];
    [self.slideshow.slideshowPhotos enumerateObjectsUsingBlock:^(SlideshowPhoto *slideshowPhoto, NSUInteger idx, BOOL * stop) {
        [photos addObject:slideshowPhoto.photo];
    }];
    [vc setSlideshowPhotos:photos];
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
        [self presentViewController:nav animated:YES completion:NULL];
    }
}

- (void)searchDidSelectPhoto:(Photo *)p {
    Photo *photo = [p MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    self.slideshow = [self.slideshow MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"slideshow.identifier == %@ and photo.identifier == %@",self.slideshow.identifier, photo.identifier];
    SlideshowPhoto *slideshowPhoto = [SlideshowPhoto MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
    
    if (slideshowPhoto){
        [self.slideshow removeSlideshowPhoto:slideshowPhoto];
    } else {
        slideshowPhoto = [SlideshowPhoto MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
        slideshowPhoto.slideshow = self.slideshow;
        slideshowPhoto.photo = photo;
    }
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [self.collectionView reloadData];
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
        [self presentViewController:nav animated:YES completion:NULL];
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
            [self presentViewController:nav animated:YES completion:NULL];
        } else {
            WFNoRotateNavController *nav = [[WFNoRotateNavController alloc] initWithRootViewController:vc];
            NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .5f * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self presentViewController:nav animated:YES completion:NULL];
            });
        }
    
    } else {
        [WFAlert show:@"Remember to add at least one slide before playing your slideshow." withTime:3.3f];
    }
}

- (void)showMetadata:(Photo*)photo{
    WFArtMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ArtMetadata"];
    [vc setPhoto:photo];
    UINavigationController *nav;
    if (IDIOM == IPAD){
        [self resetTransitionBooleans];
        showMetadata = YES;
        nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        nav.view.clipsToBounds = YES;
    } else {
        nav = [[WFNoRotateNavController alloc] initWithRootViewController:vc];
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
    
    [self presentViewController:nav animated:YES completion:NULL];
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
        self.slideshow = [self.slideshow MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        if (titleTextField.text.length){
            [textField setBackgroundColor:[UIColor colorWithWhite:1 alpha:0]];
            [self.slideshow setTitle:titleTextField.text];
        } else {
            [textField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.06]];
            [self.slideshow setTitle:@""];
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
        if (showHUD) [ProgressHUD dismiss];
    }];
}

- (void)deleteSlideshow {
    if (self.deleteRequest) return;
    [ProgressHUD show:@"Deleting..."];
    
    self.deleteRequest = [manager DELETE:[NSString stringWithFormat:@"slideshows/%@",self.slideshow.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success deleting this slideshow: %@",responseObject);
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
    [self.slideshow MR_deleteEntityInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (self.slideshowDelegate && [self.slideshowDelegate respondsToSelector:@selector(shouldReloadSlideshows)]){
            [self.slideshowDelegate shouldReloadSlideshows];
        }
        [ProgressHUD dismiss];
        [self dismiss];
        self.deleteRequest = nil;
    }];
}

- (void)willHideEditMenu:(id)sender {
    
}

- (void)didHideEditMenu:(id)sender {
    [self resignFirstResponder];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.popover && self.popover.isPopoverVisible){
        [self.popover dismissPopoverAnimated:YES];
    }
    [self saveSlideshowWithUI:NO];
    if (self.mainRequest) [self.mainRequest cancel];
}

- (void)cancelAutosave {
    [saveTimer invalidate];
    saveTimer = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self cancelAutosave];
    if (!self.slideshow.slides.count && !self.slideshow.slideshowPhotos.count && !self.slideshow.title.length){
        [self.slideshow MR_deleteEntityInContext:[NSManagedObjectContext MR_defaultContext]];
        [self saveSlideshowWithUI:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
