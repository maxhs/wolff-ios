//
//  WFCatalogViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/5/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFAppDelegate.h"
#import "WFCatalogViewController.h"
#import "WFSlideshowSplitViewController.h"
#import "WFSlideshowAnimator.h"
#import "WFArtCell.h"
#import "WFArtMetadataAnimator.h"
#import "WFArtMetadataViewController.h"
#import "WFArtViewController.h"
#import "WFMainTableCell.h"
#import "WFSettingsViewController.h"
#import "WFLoginAnimator.h"
#import "WFLoginViewController.h"
#import "WFSlideshowsViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "WFSettingsAnimator.h"
#import "WFTablesAnimator.h"
#import "WFTablesViewController.h"
#import "WFNotificationsViewController.h"
#import "WFMenuViewController.h"
#import "WFNewArtAnimator.h"
#import "WFNewArtViewController.h"
#import "WFNewLightTableController.h"
#import "WFSearchResultsViewController.h"
#import "WFCatalogHeaderView.h"
#import "Favorite+helper.h"
#import "WFInteractiveImageView.h"
#import "WFComparisonViewController.h"
#import "WFSlideshowFocusAnimator.h"

@interface WFCatalogViewController () <UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIViewControllerTransitioningDelegate, WFLoginDelegate, WFMenuDelegate, UIPopoverControllerDelegate, WFSlideshowDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    UIButton *presentationsButton;
    UIBarButtonItem *presentationsBarButton;
    UIButton *tablesButton;
    UIBarButtonItem *lightTablesButton;
    UIBarButtonItem *notificationsButton;
    UIBarButtonItem *refreshButton;
    CGFloat width;
    CGFloat height;
    NSMutableArray *_arts;
    NSMutableArray *_privateArts;
    NSMutableArray *_favorites;
    NSMutableArray *_filteredArts;
    NSMutableArray *_tables;
    NSMutableArray *_filteredTables;
    UIBarButtonItem *addButton;
    UIBarButtonItem *settingsButton;
    UIBarButtonItem *loginButton;
    UIButton *newLightTableButton;
    UIButton *expandLightTablesButton;
    BOOL expanded;
    BOOL metadata;
    BOOL searching;
    BOOL loading;
    BOOL comparison;
    BOOL settings;
    BOOL newArt;
    BOOL notificationsBool;
    BOOL groupBool;
    BOOL tableIsVisible;
    BOOL canLoadMoreArt;
    
    BOOL showPrivate;
    BOOL showFavorites;
    BOOL showLightTable;
    Table *_table;
    CGFloat topInset;
    UIRefreshControl *tableViewRefresh;
    UIRefreshControl *collectionViewRefresh;
    NSMutableOrderedSet *selectedSlides;
    
    UITapGestureRecognizer *comparisonTap;
    
    WFInteractiveImageView *comparison1;
    WFInteractiveImageView *comparison2;
    
    WFSearchResultsViewController *searchResultsVc;
}
@property (weak, nonatomic) IBOutlet UIView *comparisonContainerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *dragForComparisonLabel;
@property (nonatomic) WFInteractiveImageView *draggingView;
@property (nonatomic) NSIndexPath *startIndex;
@property (nonatomic) CGPoint dragViewStartLocation;
@property (nonatomic) NSIndexPath *moveToIndexPath;
@property (nonatomic, strong) id<WFTablesViewControllerPanTarget> groupsInteractor;
@end

@implementation WFCatalogViewController

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccessful) name:@"LoginSuccessful" object:nil];
    manager = delegate.manager;
    _arts = [NSMutableArray array];
    _privateArts = [NSMutableArray array];
    _favorites = [NSMutableArray array];
    
    _arts = [Art MR_findAllSortedBy:@"uploadedDate" ascending:NO inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
    
    //set up the nav buttons
    [self setUpNavBar];
    
    //set up the light table sidebar
    expanded = NO;
    [self setUpTableView];
    
    comparisonTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shouldCompare)];
    comparisonTap.numberOfTapsRequired = 1;
    comparisonTap.numberOfTouchesRequired = 1;
    [_comparisonContainerView addGestureRecognizer:comparisonTap];
    
    [_comparisonContainerView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.1f]];
    _dragForComparisonLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0];
    [_dragForComparisonLabel setTextColor:[UIColor colorWithWhite:.6f alpha:.7f]];
    
    /*self.groupsInteractor = [[WFGroupsInteractor alloc] initWithParentViewController:self];
    UIScreenEdgePanGestureRecognizer *gestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self.groupsInteractor action:@selector(userDidPan:)];
    gestureRecognizer.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:gestureRecognizer];*/
    
    [_collectionView setBackgroundColor:[UIColor whiteColor]];
    collectionViewRefresh = [[UIRefreshControl alloc] init];
    [collectionViewRefresh addTarget:self action:@selector(refreshCollectionView:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:collectionViewRefresh];
    canLoadMoreArt = YES;
    
    [self.searchBar setPlaceholder:@"Search catalog"];
    //reset the search bar font
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            [searchTextField setTextColor:[UIColor whiteColor]];
            [searchTextField setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLight] size:0]];
            searchTextField.keyboardAppearance = UIKeyboardAppearanceDark;
            break;
        }
    }
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    if (_currentUser){
        [self loadUser];
        if (!tableViewRefresh){
            tableViewRefresh = [[UIRefreshControl alloc] init];
            [tableViewRefresh addTarget:self action:@selector(refreshTableView:) forControlEvents:UIControlEventValueChanged];
        }
        [self.tableView addSubview:tableViewRefresh];
    }
    
    [self loadArt];
}

- (void)refreshTableView:(UIRefreshControl*)refreshControl {
    if (_currentUser){
        [ProgressHUD show:@"Refreshing..."];
        [self loadUser];
    }
}

- (void)refreshCollectionView:(id)sender {
    [ProgressHUD show:@"Refreshing Art..."];
    [_arts removeAllObjects];
    canLoadMoreArt = YES;
    NSLog(@"handle refresh collection view");
    [self loadArt];
}

- (void)setUpTableView {
    [_tableView setBackgroundColor:[UIColor blackColor]];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tableView.rowHeight = 54.f;
}

- (void)setUpNavBar {
    presentationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [presentationsButton setImage:[UIImage imageNamed:@"whitePresentation"] forState:UIControlStateNormal];
    presentationsButton.frame = CGRectMake(0.0, 0.0, 70.0, 44.0);
    [presentationsButton addTarget:self action:@selector(showPresentations) forControlEvents:UIControlEventTouchUpInside];
    presentationsBarButton = [[UIBarButtonItem alloc] initWithCustomView:presentationsButton];
    
    tablesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [tablesButton setImage:[UIImage imageNamed:@"whiteTables"] forState:UIControlStateNormal];
    [tablesButton setImage:[UIImage imageNamed:@"blueTable"] forState:UIControlStateSelected];
    tablesButton.frame = CGRectMake(20.0, 0.0, 50.0, 44.0);
    [tablesButton addTarget:self action:@selector(showLightTables) forControlEvents:UIControlEventTouchUpInside];
    lightTablesButton = [[UIBarButtonItem alloc] initWithCustomView:tablesButton];
    
    self.navigationItem.leftBarButtonItems = @[lightTablesButton,presentationsBarButton];
    
    refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshCollectionView:)];
    addButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"plus"] style:UIBarButtonItemStylePlain target:self action:@selector(add)];
    
    if (_currentUser){
        settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPopover:)];
        notificationsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"alert"] style:UIBarButtonItemStylePlain target:self action:@selector(showNotifications:)];
        
        self.navigationItem.rightBarButtonItems = @[addButton, notificationsButton, settingsButton, refreshButton];
    } else {
        loginButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login"] style:UIBarButtonItemStylePlain target:self action:@selector(showLogin)];
        self.navigationItem.rightBarButtonItems = @[loginButton, addButton, refreshButton];
    }
    
    self.navigationItem.titleView = self.searchBar;
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    topInset = self.navigationController.navigationBar.frame.size.height + 20;
    self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
}

#pragma mark - WFLoginDelegate
- (void)loginSuccessful {
    NSLog(@"Successful login from Catalog");
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    [self setUpNavBar];
    [self loadUser];
}

- (void)loadArt {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@20 forKey:@"count"];
    if (_arts.count) {
        Art *lastArt = _arts.lastObject;
        [parameters setObject:[NSNumber numberWithDouble:[lastArt.uploadedDate timeIntervalSince1970]] forKey:@"before_date"];
    } else {
        [ProgressHUD show:@"Loading art..."];
    }
    if (!loading){
        loading = YES;
        [manager GET:@"arts" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"load arts success: %@", responseObject);
            NSLog(@"arts count: %d",[[responseObject objectForKey:@"arts"] count]);
            if ([[responseObject objectForKey:@"arts"] count]){
                canLoadMoreArt = YES;
                
                for (NSDictionary *dict in [responseObject objectForKey:@"arts"]) {
                    Art *art = [Art MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                    if (!art){
                        art = [Art MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [art populateFromDictionary:dict];
                    if (![_arts containsObject:art]){
                        [_arts addObject:art];
                    }
                }
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    NSLog(@"Done saving art: %u",success);
                }];
            } else {
                canLoadMoreArt = NO;
                NSLog(@"Can't load any more art. We got it all!");
            }
            [self.collectionView reloadData];
            [self endRefresh];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self endRefresh];
        }];
    }
}

- (void)loadUser {
    if (_currentUser && !loading){
        loading = YES;
        [manager GET:[NSString stringWithFormat:@"users/%@/dashboard",_currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success getting user art: %@", responseObject);
            
            [_currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"privateArt == %@ && user.identifier == %@", @YES, [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
                _privateArts = [Art MR_findAllWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
                
                [_currentUser.favorites enumerateObjectsUsingBlock:^(Favorite *favorite, NSUInteger idx, BOOL *stop) {
                    if (favorite.art && ![_favorites containsObject:favorite.art]) {
                        [_favorites addObject:favorite.art];
                    }
                }];
                
                if (!_tables){
                    _tables = [NSMutableArray arrayWithArray:_currentUser.tables.array];
                } else {
                    _tables = _currentUser.tables.array.mutableCopy;
                }
                [self.tableView reloadData];
                [self endRefresh];
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get user art: %@",error.description);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to load your art. Please try again soon." delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil] show];
            
            [self endRefresh];
        }];
    }
}
- (void)endRefresh {
    loading = NO;
    [ProgressHUD dismiss];
    if (tableViewRefresh.isRefreshing){
        [tableViewRefresh endRefreshing];
    }
    if (collectionViewRefresh.isRefreshing){
        [collectionViewRefresh endRefreshing];
    }
}

- (void)add {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        settings = NO; metadata = NO; _login = NO; groupBool = NO;
        newArt = YES;
        WFNewArtViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"NewArt"];
        //UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        vc.transitioningDelegate = self;
        vc.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:vc animated:YES completion:^{
            
        }];
    } else {
        [self showLogin];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
            break;
        case 1:
            if (_tables.count){
                return _tables.count;
            } else {
                return 1;
            }
            break;
        case 2:
            return 1;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFMainTableCell *cell = (WFMainTableCell *)[tableView dequeueReusableCellWithIdentifier:@"MainCell"];

    if (indexPath.section == 0){
        if (indexPath.row == 0){
            [cell.imageView setImage:[UIImage imageNamed:@"whiteLock"]];
            [cell.textLabel setText:@"Private"];
        } else {
            [cell.imageView setImage:[UIImage imageNamed:@"whiteFavorite"]];
            [cell.textLabel setText:@"Favorites"];
        }
        
    } else if (indexPath.section == 1){
        if (_tables.count){
            Table *table;
            table = _tables[indexPath.row];
            [cell configureForTable:table];
            [cell.textLabel setText:@""];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        } else {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
            [cell.textLabel setText:@"No Light Tables"];
            [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
        }
        
    } else {
        [cell.imageView setImage:[UIImage imageNamed:@"whitePlus"]];
        [cell.textLabel setText:@"Light Table"];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1){
        return 34;
    } else {
        return 0;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGFloat headerHeight = (section == 1 ? 34.f : 0.f);
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, headerHeight)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    if (section == 1){
        UILabel *headerLabel = [[UILabel alloc] init];
        [headerView addSubview:headerLabel];
        [headerLabel setFrame:CGRectMake(10, 0, width-10, headerHeight)];
        [headerLabel setBackgroundColor:[UIColor clearColor]];
        [headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption1 forFont:kMuseoSans] size:0]];
        [headerLabel setTextColor:[UIColor colorWithWhite:1 alpha:.7]];
        [headerLabel setText:@"TABLES"];
    }
    
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0){
        if (indexPath.row == 0){
            [self showPrivateArt];
        } else {
            [self showFavorites];
        }
    } else if (indexPath.section == 1 && _currentUser.tables.count){
        Table *table = _currentUser.tables[indexPath.row];
        [self showTable:table];
    } else if (indexPath.section == 2){
        [self showNewLightTable];
    } else {
        
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)resetArtBooleans {
    showPrivate = NO;
    showFavorites = NO;
    showLightTable = NO;
}

- (void)showPrivateArt {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        if (showPrivate){
            [self resetArtBooleans];
        } else {
            [self resetArtBooleans];
            showPrivate = YES;
        }
        [self.collectionView reloadData];
    } else {
        [self showLogin];
    }
}

- (void)showFavorites {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        if (showFavorites){
            [self resetArtBooleans];
        } else {
            [self resetArtBooleans];
            showFavorites = YES;
        }
        [self.collectionView reloadData];
    } else {
        [self showLogin];
    }
}

- (void)showTable:(Table*)table {
    if (showLightTable){
        [self resetArtBooleans];
    } else {
        [self resetArtBooleans];
        showLightTable = YES;
    }
    _table = table;
    [self loadLightTable:_table];
}

- (void)loadLightTable:(Table*)table {
    if (!loading && table && ![table.identifier isEqualToNumber:@0]){
        [ProgressHUD show:@"Loading table..."];
        loading = YES;
        [manager GET:[NSString stringWithFormat:@"light_tables/%@",table.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success loading light table: %@",responseObject);
            [table populateFromDictionary:[responseObject objectForKey:@"table"]];
            [self.collectionView reloadData];
            [self endRefresh];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error loading light table: %@",error.description);
            [self endRefresh];
            [self.collectionView reloadData];
        }];
    }
}

- (void) showNewLightTable {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        WFNewLightTableController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"NewLightTable"];
        //UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        vc.modalPresentationStyle = UIModalPresentationCustom;
        vc.transitioningDelegate = self;
        [self resetTransitionBooleans];
        newArt = YES;
        [self presentViewController:vc animated:YES completion:^{
            
        }];
    } else {
        [self showLogin];
    }
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        if (tableIsVisible){
            return CGSizeMake((width-kSidebarWidth)/3,(width-kSidebarWidth)/3);
        } else {
            return CGSizeMake(width/4, width/4);
        }
    } else {
        return CGSizeMake(width/3,width/3);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    if (showPrivate){
        return _privateArts.count;
    } else if (showLightTable){
        return _table.arts.count;
    } else if (showFavorites){
        return _favorites.count;
    } else {
        return _arts.count;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    UICollectionReusableView *reusableview = nil;
    if (kind == UICollectionElementKindSectionHeader) {
        WFCatalogHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        if (showPrivate){
            [headerView.headerLabel setText:@"My Private Art"];
        } else if (showLightTable) {
            [headerView.headerLabel setText:[NSString stringWithFormat:@"\"%@\" Art",_table.name]];
        } else if (showFavorites) {
            [headerView.headerLabel setText:@"My Favorites"];
        }
        [headerView.headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
        [headerView.headerLabel setTextColor:[UIColor blackColor]];
        reusableview = headerView;
    }
    
    if (kind == UICollectionElementKindSectionFooter) {
        UICollectionReusableView *footerview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
        reusableview = footerview;
    }
    
    return reusableview;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (showFavorites || showLightTable || showPrivate){
        return CGSizeMake(collectionView.frame.size.width, 34);
    } else {
        return CGSizeMake(0, 0);
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFArtCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ArtCell" forIndexPath:indexPath];
    Art *art;
    if (showPrivate){
        art = _privateArts[indexPath.item];
    } else if (showLightTable){
        art = _table.arts[indexPath.item];
    } else if (showFavorites){
        art = _favorites[indexPath.item];
    } else {
        art = _arts[indexPath.item];
    }
    [cell configureForArt:art];
    if ([selectedSlides containsObject:art]){
        [cell.checkmark setHidden:NO];
    } else {
        [cell.checkmark setHidden:YES];
    }
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == _collectionView){
        float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
        if (bottomEdge >= scrollView.contentSize.height) {
            // at the bottom of the scrollView
            if (canLoadMoreArt){
                [self loadArt];
            }
        }
    }
}

- (IBAction)longPressed:(UILongPressGestureRecognizer*)sender {
    CGPoint loc = [sender locationInView:self.collectionView];
    CGFloat heightInScreen = fmodf((loc.y-self.collectionView.contentOffset.y), CGRectGetHeight(self.collectionView.frame));
    CGFloat hoverOffset;
    tableIsVisible ? (hoverOffset = kSidebarWidth) : (hoverOffset = 0);
    CGPoint locInScreen = CGPointMake( loc.x - self.collectionView.contentOffset.x + hoverOffset, heightInScreen );
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.startIndex = [self.collectionView indexPathForItemAtPoint:loc];
        
        if (self.startIndex) {
            WFArtCell *cell = (WFArtCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
            self.dragViewStartLocation = [self.view convertPoint:cell.center fromView:nil];
            
            Art *art;
            if (showPrivate){
                art = _privateArts[self.startIndex.item];
            } else if (showLightTable){
                art = _table.arts[self.startIndex.item];
            } else if (showFavorites){
                art = _favorites[self.startIndex.item];
            } else {
                art = _arts[self.startIndex.item];
            }
            self.draggingView = [[WFInteractiveImageView alloc] initWithImage:[cell getRasterizedImageCopy] andArt:art];
            [cell.contentView setAlpha:0.23f];
            
            CGPoint centerPoint = [self.view convertPoint:locInScreen fromView:nil];
            NSLog(@"center point: %f, %f",centerPoint.x, centerPoint.y);
            
            [self.view addSubview:self.draggingView];
            [self.view bringSubviewToFront:self.draggingView];
            self.draggingView.center = centerPoint;
        }
    }
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        self.draggingView.center = locInScreen;
    }
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        // comparison mode
        // 128 is half the width of an art slide, since the point we're grabbing is a center point, not the origin
        if (loc.x < (kSidebarWidth - 128) && loc.y > (_comparisonContainerView.frame.origin.y - 128)){
            if (comparison1){
                comparison2 = [[WFInteractiveImageView alloc] initWithFrame:CGRectMake(comparison1.frame.size.width+comparison1.frame.origin.x+10, 10, 125, 130) andArt:self.draggingView.art];
                NSLog(@"what is comparison 2? %@",comparison2.art.title);
                [comparison2 sd_setImageWithURL:[NSURL URLWithString:self.draggingView.art.photo.mediumImageUrl]];
                comparison2.clipsToBounds = NO;
                [_comparisonContainerView addSubview:comparison2];
                
            } else {
                comparison1 = [[WFInteractiveImageView alloc] initWithFrame:CGRectMake(10, 10, 125, 130) andArt:self.draggingView.art];
                [comparison1 sd_setImageWithURL:[NSURL URLWithString:self.draggingView.art.photo.mediumImageUrl]];
                comparison1.clipsToBounds = NO;
                [_comparisonContainerView addSubview:comparison1];
            }
            [self resetComparisonLabel];
            [self resetDraggingView];
        } else if (self.draggingView) {
            self.moveToIndexPath = [self.collectionView indexPathForItemAtPoint:loc];
            if (self.moveToIndexPath) {
        
                WFArtCell *movedCell = (WFArtCell*)[self.collectionView cellForItemAtIndexPath:self.moveToIndexPath];
                CGPoint moveToPoint = [self.view convertPoint:movedCell.center fromView:nil];
                
                WFArtCell *oldIndexCell = (WFArtCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
                
                NSNumber *thisNumber = [_arts objectAtIndex:self.startIndex.row];
                [_arts removeObjectAtIndex:self.startIndex.row];
                if (self.moveToIndexPath.row < self.startIndex.row) {
                    [_arts insertObject:thisNumber atIndex:self.moveToIndexPath.row];
                } else {
                    [_arts insertObject:thisNumber atIndex:self.moveToIndexPath.row];
                }
                
                [UIView animateWithDuration:.23f animations:^{
                    self.draggingView.center = moveToPoint;
                    [self.draggingView setAlpha:0.0];
                    [oldIndexCell.contentView setAlpha:1.f];
                    [movedCell.contentView setAlpha:1.f];
                } completion:^(BOOL finished) {
                    [self.draggingView removeFromSuperview];
                    self.draggingView = nil;
                    self.startIndex = nil;
                }];
                
                //change items
                __weak typeof(self) weakSelf = self;
                [self.collectionView performBatchUpdates:^{
                    __strong typeof(self) strongSelf = weakSelf;
                    if (strongSelf) {
                        [strongSelf.collectionView deleteItemsAtIndexPaths:@[ self.startIndex ]];
                        [strongSelf.collectionView insertItemsAtIndexPaths:@[ strongSelf.moveToIndexPath ]];
                    }
                } completion:^(BOOL finished) {
                    
                }];
            } else {
                [self resetDraggingView];
            }
            
            loc = CGPointZero;
        }
    }
}

- (void)shouldCompare {
    if (comparison1 && comparison2){
        [self resetTransitionBooleans];
        comparison = YES;
        
        NSLog(@"should be comparing: %@ and %@",comparison1.art.title, comparison2.art.title);
        WFComparisonViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Comparison"];
        vc.arts = [NSMutableOrderedSet orderedSetWithArray:@[comparison1.art, comparison2.art]];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    }
}

- (void)resetComparisonLabel {
    if (comparison2 || comparison1){
        [_dragForComparisonLabel setHidden:YES];
    } else {
        [_dragForComparisonLabel setHidden:NO];
    }
}

- (void)resetDraggingView {
    WFArtCell *cell = (WFArtCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
    [UIView animateWithDuration:.23f animations:^{
        [self.draggingView setAlpha:0.0];
        [cell.contentView setAlpha:1.f];
    } completion:^(BOOL finished) {
        [self.draggingView removeFromSuperview];
        self.draggingView = nil;
        self.startIndex = nil;
    }];
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Art *art;
    if (showPrivate){
        art = _privateArts[indexPath.item];
    } else if (showLightTable){
        art = _table.arts[indexPath.item];
    } else if (showFavorites){
        art = _favorites[indexPath.item];
    } else {
        art = _arts[indexPath.item];
    }
    
    if (searching && tableIsVisible){
        //WFArtCell *selectedCell = (WFArtCell*)[collectionView cellForItemAtIndexPath:indexPath];
        if ([selectedSlides containsObject:art]){
            [selectedSlides removeObject:art];
        } else {
            [selectedSlides addObject:art];
        }
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        [self showMetadata:art];
    }
}

- (void)showMetadata:(Art*)art{
    WFArtMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ArtMetadata"];
    [vc setArt:art];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    [self resetTransitionBooleans];
    metadata = YES;
    
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

- (void)dismissMetadata {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Custom Transitions 

- (void)showLogin {
    WFLoginViewController *login = [[self storyboard] instantiateViewControllerWithIdentifier:@"Login"];
    delegate.loginDelegate = self;
    login.modalPresentationStyle = UIModalPresentationCustom;
    login.transitioningDelegate = self;
    [self resetTransitionBooleans];
    _login = YES;
    
    [self presentViewController:login animated:YES completion:^{
        
    }];
}

- (void)showNotifications:(id)sender {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    WFNotificationsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Notifications"];
    //vc.notificationsDelegate = self;
    vc.preferredContentSize = CGSizeMake(430, 500);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    //[self.popover setBackgroundColor:[UIColor clearColor]];
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)settingsPopover:(id)sender {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    WFMenuViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Menu"];
    vc.menuDelegate = self;
    vc.preferredContentSize = CGSizeMake(230, 216);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)resetTransitionBooleans {
    settings = NO;
    newArt = NO;
    metadata = NO;
    comparison = NO;
    _login = NO;
    notificationsBool = NO;
    groupBool = NO;
}

- (void)showSettings {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        [self resetTransitionBooleans];
        settings = YES;
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

- (void)logout {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    _currentUser = nil;
    [self setUpNavBar];
    [self loadArt];
}

- (void)showPresentations {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        WFSlideshowsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Slideshows"];
        vc.presentationDelegate = self;
        vc.preferredContentSize = CGSizeMake(320, 400);
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        self.popover.delegate = self;
        [self.popover setBackgroundColor:[UIColor blackColor]];
        
        [self.popover presentPopoverFromBarButtonItem:presentationsBarButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self showLogin];
    }
}

- (void)newPresentation {
    [self.popover dismissPopoverAnimated:YES];
    WFSlideshowSplitViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideshowSplitView"];
    Presentation *presentation = [Presentation MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    if (_currentUser){
        presentation.user = _currentUser;
    }
    [vc setPresentation:presentation];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self resetTransitionBooleans];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)presentationSelected:(Presentation *)presentation {
    [self.popover dismissPopoverAnimated:YES];
    WFSlideshowSplitViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideshowSplitView"];
    [vc setPresentation:presentation];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self resetTransitionBooleans];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}


- (void)showLightTables {
    if (tableIsVisible){
        //hide the light table sidebar
        CGRect collectionFrame = _collectionView.frame;
        collectionFrame.origin.x = 0;
        collectionFrame.size.width += kSidebarWidth;
        tableIsVisible = NO;
        tablesButton.selected = NO;
        
        [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.000001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _tableView.transform = CGAffineTransformIdentity;
            _comparisonContainerView.transform = CGAffineTransformIdentity;
            [_collectionView setFrame:collectionFrame];
            [_collectionView performBatchUpdates:^{
                [_collectionView reloadData];
            } completion:^(BOOL finished) { }];
            
        } completion:^(BOOL finished) {
            
        }];
    } else {
        //show the light table sidebar
        CGRect collectionFrame = _collectionView.frame;
        collectionFrame.origin.x = kSidebarWidth;
        collectionFrame.size.width -= kSidebarWidth;
        tableIsVisible = YES;
        tablesButton.selected = YES;
        
        if (!selectedSlides) selectedSlides = [NSMutableOrderedSet orderedSet];
        
        [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.00001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _tableView.transform = CGAffineTransformMakeTranslation(kSidebarWidth, 0);
            _comparisonContainerView.transform = CGAffineTransformMakeTranslation(kSidebarWidth, 0);
            [_collectionView setFrame:collectionFrame];            
            [_collectionView performBatchUpdates:^{
                [_collectionView reloadData];
            } completion:^(BOOL finished) { }];
            
        } completion:^(BOOL finished) {
            
        }];
    }
    
    /*WFTablesViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Groups"];
    settings = NO; newArt = NO; metadata = NO; _login = NO;
    groupBool = YES;
    
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:vc animated:YES completion:^{
        
    }];*/
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
    } else if (newArt) {
        WFNewArtAnimator *animator = [WFNewArtAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (_login) {
        WFLoginAnimator *animator = [WFLoginAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (comparison) {
        WFSlideshowFocusAnimator *animator = [WFSlideshowFocusAnimator new];
        animator.presenting = YES;
        return animator;
    } else {
        WFSlideshowAnimator *animator = [WFSlideshowAnimator new];
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
    } else if (newArt) {
        WFNewArtAnimator *animator = [WFNewArtAnimator new];
        return animator;
    } else if (_login) {
        WFLoginAnimator *animator = [WFLoginAnimator new];
        return animator;
    } else if (comparison) {
        WFSlideshowFocusAnimator *animator = [WFSlideshowFocusAnimator new];
        return animator;
    } else {
        WFSlideshowAnimator *animator = [WFSlideshowAnimator new];
        return animator;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self.searchBar endEditing:YES];
    searching = NO;
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:^{
       
    }];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    searching = YES;
    searchResultsVc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SearchResults"];
    searchResultsVc.preferredContentSize = CGSizeMake(self.searchBar.frame.size.width-40, 400);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:searchResultsVc];
    self.popover.delegate = self;
    [self.popover presentPopoverFromRect:self.navigationItem.titleView.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    NSLog(@"Search text did change: %@",searchText);
    if (searchResultsVc){
        [searchResultsVc filterContentForSearchText:searchText scope:nil];
    }
    //[self filterContentForSearchText:searchText scope:nil];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    if (!_filteredArts){
        _filteredArts = [NSMutableArray array];
    } else {
        [_filteredArts removeAllObjects];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", searchText];
    
    for (Art *art in _arts){
        if([predicate evaluateWithObject:art.title]) {
            [_filteredArts addObject:art];
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
