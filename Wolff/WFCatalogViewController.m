//
//  WFCatalogViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFAppDelegate.h"
#import "WFCatalogViewController.h"
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
#import "WFPresentationsViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "WFSettingsAnimator.h"
#import "WFTablesAnimator.h"
#import "WFTablesViewController.h"

@interface WFCatalogViewController () <UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIViewControllerTransitioningDelegate, WFLoginDelegate, UIPopoverControllerDelegate, WFPresentationDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    UIBarButtonItem *presentationsButton;
    UIBarButtonItem *groupsButton;
    CGFloat width;
    CGFloat height;
    NSMutableArray *arts;
    NSMutableArray *filteredArts;
    NSMutableArray *tables;
    NSMutableArray *filteredTables;
    UIBarButtonItem *addButton;
    UIBarButtonItem *settingsButton;
    UIBarButtonItem *loginButton;
    BOOL metadata;
    BOOL searching;
    BOOL settings;
    BOOL groupBool;
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
@property (nonatomic, strong) id<WFTablesViewControllerPanTarget> groupsInteractor;
@end

@implementation WFCatalogViewController

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
    delegate.loginDelegate = self;
    manager = delegate.manager;
    [_comparisonContainerView setBackgroundColor:[UIColor lightGrayColor]];
    
    /*self.groupsInteractor = [[WFGroupsInteractor alloc] initWithParentViewController:self];
    UIScreenEdgePanGestureRecognizer *gestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self.groupsInteractor action:@selector(userDidPan:)];
    gestureRecognizer.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:gestureRecognizer];*/
    
    _dragForComparisonLabel.font = [UIFont fontWithName:kMuseoSansLight size:20];
    [self setUpNavBar];
    
    mainRefresh = [[UIRefreshControl alloc] init];
    [mainRefresh addTarget:self action:@selector(refreshMain:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:mainRefresh];
    [self.searchBar setPlaceholder:@"Search catalog"];
    //reset the search bar font
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleBody forFont:kLato] size:0]];
            break;
        }
    }
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    [self loadUser];
}

- (void)refreshMain:(UIRefreshControl*)refreshControl {
    if (_currentUser){
        [ProgressHUD show:@"Refreshing..."];
        [self loadUser];
    }
}

#pragma mark - WFLoginDelegate
- (void)loginSuccessful {
    NSLog(@"Successful login from WFMainView");
    [self setUpNavBar];
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    [self loadUser];
}

- (void)setUpNavBar {
    presentationsButton = [[UIBarButtonItem alloc] initWithTitle:@"Presentations" style:UIBarButtonItemStylePlain target:self action:@selector(showPresentations:)];
    groupsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tables"] style:UIBarButtonItemStylePlain target:self action:@selector(showTables)];
    self.navigationItem.leftBarButtonItems = @[groupsButton,presentationsButton];
    
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
    
    if (_currentUser){
        settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
        self.navigationItem.rightBarButtonItems = @[addButton,settingsButton];
    } else {
        loginButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login"] style:UIBarButtonItemStylePlain target:self action:@selector(showLogin)];
        self.navigationItem.rightBarButtonItems = @[loginButton, addButton];
    }
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    topInset = self.navigationController.navigationBar.frame.size.height + 20;
    self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
}

- (void)loadUser {
    if (_currentUser){
        [manager GET:[NSString stringWithFormat:@"users/%@/dashboard",_currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success getting user art: %@", responseObject);
            
            [_currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
            
            if (!arts){
                arts = [NSMutableArray arrayWithArray:_currentUser.arts.array];
            } else {
                arts = _currentUser.arts.array.mutableCopy;
            }
            if (!tables){
                tables = [NSMutableArray arrayWithArray:_currentUser.groups.array];
            } else {
                tables = _currentUser.groups.array.mutableCopy;
            }
            [self.tableView reloadData];
            [self.collectionView reloadData];
            
            [self endRefresh];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get user art: %@",error.description);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to load your art. Please try again soon." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil] show];
            
            [self endRefresh];
        }];
    }
}
- (void)endRefresh {
    [ProgressHUD dismiss];
    if (mainRefresh.isRefreshing){
        [mainRefresh endRefreshing];
    }
}

- (void)add {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return arts.count;
            break;
        case 1:
            return tables.count;
            break;
        default:
            return 0;
            break;
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
        Table *table;
        if (searching) {
            table = filteredTables[indexPath.row];
        } else {
            table = tables[indexPath.row];
        }
        [cell configureForTable:table];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 34;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 34)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    UILabel *headerLabel = [[UILabel alloc] init];
    [headerView addSubview:headerLabel];
    [headerLabel setFrame:CGRectMake(10, 0, width-10, 34)];
    [headerLabel setBackgroundColor:[UIColor clearColor]];
    [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredLatoFontForTextStyle:UIFontTextStyleCaption1 forFont:kLatoLight] size:0]];
    if (section == 0){
        [headerLabel setText:@"ART"];
    } else {
        [headerLabel setText:@"TABLES"];
    }
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did select something");
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
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
    return arts.count;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFArtCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ArtCell" forIndexPath:indexPath];
    cell.layer.borderColor = [UIColor colorWithWhite:1 alpha:.023].CGColor;
    cell.layer.borderWidth = 0.f;
    Art *art = arts[indexPath.item];
    if (art.photo.largeImageUrl.length){
        [cell.artImageView sd_setImageWithURL:[NSURL URLWithString:art.photo.largeImageUrl]  placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            [UIView animateWithDuration:.23 animations:^{
                [cell.artImageView setAlpha:1.0];
            }];
        }];
        
     } else {
         [cell.artImageView setImage:nil];
     }
    
    return cell;
}

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
        NSLog(@"ended loc: %f, %f",loc.x,loc.y);
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
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Art *art = arts[indexPath.item];
    [self showMetadata:art];
}

- (void)showMetadata:(Art*)art{
    WFArtMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ArtMetadata"];
    [vc setArt:art];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    metadata = YES;
    settings = NO;
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

- (void)dismissMetadata {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Custom Transitions 

- (void)showLogin {
    WFLoginViewController *login = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
    [self presentViewController:login animated:YES completion:^{
        
    }];
}

- (void)showSettings {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        settings = YES;
        metadata = NO;
        _login = NO;
        groupBool = NO;
        WFSettingsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Settings"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    } else {
        [self showLogin];
    }
}

- (void)showPresentations:(id)sender {
    WFPresentationsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Presentations"];
    vc.presentationDelegate = self;
    vc.preferredContentSize = CGSizeMake(320, 400);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)showTables {
    WFTablesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Groups"];
    groupBool = YES;
    settings = NO;
    metadata = NO;
    _login = NO;
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

- (void)presentationSelected:(Presentation *)presentation {
    [self.popover dismissPopoverAnimated:YES];
    WFPresentationSplitViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"PresentationSplitView"];
    [vc setPresentation:presentation];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    metadata = NO;
    settings = NO;
    _login = NO;
    groupBool = NO;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    if (groupBool){
        WFTablesAnimator *animator = [WFTablesAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (settings){
        WFSettingsAnimator *animator = [WFSettingsAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (metadata){
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
    
    if (groupBool){
        WFTablesAnimator *animator = [WFTablesAnimator new];
        return animator;
    } else if (settings){
        WFSettingsAnimator *animator = [WFSettingsAnimator new];
        return animator;
    } else if (metadata){
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"Art"]){
        Art *art = (Art*)sender;
        WFArtViewController *vc = [segue destinationViewController];
        [vc setArt:art];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
