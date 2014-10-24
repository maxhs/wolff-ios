//
//  WFMainViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFMainViewController.h"
#import "WFPresentationSplitViewController.h"
#import "WFPresentationAnimator.h"
#import "WFArtCell.h"
#import "WFArtMetadataAnimator.h"
#import "WFArtMetadataViewController.h"
#import "WFArtViewController.h"
#import "WFMainTableCell.h"
#import "WFSettingsViewController.h"
#import "WFLoginAnimator.h"
#import "WFLoginViewController.h"

@interface WFMainViewController () <UIViewControllerTransitioningDelegate, WFLoginDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UIBarButtonItem *presentationsButton;
    CGFloat width;
    CGFloat height;
    NSMutableArray *arts;
    NSMutableArray *filteredArts;
    UIBarButtonItem *addButton;
    UIBarButtonItem *settingsButton;
    UIBarButtonItem *loginButton;
    BOOL metadata;
    BOOL searching;
    CGFloat topInset;
    UIRefreshControl *mainRefresh;
}
@property (weak, nonatomic) IBOutlet UIView *comparisonContainerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *dragForComparisonLabel;
@property (nonatomic) UIImageView *draggingView;
@property (nonatomic) CGPoint dragViewStartLocation;
@property (nonatomic) NSIndexPath *startIndex;
@property (nonatomic) NSIndexPath *moveToIndexPath;
@end

@implementation WFMainViewController

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
    NSLog(@"what is width? %f, and screenWidth? %d",width,screenWidth());
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    delegate.loginDelegate = self;
    manager = delegate.manager;
    [_comparisonContainerView setBackgroundColor:[UIColor lightGrayColor]];

    _dragForComparisonLabel.font = [UIFont fontWithName:kMyriadLight size:20];
    [self setUpNavBar];
    [self loadUserArt];
    
    mainRefresh = [[UIRefreshControl alloc] init];
    [mainRefresh addTarget:self action:@selector(refreshMain:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:mainRefresh];
    [self.searchBar setPlaceholder:@"Search catalog"];
}

- (void)refreshMain:(UIRefreshControl*)refreshControl {
    if (delegate.currentUser){
        [ProgressHUD show:@"Refreshing..."];
        [self loadUserArt];
    }
}

#pragma mark - WFLoginDelegate
- (void)loginSuccessful {
    NSLog(@"Successful login from WFMainView");
    [self setUpNavBar];
    [self loadUserArt];
}

- (void)setUpNavBar {
    presentationsButton = [[UIBarButtonItem alloc] initWithTitle:@"Presentations" style:UIBarButtonItemStylePlain target:self action:@selector(showPresentations)];
    self.navigationItem.leftBarButtonItem = presentationsButton;
    
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
    
    if (delegate.currentUser){
        settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(goToSettings)];
        self.navigationItem.rightBarButtonItems = @[addButton,settingsButton];
    } else {
        loginButton = [[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStylePlain target:self action:@selector(showLogin)];
        self.navigationItem.rightBarButtonItems = @[loginButton, addButton];
    }
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    topInset = self.navigationController.navigationBar.frame.size.height + 20;
    self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
}

- (void)loadUserArt {
    if (delegate.currentUser){
        [manager GET:[NSString stringWithFormat:@"%@/arts",kApiBaseUrl] parameters:@{@"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success getting user art: %@", responseObject);
            
            [delegate.currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
            if (!arts){
                arts = [NSMutableArray arrayWithArray:delegate.currentUser.arts.array];
            } else {
                arts = delegate.currentUser.arts.array.mutableCopy;
            }
            [self.tableView reloadData];
            
            [ProgressHUD dismiss];
            if (mainRefresh.isRefreshing){
                [mainRefresh endRefreshing];
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get user art: %@",error.description);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to load your art. Please try again soon." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil] show];
            [ProgressHUD dismiss];
            if (mainRefresh.isRefreshing){
                [mainRefresh endRefreshing];
            }
        }];
    }
}

- (void)add {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0){
        return arts.count;
    } else {
        return 4;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WFMainTableCell *cell = (WFMainTableCell *)[tableView dequeueReusableCellWithIdentifier:@"MainCell"];
    
    if (indexPath.section == 0){
        Art *art;
        if (searching) {
            art = filteredArts[indexPath.row];
        } else {
            art = arts[indexPath.row];
        }
        [cell configureForArt:art];
    } else {
        
    }
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0){
        return @"My Images";
    } else {
        return @"Other Images";
    }
}


#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"what is it? %f",(width-kMainSplitWidth)/3);
    if (IDIOM == IPAD){
        return CGSizeMake((width-kMainSplitWidth)/3,(width-kMainSplitWidth)/3);
    } else {
        return CGSizeMake(width/3,width/3);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    //return arts.count;
    return 12;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFArtCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ArtCell" forIndexPath:indexPath];
    cell.layer.borderColor = [UIColor colorWithWhite:1 alpha:.023].CGColor;
    cell.layer.borderWidth = 0.f;
    /*Art *art = arts[indexPath.row];
    //NSLog(@"art url: %@",art.mediumImageUrl);
    if (art.mediumImageUrl.length){
     [cell.artImageView setImageWithURL:[NSURL URLWithString:art.mediumImageUrl] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
     [UIView animateWithDuration:.23 animations:^{
     [cell.artImageView setAlpha:1.0];
     }];
     }];
     } else {
     [cell.artImageView setImage:nil];
     }*/
    [cell.artImageView setImage:[UIImage imageNamed:@"art.jpg"]];
    
    return cell;
}

/*- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (kind == UICollectionElementKindSectionHeader){
        UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header" forIndexPath:indexPath];
        [headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        return headerView;
    } else {
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        return footerView;
    }
}*/

- (IBAction)longPressed:(UILongPressGestureRecognizer*)sender {
    CGPoint loc = [sender locationInView:self.collectionView];
    CGFloat heightInScreen = fmodf((loc.y-self.collectionView.contentOffset.y), CGRectGetHeight(self.collectionView.frame));
    CGPoint locInScreen = CGPointMake( loc.x-self.collectionView.contentOffset.x+kMainSplitWidth, heightInScreen );
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.startIndex = [self.collectionView indexPathForItemAtPoint:loc];
        
        if (self.startIndex) {
            WFArtCell *cell = (WFArtCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
            self.draggingView = [[UIImageView alloc] initWithImage:[cell getRasterizedImageCopy]];
            
            [cell.contentView setAlpha:0.f];
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
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        self.draggingView.center = locInScreen;
    }
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (self.draggingView) {
            self.moveToIndexPath = [self.collectionView indexPathForItemAtPoint:loc];
            if (self.moveToIndexPath) {
                //update date source
                NSNumber *thisNumber = [arts objectAtIndex:self.startIndex.row];
                [arts removeObjectAtIndex:self.startIndex.row];
                
                if (self.moveToIndexPath.row < self.startIndex.row) {
                    [arts insertObject:thisNumber atIndex:self.moveToIndexPath.row];
                } else {
                    [arts insertObject:thisNumber atIndex:self.moveToIndexPath.row];
                }
                
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
                [UIView animateWithDuration:.23f animations:^{
                    self.draggingView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                    WFArtCell *cell = (WFArtCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
                    [cell.contentView setAlpha:1.f];
                    
                    [self.draggingView removeFromSuperview];
                    self.draggingView = nil;
                    self.startIndex = nil;
                }];
            }
            
            loc = CGPointZero;
        }
    }
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Art *art = arts[indexPath.item];
    [self showMetadata:art];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"Art"]){
        Art *art = (Art*)sender;
        NSLog(@"should be segueing to art with name: %@",art.title);
        WFArtViewController *vc = [segue destinationViewController];
        [vc setArt:art];
    }
}

- (void)showMetadata:(Art*)art{
    WFArtMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ArtMetadata"];
    [vc setArt:art];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    metadata = YES;
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

#pragma mark - Custom Transitions 

- (void)showLogin {
    WFLoginViewController *login = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
    [self presentViewController:login animated:YES completion:^{
        
    }];
}

- (void)goToSettings {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        WFSettingsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Settings"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    } else {
        [self showLogin];
    }
}

- (void)showPresentations {
    WFPresentationSplitViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"PresentationSplitView"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    metadata = NO;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    if (metadata){
        WFArtMetadataAnimator *animator = [WFArtMetadataAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (_login) {
        WFLoginAnimator *animator = [WFLoginAnimator new];
        animator.presenting = YES;
        return animator;
    } else {
        WFPresentationAnimator *animator = [WFPresentationAnimator new];
        animator.presenting = YES;
        return animator;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    if (metadata){
        WFArtMetadataAnimator *animator = [WFArtMetadataAnimator new];
        return animator;
    } else if (_login) {
        WFLoginAnimator *animator = [WFLoginAnimator new];
        return animator;
    } else {
        WFPresentationAnimator *animator = [WFPresentationAnimator new];
        return animator;
    }
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:^{
       
    }];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    NSLog(@"Search bar is editing");
    searching = YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSLog(@"Search text did change: %@",searchText);
    [self filterContentForSearchText:searchText scope:nil];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    if (!filteredArts){
        filteredArts = [NSMutableArray array];
    } else {
        [filteredArts removeAllObjects];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
    
    for (Art *art in arts){
        if([predicate evaluateWithObject:art.title]) {
            [filteredArts addObject:art];
        }
    }
}

@end
