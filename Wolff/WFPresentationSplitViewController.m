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

@interface WFPresentationSplitViewController () <UIViewControllerTransitioningDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *playButton;
    UIBarButtonItem *newSlideButton;
    CGFloat topInset;
    BOOL showPresentation;
}

@end

@implementation WFPresentationSplitViewController

@synthesize presentation = _presentation;

- (void)viewDidLoad
{
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
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    
    newSlideButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(newSlide)];
    playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playPresentation)];
    self.navigationItem.rightBarButtonItems = @[newSlideButton, playButton];
    
    [self.tableView setBackgroundColor:[UIColor colorWithWhite:.1 alpha:1]];
    self.tableView.rowHeight = 160.f;
    
    self.title = _presentation.title;
    
    //manually set the collectionView's top inset
    topInset = self.navigationController.navigationBar.frame.size.height + 20;
    self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _presentation.slides.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WFSlideTableCell *cell = (WFSlideTableCell *)[tableView dequeueReusableCellWithIdentifier:@"SlideTableCell"];
    Slide *slide = _presentation.slides[indexPath.row];
    [cell configureForSlide:slide];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    return _presentation.slides.count;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFSlideCollectionCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"SlideCollectionCell" forIndexPath:indexPath];
    Slide *slide = _presentation.slides[indexPath.row];
    [cell configureForSlide:slide];
    
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
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Slide *slide = _presentation.slides[indexPath.item];
    [self showSlideDetail:slide];
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

- (void)newSlide {
    Slide *slide = [Slide MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    [_presentation addSlide:slide];
    [self.collectionView reloadData];
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

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
