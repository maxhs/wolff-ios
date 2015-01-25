//
//  WFSlideshowSplitViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFAppDelegate.h"
#import "WFSlideshowSplitViewController.h"
#import "WFSlideCollectionCell.h"
#import "WFSlideTableCell.h"
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
#import "WFTablesViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface WFSlideshowSplitViewController () <UIViewControllerTransitioningDelegate, WFSearchDelegate,WFSlideshowSettingsDelegate, UIPopoverControllerDelegate,  UITextFieldDelegate, UIAlertViewDelegate, WFImageViewDelegate, WFSaveSlideshowDelegate, WFLightTablesDelegate> {
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
    Photo *selectedPhoto;
    Slide *selectedSlide;
    UIAlertView *titlePrompt;
    UIAlertView *artImageViewPrompt;
    
    NSIndexPath *activeIndexPath;
    Slide *activeSlide;
    WFInteractiveImageView *activeImageView;
    
    User *_currentUser;
}

@property (nonatomic) WFInteractiveImageView *draggingView;
@property (nonatomic) CGPoint dragViewStartLocation;
@property (nonatomic) NSIndexPath *startIndex;
@property (nonatomic) NSIndexPath *moveToIndexPath;
@property (weak, nonatomic) IBOutlet UILongPressGestureRecognizer *longPressRecognizer;

@end

@implementation WFSlideshowSplitViewController

@synthesize slideshow = _slideshow;

- (void)viewDidLoad {
    [super viewDidLoad];
    if (IDIOM == IPAD){
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
            width = screenWidth();
            height = screenHeight();
        } else {
            width = screenHeight();
            height = screenWidth();
        }
    }
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController.navigationBar setTranslucent:YES];
    
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:.1 alpha:23]];
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1 alpha:.1]];
    self.tableView.rowHeight = 180.f;
    [self setUpNavButtons];
    [self setUpTitleView];
    
    [self redrawSlideshow];
    [self registerKeyboardNotifications];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    }
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(slideDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.tableView addGestureRecognizer:doubleTap];
    
    [_longPressRecognizer addTarget:self action:@selector(longPressed:)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideEditMenu:) name:UIMenuControllerWillHideMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHideEditMenu:) name:UIMenuControllerDidHideMenuNotification object:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // manually set the top inset
    topInset = self.navigationController.navigationBar.frame.size.height;
    self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // only have the title textField become first responder if the slideshow title is still blank
    if (!_slideshow.title.length){
        [titleTextField becomeFirstResponder];
    }
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
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && [_slideshow.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        self.navigationItem.rightBarButtonItems = @[playButton, /*settingsButton,*/ searchButton, saveButton, shareButton];
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
    [titleTextField setText:_slideshow.title];
    [titleTextField setTextColor:[UIColor whiteColor]];
    [titleTextField setTextAlignment:NSTextAlignmentCenter];
    [titleTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]];
    [titleTextField setPlaceholder:@"Your Slideshow Title"];
    if (!_slideshow.title.length){
        [titleTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.06]];
    }
    self.navigationItem.titleView = titleTextField;
}

- (void)redrawSlideshow {
    if (!_slideshow.photos.count){
        [_lightBoxPlaceholderLabel setText:@"You don't have any slides in this light table"];
        [_lightBoxPlaceholderLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansThinItalic] size:0]];
        [_lightBoxPlaceholderLabel setTextAlignment:NSTextAlignmentCenter];
        [_lightBoxPlaceholderLabel setTextColor:[UIColor lightGrayColor]];
        [_lightBoxPlaceholderLabel setHidden:NO];
    } else {
        [_lightBoxPlaceholderLabel setHidden:YES];
    }
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0){
        return _slideshow.slides.count;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        WFSlideTableCell *cell = (WFSlideTableCell *)[tableView dequeueReusableCellWithIdentifier:@"SlideTableCell"];
        Slide *slide = _slideshow.slides[indexPath.row];
        cell.artImageView1.imageViewDelegate = self;
        cell.artImageView2.imageViewDelegate = self;
        cell.artImageView3.imageViewDelegate = self;
        [cell configureForSlide:slide withSlideNumber:indexPath.row + 1];
        
        return cell;
    } else {
        // prompt to add new cell
        WFSlideTableCell *cell = (WFSlideTableCell *)[tableView dequeueReusableCellWithIdentifier:@"SlideTableCell"];
        [cell configureForSlide:nil withSlideNumber:indexPath.row];
        return cell;
    }
}

- (void)slideDoubleTap:(UITapGestureRecognizer*)gestureRecognizer {
    CGPoint loc = [gestureRecognizer locationInView:_tableView];
    NSIndexPath *selectedIndexPath = [_tableView indexPathForRowAtPoint:loc];
    [self playSlideshow:selectedIndexPath.row];
}

- (void)longPressGesture:(UILongPressGestureRecognizer*)gestureRecognizer {
    
    WFInteractiveImageView *imageView = (WFInteractiveImageView*)gestureRecognizer.view;
    __block WFSlideTableCell *slideTableCell;
    [self.tableView.visibleCells enumerateObjectsUsingBlock:^(WFSlideTableCell *cell, NSUInteger idx, BOOL *stop) {
        if (cell.artImageView1 == imageView) {
            slideTableCell = cell;
            *stop = YES;
        } else if (cell.artImageView2 == imageView) {
            slideTableCell = cell;
            *stop = YES;
        } else if (cell.artImageView3 == imageView) {
            slideTableCell = cell;
            *stop = YES;
        }
    }];
    if (slideTableCell) {
        
        [self becomeFirstResponder];
        activeIndexPath = [self.tableView indexPathForCell:slideTableCell];
        activeImageView = imageView;
        activeSlide = _slideshow.slides[activeIndexPath.row];
        
        NSString *menuItemTitle = NSLocalizedString(@"Remove", @"Remove art from slide");
        UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:menuItemTitle action:@selector(removeArt:)];
        
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        [menuController setMenuItems:@[resetMenuItem]];
        
        CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
        CGRect menuLocation = CGRectMake(location.x, location.y, 0, 0);
        [menuController setTargetRect:menuLocation inView:[gestureRecognizer view]];
        
        [menuController setMenuVisible:YES animated:YES];
    }
}

- (void)removeArt:(UIMenuController*)menuController {
    [activeSlide removePhoto:activeImageView.photo];
    NSLog(@"active slide index: %@",activeSlide.index);
    if (activeSlide.photos.count){
        [self.tableView reloadRowsAtIndexPaths:@[activeIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView beginUpdates];
        [_slideshow removeSlide:activeSlide];
        [activeSlide MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        //[self.tableView deleteRowsAtIndexPaths:@[activeIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
     
        activeSlide = nil;
        activeImageView = nil;
        activeIndexPath = nil;
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
     
    }];
}

// UIMenuController requires that we can become first responder or it won't display
- (BOOL)canBecomeFirstResponder {
    return YES;
}
//
//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
//    return YES;
//}
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }   
//}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    Slide *slide = _slideshow.slides[fromIndexPath.row];
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:_slideshow.slides];
    [tempSet removeObject:slide];
    [tempSet insertObject:slide atIndex:toIndexPath.row];
    _slideshow.slides = tempSet;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
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
    return _slideshow.photos.count;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    [self redrawSlideshow];
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SlideshowArtCell" forIndexPath:indexPath];
    Photo *photo = _slideshow.photos[indexPath.item];
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
    Photo *photo = _slideshow.photos[indexPath.item];
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

- (void)longPressed:(UILongPressGestureRecognizer*)sender {
    CGPoint loc = [sender locationInView:self.collectionView];
    CGFloat heightInScreen = fmodf((loc.y-self.collectionView.contentOffset.y), CGRectGetHeight(self.collectionView.frame));
    CGFloat hoverOffset = kSidebarWidth;
    CGPoint locInScreen = CGPointMake( loc.x-self.collectionView.contentOffset.x+hoverOffset, heightInScreen );
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSLog(@"loc start: x %f and y: %f",loc.x, loc.y);
        if (loc.x < 0){
            self.startIndex = [self.tableView indexPathForRowAtPoint:loc];
            if (self.startIndex) {
                WFSlideTableCell *cell = (WFSlideTableCell*)[self.tableView cellForRowAtIndexPath:self.startIndex];
                selectedSlide = _slideshow.slides[self.startIndex.row];
                self.draggingView = [[WFInteractiveImageView alloc] initWithImage:[cell getRasterizedImageCopy] andPhoto:nil];
                
                [cell.contentView setAlpha:0.1f];
                [self.view addSubview:self.draggingView];
                self.draggingView.center = locInScreen;
                self.dragViewStartLocation = self.draggingView.center;
                [self.view bringSubviewToFront:self.draggingView];
                
                [UIView animateWithDuration:.23f animations:^{
                    CGAffineTransform transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                    self.draggingView.transform = transform;
                }];
            }
        } else {
            self.startIndex = [self.collectionView indexPathForItemAtPoint:loc];
            if (self.startIndex) {
                WFPhotoCell *cell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
                selectedPhoto = _slideshow.photos[self.startIndex.item];
                self.draggingView = [[WFInteractiveImageView alloc] initWithImage:[cell getRasterizedImageCopy] andPhoto:selectedPhoto];
                
                [cell.contentView setAlpha:0.1f];
                [self.view addSubview:self.draggingView];
                self.draggingView.center = locInScreen;
                self.dragViewStartLocation = self.draggingView.center;
                [self.view bringSubviewToFront:self.draggingView];
                
                [UIView animateWithDuration:.23f animations:^{
                    CGAffineTransform transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                    self.draggingView.transform = transform;
                }];
            }
        }
    }
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        self.draggingView.center = locInScreen;
    }
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        NSLog(@"ended loc: %f, %f",loc.x,loc.y);
        if (selectedPhoto){
            if (loc.x < 0){
                NSLog(@"content offset y: %f",_tableView.contentOffset.y);
                loc.y += _tableView.contentOffset.y + 44.f; //the original offset
                //cell was dropped in the left sidebar
                NSArray *visibleCells = self.tableView.visibleCells;
                [visibleCells enumerateObjectsUsingBlock:^(WFSlideTableCell *cell, NSUInteger idx, BOOL *stop) {
                    CGFloat lowerBounds = cell.frame.origin.y;
                    CGFloat upperBounds = cell.frame.origin.y + cell.frame.size.height;
                    CGFloat bottomOfSlides = cell.frame.size.height * _slideshow.slides.count;
                    //NSLog(@"Bottom of slides: %f, new loc y: %f",bottomOfSlides,loc.y);
                    if (loc.y > bottomOfSlides){
                        // this means we should add a new slide
                        Slide *slide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                        [slide addPhoto:selectedPhoto];
                        [slide setIndex:@(_slideshow.slides.count)];
                        [_slideshow addSlide:slide];
                        *stop = YES;
                        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                            [self.tableView reloadData];
                            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                        }];
                        
                    } else if (loc.y < upperBounds && loc.y > lowerBounds && selectedPhoto){
                        Slide *slide = [_slideshow.slides objectAtIndex:idx];
                        if (loc.x > -(kSidebarWidth/2) || slide.photos.count == 1){
                            if (slide.photos.count > 1){
                                [slide replacePhotoAtIndex:1 withPhoto:selectedPhoto];
                            } else {
                                [slide addPhoto:selectedPhoto];
                            }
                        } else {
                            [slide replacePhotoAtIndex:0 withPhoto:selectedPhoto];
                        }
                        [self.tableView reloadData];
                        *stop = YES;
                        [self endPressAnimation];
                        return;
                    }
                }];
            } else {
                NSLog(@"Art slide was not dropped on the left sidebar");
            }
        } else if (selectedSlide) {
            
        }
        
        if (self.draggingView) {
            self.moveToIndexPath = [self.collectionView indexPathForItemAtPoint:loc];
            if (self.moveToIndexPath) {
                //update date source
                NSNumber *thisNumber = [_slideshow.photos objectAtIndex:self.startIndex.row];
                NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:_slideshow.photos];
                [tempSet removeObjectAtIndex:self.startIndex.row];
                
                if (self.moveToIndexPath.row < self.startIndex.row) {
                    [tempSet insertObject:thisNumber atIndex:self.moveToIndexPath.row];
                } else {
                    [tempSet insertObject:thisNumber atIndex:self.moveToIndexPath.row];
                }
                [_slideshow setPhotos:tempSet];
                
                [UIView animateWithDuration:.23f animations:^{
                    self.draggingView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                    
                    //change items
                    __weak typeof(self) weakSelf = self;
                    [self.collectionView performBatchUpdates:^{
                        __strong typeof(self) strongSelf = weakSelf;
                        if (strongSelf) {
                            [strongSelf.collectionView deleteItemsAtIndexPaths:@[ self.startIndex ]];
                            [strongSelf.collectionView insertItemsAtIndexPaths:@[ strongSelf.moveToIndexPath ]];
                        }
                    } completion:^(BOOL finished) {
                        WFPhotoCell *movedCell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.moveToIndexPath];
                        [movedCell.contentView setAlpha:1.f];
                        WFPhotoCell *oldIndexCell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
                        [oldIndexCell.contentView setAlpha:1.f];
                    }];
                    
                    [self.draggingView removeFromSuperview];
                    self.draggingView = nil;
                    self.startIndex = nil;
                    
                }];
                
            } else {
                [self endPressAnimation];
            }
            
            loc = CGPointZero;
        }
    }
}

- (void)endPressAnimation {
    [UIView animateWithDuration:.23f animations:^{
        self.draggingView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        WFPhotoCell *cell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
        [cell.contentView setAlpha:1.f];
        
        [self.draggingView removeFromSuperview];
        self.draggingView = nil;
        self.startIndex = nil;
        selectedSlide = nil;
        selectedPhoto = nil;
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
    NSLog(@"Should enable offline mode");
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    }
}

- (void)save {
    if (_slideshow.title.length) {
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            //NSLog(@"Success saving? %u",success);
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
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    if (_slideshow.title.length){
        [parameters setObject:_slideshow.title forKey:@"title"];
    }
    if (_slideshow.slideshowDescription.length){
        [parameters setObject:_slideshow.slideshowDescription forKey:@"description"];
    }
    
    NSMutableArray *slideshowPhotos = [NSMutableArray arrayWithCapacity:_slideshow.photos.count];
    for (Photo *photo in _slideshow.photos){
        [slideshowPhotos addObject:photo.identifier];
    }
    NSLog(@"slideshow photos: %@",slideshowPhotos);
    [parameters setObject:slideshowPhotos forKey:@"photo_ids"];
    
    [_slideshow.slides enumerateObjectsUsingBlock:^(Slide *slide, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *slideObject = [NSMutableDictionary dictionary];
        if (slide && ![slide.identifier isEqualToNumber:@0]){
            [slideObject setObject:slide.identifier forKey:@"slide_id"];
        }
        
        NSLog(@"art count %lu for slide index %@",(unsigned long)slide.photos.count, slide.index);
        NSMutableArray *artIds = [NSMutableArray arrayWithCapacity:slide.photos.count];
        [slide.photos enumerateObjectsUsingBlock:^(Art *art, NSUInteger idx, BOOL *stop) {
            [artIds addObject:art.identifier];
        }];
        [slideObject setObject:artIds forKey:@"photo_ids"];
        [parameters setObject:slideObject forKey:[NSString stringWithFormat:@"slides[%lu]",(unsigned long)idx]];
    }];
    
    if ([_slideshow.identifier isEqualToNumber:@0]){
        [manager POST:[NSString stringWithFormat:@"slideshows"] parameters:@{@"slideshow":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success creating a slideshow: %@",responseObject);
            [_slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [WFAlert show:@"Slideshow saved!" withTime:2.3f];
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to create a slideshow: %@",error.description);
        }];
    } else {
        [manager PATCH:[NSString stringWithFormat:@"slideshows/%@",_slideshow.identifier] parameters:@{@"slideshow":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success saving a slideshow: %@",responseObject);
            [_slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [WFAlert show:@"Slideshow saved!" withTime:2.3f];
            }];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to save a slideshow: %@",error.description);
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
    WFTablesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Tables"];
    vc.lightTableDelegate = self;
    [vc setSlideshow:_slideshow];
    [vc setLightTables:_currentUser.lightTables.array.mutableCopy];
    CGFloat vcHeight = _currentUser.lightTables.count*54.f > 260.f ? 260 : (_currentUser.lightTables.count)*54.f;
    vc.preferredContentSize = CGSizeMake(270, vcHeight + 34.f); // add the header height
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover presentPopoverFromBarButtonItem:shareButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)lightTableSelected:(NSNumber *)lightTableId {
    Table *lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:lightTableId inContext:[NSManagedObjectContext MR_defaultContext]];
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    [lightTable addSlideshow:_slideshow];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [WFAlert show:[NSString stringWithFormat:@"Dropped to \"%@\"",lightTable.name] withTime:2.7f];
    }];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    [parameters setObject:_slideshow.identifier forKey:@"slideshow_id"];
    [manager POST:[NSString stringWithFormat:@"light_tables/%@/add_slideshow",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success adding slideshow to light table: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to add slideshow to light table: %@",error.description);
    }];
}

- (void)startSearch {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    WFSearchResultsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SearchResults"];
    vc.shouldShowSearchBar = YES;
    vc.shouldShowTiles = YES;
    vc.searchDelegate = self;
    vc.preferredContentSize = CGSizeMake(400, 500);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover setBackgroundColor:[UIColor blackColor]];
    [self.popover presentPopoverFromBarButtonItem:searchButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)searchDidSelectPhoto:(Photo *)photo {
    BOOL add; NSIndexPath *indexPathToReload;
    
    if ([_slideshow.photos containsObject:photo]){
        indexPathToReload = [NSIndexPath indexPathForItem:[_slideshow.photos indexOfObject:photo] inSection:0];
        [_slideshow removePhoto:photo];
        add = NO;
    } else {
        [_slideshow addPhoto:photo];
        add = YES;
        indexPathToReload = [NSIndexPath indexPathForItem:0 inSection:0];
    }
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        if (add){
            [_collectionView insertItemsAtIndexPaths:@[indexPathToReload]];
        } else {
            [_collectionView deleteItemsAtIndexPaths:@[indexPathToReload]];
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
    [self playSlideshow:0];
}

- (void)playSlideshow:(NSInteger)startIndex {
    if (_slideshow.slides.count){
        showSlideshow = YES;
        showMetadata = NO;
        WFSlideshowViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Slideshow"];
        [vc setStartIndex:startIndex];
        [vc setSlideshow:_slideshow];
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
            [_slideshow setTitle:titleTextField.text];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            }];
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
    [manager DELETE:[NSString stringWithFormat:@"slideshows/%@",_slideshow.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
    [_slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
