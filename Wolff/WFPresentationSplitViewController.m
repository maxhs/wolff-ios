//
//  WFPresentationSplitViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFAppDelegate.h"
#import "WFPresentationSplitViewController.h"
#import "WFSlideCollectionCell.h"
#import "WFSlideTableCell.h"
#import "WFSlideDetailViewController.h"
#import "WFPresentationViewController.h"
#import "WFSlideAnimator.h"
#import "WFPresentationFocusAnimator.h"
#import "WFSearchResultsViewController.h"
#import "WFArtCell.h"

@interface WFPresentationSplitViewController () <UIViewControllerTransitioningDelegate, UIPopoverControllerDelegate, WFSearchDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *playButton;
    UIBarButtonItem *searchButton;
    UIBarButtonItem *cloudDownloadButton;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *shareButton;
    CGFloat topInset;
    BOOL showPresentation;
    UITextField *titleTextField;
    NSTimeInterval duration;
    UIViewAnimationOptions animationCurve;
    CGFloat keyboardHeight;
    Art *selectedArt;
    Slide *selectedSlide;
}

@property (nonatomic) UIImageView *draggingView;
@property (nonatomic) CGPoint dragViewStartLocation;
@property (nonatomic) NSIndexPath *startIndex;
@property (nonatomic) NSIndexPath *moveToIndexPath;
@property (weak, nonatomic) IBOutlet UILongPressGestureRecognizer *longPressRecognizer;

@end

@implementation WFPresentationSplitViewController

@synthesize presentation = _presentation;

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
    self.tableView.rowHeight = 200.f;
    [self setUpNavButtons];
    [self setUpTitleView];
    
    [self redrawPresentation];
    [self registerKeyboardNotifications];
    
    [_longPressRecognizer addTarget:self action:@selector(longPressed:)];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // manually set the top inset
    topInset = self.navigationController.navigationBar.frame.size.height;
    self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // only have the title textField become first responder if the presentation title is still blank
    if (!_presentation.title.length){
        [titleTextField becomeFirstResponder];
    }
}

#pragma mark - View Setup
- (void)setUpNavButtons {
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItems = @[dismissButton];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    shareButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"people"] style:UIBarButtonItemStylePlain target:self action:@selector(share)];
    searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search"] style:UIBarButtonItemStylePlain target:self action:@selector(startSearch)];
    cloudDownloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cloudDownload"] style:UIBarButtonItemStylePlain target:self action:@selector(cloudDownload)];
    saveButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cloudUpload"] style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    
    playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playPresentation)];
    self.navigationItem.rightBarButtonItems = @[playButton, searchButton, cloudDownloadButton, saveButton, shareButton];
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
    [titleTextField setText:_presentation.title];
    [titleTextField setTextColor:[UIColor whiteColor]];
    [titleTextField setTextAlignment:NSTextAlignmentCenter];
    [titleTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSans] size:0]];
    [titleTextField setPlaceholder:@"Your Presentation Title"];
    [titleTextField setBackgroundColor:[UIColor colorWithWhite:1 alpha:.06]];
    self.navigationItem.titleView = titleTextField;
}

- (void)redrawPresentation {
    if (!_presentation.arts.count){
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _presentation.slides.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFSlideTableCell *cell = (WFSlideTableCell *)[tableView dequeueReusableCellWithIdentifier:@"SlideTableCell"];
    Slide *slide = _presentation.slides[indexPath.row];
    [cell configureForSlide:slide withSlideNumber:indexPath.row + 1];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    Slide *slide = _presentation.slides[fromIndexPath.row];
    NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:_presentation.slides];
    [tempSet removeObject:slide];
    [tempSet insertObject:slide atIndex:toIndexPath.row];
    _presentation.slides = tempSet;
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
        return CGSizeMake((width-kPresentationSplitWidth)/3,(width-kPresentationSplitWidth)/3);
    } else {
        return CGSizeMake(width/3,width/3);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return _presentation.arts.count;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    [self redrawPresentation];
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFArtCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ArtCell" forIndexPath:indexPath];
    Art *art = _presentation.arts[indexPath.item];
    [cell configureForArt:art];
    
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
    Art *art = _presentation.arts[indexPath.item];
    NSLog(@"Presentation did select: %@",art.title);
}

- (void)showSlideDetail:(Slide*)slide {
    showPresentation = NO;
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
    CGFloat hoverOffset = kPresentationSplitWidth;
    CGPoint locInScreen = CGPointMake( loc.x-self.collectionView.contentOffset.x+hoverOffset, heightInScreen );
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        NSLog(@"loc start: x %f and y: %f",loc.x, loc.y);
        /*if (loc.x < kPresentationSplitWidth){
            NSLog(@"we've selected a slide, not an art piece");
            self.startIndex = [self.tableView indexPathForRowAtPoint:loc];
            if (self.startIndex) {
                WFSlideTableCell *cell = (WFSlideTableCell*)[self.tableView cellForRowAtIndexPath:self.startIndex];
                selectedSlide = _presentation.slides[self.startIndex.row];
                self.draggingView = [[UIImageView alloc] initWithImage:[cell getRasterizedImageCopy]];
                
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
        } else {*/
            self.startIndex = [self.collectionView indexPathForItemAtPoint:loc];
            if (self.startIndex) {
                WFArtCell *cell = (WFArtCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
                selectedArt = _presentation.arts[self.startIndex.item];
                self.draggingView = [[UIImageView alloc] initWithImage:[cell getRasterizedImageCopy]];
                
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
        //}
    }
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        self.draggingView.center = locInScreen;
    }
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        //NSLog(@"ended loc: %f, %f",loc.x,loc.y);
        if (selectedArt){
            NSArray *visibleCells = self.tableView.visibleCells;
            if (visibleCells.count){
                [visibleCells enumerateObjectsUsingBlock:^(WFSlideTableCell *cell, NSUInteger idx, BOOL *stop) {
                    CGFloat lowerBounds = cell.frame.origin.y;
                    CGFloat upperBounds = cell.frame.origin.y + cell.frame.size.height;
                    CGFloat bottomOfSlides = cell.frame.size.height * _presentation.slides.count;
                    NSLog(@"bottom of slides: %f", bottomOfSlides);
                    if (loc.y > bottomOfSlides){
                        // this means we should add a new slide
                        Slide *slide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                        [slide addArt:selectedArt];
                        [slide setIndex:[NSNumber numberWithInteger:_presentation.slides.count]];
                        [_presentation addSlide:slide];
                        [self.tableView reloadData];
                    } else if (loc.y < upperBounds && loc.y > lowerBounds){
                        NSLog(@"slide origin %f, y %f, and width %f",cell.frame.origin.x,cell.frame.origin.y, cell.frame.size.width);
                        Slide *slide = [_presentation.slides objectAtIndex:idx];
                        if (selectedArt)[slide addArt:selectedArt];
                        [self.tableView reloadData];
                        *stop = YES;
                        [self endPressAnimation];
                        return;
                    }
                }];
            } else {
                Slide *slide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                if (selectedArt)[slide addArt:selectedArt];
                [slide setIndex:[NSNumber numberWithInteger:_presentation.slides.count]];
                [_presentation addSlide:slide];
                [self.tableView reloadData];
                
                [self endPressAnimation];
            }
        } else if (selectedSlide) {
            
        }
        
        
        if (self.draggingView) {
            self.moveToIndexPath = [self.collectionView indexPathForItemAtPoint:loc];
            if (self.moveToIndexPath) {
                //update date source
                NSNumber *thisNumber = [_presentation.arts objectAtIndex:self.startIndex.row];
                NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:_presentation.arts];
                [tempSet removeObjectAtIndex:self.startIndex.row];
                
                if (self.moveToIndexPath.row < self.startIndex.row) {
                    [tempSet insertObject:thisNumber atIndex:self.moveToIndexPath.row];
                } else {
                    [tempSet insertObject:thisNumber atIndex:self.moveToIndexPath.row];
                }
                [_presentation setArts:tempSet];
                
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
                        WFArtCell *movedCell = (WFArtCell*)[self.collectionView cellForItemAtIndexPath:self.moveToIndexPath];
                        [movedCell.contentView setAlpha:1.f];
                        WFArtCell *oldIndexCell = (WFArtCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
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
        WFArtCell *cell = (WFArtCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
        [cell.contentView setAlpha:1.f];
        
        [self.draggingView removeFromSuperview];
        self.draggingView = nil;
        self.startIndex = nil;
        selectedSlide = nil;
        selectedArt = nil;
    }];
}

- (void)newSlide {
    Slide *slide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [slide setIndex:[NSNumber numberWithInteger:_presentation.slides.count]];
    [_presentation addSlide:slide];
    [self.tableView reloadData];
}

- (void)save {
    NSLog(@"Should be saving");
    if (_presentation.title.length) {
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"Success saving? %u",success);
            NSLog(@"what's the new presentation id? %@",_presentation.identifier);
            [self post];
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"No title!" message:@"Please make sure you've titled this presentation before saving." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}

- (void)post {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    if (_presentation.title.length){
        [parameters setObject:_presentation.title forKey:@"title"];
    }
    if (_presentation.presentationDescription.length){
        [parameters setObject:_presentation.presentationDescription forKey:@"description"];
    }
    
    NSMutableArray *presentationArts = [NSMutableArray array];
    for (Art *art in _presentation.arts){
        [presentationArts addObject:art.identifier];
    }
    if (presentationArts.count){
        NSLog(@"presentation arts: %@",presentationArts);
        [parameters setObject:[presentationArts componentsJoinedByString:@","] forKey:@"art_ids"];
    }
    
    NSMutableArray *slides = [NSMutableArray array];
    for (Slide *slide in _presentation.slides){
        if (slide && ![slide.identifier isEqualToNumber:@0]){
            [slides addObject:@{@"slide_id":slide.identifier}];
        }
        NSMutableArray *artIds = [NSMutableArray arrayWithCapacity:slide.arts.count];
        [slide.arts enumerateObjectsUsingBlock:^(Art *art, NSUInteger idx, BOOL *stop) {
            [artIds addObject:art.identifier];
        }];
        [slides addObject:@{@"art_ids":artIds}];
        [slides addObject:@{@"index":slide.index}];
    }
    if (slides.count){
        NSLog(@"slides: %@",slides);
        [parameters setObject:slides forKey:@"slides"];
    }
    
    if ([_presentation.identifier isEqualToNumber:@0]){
        [manager POST:[NSString stringWithFormat:@"presentations"] parameters:@{@"presentation":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success creating a presentation: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to create a presentation: %@",error.description);
        }];
    } else {
        [manager PATCH:[NSString stringWithFormat:@"presentations/%@",_presentation.identifier] parameters:@{@"presentation":parameters} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success saving a presentation: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to save a presentation: %@",error.description);
        }];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [titleTextField becomeFirstResponder];
}

- (void)cloudDownload {
    NSLog(@"Should be downloading");
}

- (void)share {
    NSLog(@"Should be sharing");
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
    [self.popover presentPopoverFromBarButtonItem:searchButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)searchDidSelectArt:(Art *)art {
    if ([_presentation.arts containsObject:art]){
        [_presentation removeArt:art];
    } else {
        [_presentation addArt:art];
    }
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveOnlySelfWithCompletion:^(BOOL success, NSError *error) {
        [_collectionView reloadData];
    }];
}

- (void)endSearch {
    [self.view endEditing:YES];
    [self.popover dismissPopoverAnimated:YES];
}

- (void)playPresentation {
    showPresentation = YES;
    WFPresentationViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Presentation"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    if (showPresentation){
        WFPresentationFocusAnimator *animator = [WFPresentationFocusAnimator new];
        animator.presenting = YES;
        return animator;
    } else {
        WFSlideAnimator *animator = [WFSlideAnimator new];
        animator.presenting = YES;
        return animator;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    if (showPresentation){
        WFPresentationFocusAnimator *animator = [WFPresentationFocusAnimator new];
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
            [_presentation setTitle:titleTextField.text];
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
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    keyboardHeight = [keyboardFrameBegin CGRectValue].size.height;
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

- (void)savePresentation {
    [ProgressHUD show:@"Saving..."];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"Success saving presentation? %u",success);
        [ProgressHUD showSuccess:@"Saved"];
    }];
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
