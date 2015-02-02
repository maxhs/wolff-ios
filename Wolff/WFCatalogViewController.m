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
#import "WFPhotoCell.h"
#import "WFArtMetadataAnimator.h"
#import "WFArtMetadataViewController.h"
#import "WFMainTableCell.h"
#import "WFSettingsViewController.h"
#import "WFLoginAnimator.h"
#import "WFLoginViewController.h"
#import "WFSlideshowsViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "WFSettingsAnimator.h"
#import "WFTablesAnimator.h"
#import "WFLightTablesViewController.h"
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
#import "WFDismissableNavigationController.h"
#import "WFNewLightTableAnimator.h"
#import "WFLightTableDetailsViewController.h"
#import "WFWalkthroughViewController.h"
#import "WFWalkthroughAnimator.h"
#import "WFProfileAnimator.h"
#import "WFProfileViewController.h"
#import "WFSlideshowCell.h"
#import "WFAlert.h"
#import "WFUtilities.h"
#import "WFSlideshowViewController.h"

@interface WFCatalogViewController () <UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIViewControllerTransitioningDelegate,UIPopoverControllerDelegate, UIAlertViewDelegate, WFLoginDelegate, WFMenuDelegate,  WFSlideshowDelegate, WFImageViewDelegate, WFSearchDelegate, WFMetadataDelegate, WFNewArtDelegate, WFLightTableDelegate, WFSlideshowCellDelegate, WFLightTableCellDelegate, UIGestureRecognizerDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    UIButton *homeButton;
    UIBarButtonItem *homeBarButton;
    UIButton *slideshowsButton;
    UIBarButtonItem *slideshowsBarButton;
    UIButton *tablesButton;
    UIBarButtonItem *lightTablesButton;
    UIBarButtonItem *notificationsButton;
    UIBarButtonItem *refreshButton;
    CGFloat width;
    CGFloat height;
    NSMutableArray *_photos;
    NSMutableOrderedSet *_privatePhotos;
    NSMutableOrderedSet *_favoritePhotos;
    NSMutableArray *_filteredPhotos;
    NSMutableArray *_tables;
    NSMutableArray *_slideshows;
    NSMutableArray *_filteredTables;
    UIBarButtonItem *addButton;
    UIBarButtonItem *settingsButton;
    UILabel *selectedLabel;
    UIImageView *checkboxView;
    UIBarButtonItem *selectedBarButtonItem;
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
    BOOL newUser;
    BOOL profile;
    BOOL newLightTableTransition;
    BOOL notificationsBool;
    BOOL groupBool;
    BOOL tableIsVisible;
    BOOL canLoadMorePhotos;
    BOOL showSlideshow;
    BOOL showPrivate;
    BOOL showFavorites;
    BOOL showLightTable;
    BOOL iOS8;
    BOOL slideshowSidebarMode;
    Table *_table;
    CGFloat topInset;
    UIRefreshControl *tableViewRefresh;
    UIRefreshControl *collectionViewRefresh;
    NSMutableOrderedSet *_selectedPhotos;
    
    UILongPressGestureRecognizer *comparison1LongPress;
    UILongPressGestureRecognizer *comparison2LongPress;
    UILongPressGestureRecognizer *catalogLongPress;
    UITapGestureRecognizer *catalogDoubleTap;
    UITapGestureRecognizer *comparisonTap;
    
    NSIndexPath *indexPathForFavoriteToRemove;
    NSIndexPath *indexPathForLightTableArtToRemove;
    WFInteractiveImageView *comparison1;
    WFInteractiveImageView *comparison2;
    
    WFSearchResultsViewController *searchResultsVc;
    NSString *searchText;
    UIButton *resetButton;
    UIImageView *navBarShadowView;
}
@property (weak, nonatomic) IBOutlet UIView *comparisonContainerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *noSearchResultsLabel;
@property (weak, nonatomic) IBOutlet UILabel *dragForComparisonLabel;
@property (nonatomic) WFInteractiveImageView *draggingView;
@property (nonatomic) NSIndexPath *startIndex;
@property (nonatomic) CGPoint dragViewStartLocation;
@property (nonatomic) NSIndexPath *moveToIndexPath;
@property (nonatomic, strong) id<WFLightTablesDelegate> groupsInteractor;
@end

@implementation WFCatalogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
    }
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    _photos = [NSMutableArray array];
    _privatePhotos = [NSMutableOrderedSet orderedSet];
    _favoritePhotos = [NSMutableOrderedSet orderedSet];
    
    if (!_selectedPhotos) _selectedPhotos = [NSMutableOrderedSet orderedSet];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"art.privateArt = %@",@NO];
    _photos = [Photo MR_findAllSortedBy:@"createdDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
    
    //set up the nav buttons
    [self setUpNavBar];
    
    //set up the light table sidebar
    expanded = NO;
    [self setUpTableView];
    [self setUpGestureRecognizers];
    
    [_comparisonContainerView setBackgroundColor:[UIColor colorWithWhite:0 alpha:.9f]];
    _dragForComparisonLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansThin] size:0];
    [_dragForComparisonLabel setTextColor:[UIColor colorWithWhite:.7f alpha:.6f]];
    
    /*self.groupsInteractor = [[WFGroupsInteractor alloc] initWithParentViewController:self];
    UIScreenEdgePanGestureRecognizer *gestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self.groupsInteractor action:@selector(userDidPan:)];
    gestureRecognizer.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:gestureRecognizer];*/
    
    _collectionView.delaysContentTouches = NO;
    [_collectionView setBackgroundColor:[UIColor whiteColor]];
    collectionViewRefresh = [[UIRefreshControl alloc] init];
    [collectionViewRefresh addTarget:self action:@selector(refreshCollectionView:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:collectionViewRefresh];
    canLoadMorePhotos = YES;
    
    [self setUpSearch];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccessful) name:@"LoginSuccessful" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loggedOut) name:@"LoggedOut" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideEditMenu:) name:UIMenuControllerWillHideMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHideEditMenu:) name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)setUpGestureRecognizers {
    catalogLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    catalogLongPress.minimumPressDuration = .23f;
    [_collectionView addGestureRecognizer:catalogLongPress];
    
    catalogDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    catalogDoubleTap.numberOfTapsRequired = 2;
    [_collectionView addGestureRecognizer:catalogDoubleTap];
    
    comparisonTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shouldCompare)];
    comparisonTap.numberOfTapsRequired = 1;
    [_comparisonContainerView addGestureRecognizer:comparisonTap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    if (_currentUser){
        [self loadUserDashboard];
        if (!tableViewRefresh){
            tableViewRefresh = [[UIRefreshControl alloc] init];
            [tableViewRefresh addTarget:self action:@selector(refreshTableView:) forControlEvents:UIControlEventValueChanged];
        }
        [self.tableView addSubview:tableViewRefresh];
    }
    [self loadPhotos];
    navBarShadowView.hidden = YES;
    
    if (tableIsVisible){
        [self.tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showWalkthrough];
}

- (void)showWalkthrough {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kExistingUser]){
        double delayInSeconds = .23f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [ProgressHUD dismiss];
            newUser = YES;
            WFWalkthroughViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Walkthrough"];
            vc.modalPresentationStyle = UIModalPresentationCustom;
            vc.transitioningDelegate = self;
            [self presentViewController:vc animated:YES completion:^{
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kExistingUser];
            }];
        });
    }
}

- (void)refreshTableView:(UIRefreshControl*)refreshControl {
    if (_currentUser){
        [ProgressHUD show:@"Refreshing..."];
        [self loadUserDashboard];
    }
}

- (void)refreshCollectionView:(id)sender {
    [ProgressHUD show:@"Refreshing Art..."];
    [_photos removeAllObjects];
    canLoadMorePhotos = YES;
    [self loadPhotos];
}

- (void)setUpTableView {
    [_tableView setBackgroundColor:[UIColor blackColor]];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tableView.rowHeight = 60.f;
}

- (void)setUpNavBar {
    homeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    homeButton.frame = CGRectMake(14.0, 0.0, 66.0, 44.0);
    [homeButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.1975f]];
    [homeButton setImage:[UIImage imageNamed:@"homeIcon"] forState:UIControlStateNormal];
    [homeButton addTarget:self action:@selector(resetCatalog) forControlEvents:UIControlEventTouchUpInside];
    homeBarButton = [[UIBarButtonItem alloc] initWithCustomView:homeButton];
    
    tablesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [tablesButton setImage:[UIImage imageNamed:@"whiteTables"] forState:UIControlStateNormal];
    [tablesButton setImage:[UIImage imageNamed:@"blueTables"] forState:UIControlStateSelected];
    tablesButton.frame = CGRectMake(8.0, 0.0, 58.0, 44.0);
    tablesButton.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
    [tablesButton addTarget:self action:@selector(showLightTables) forControlEvents:UIControlEventTouchUpInside];
    lightTablesButton = [[UIBarButtonItem alloc] initWithCustomView:tablesButton];
    
    slideshowsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    slideshowsButton.frame = CGRectMake(0.0, 0.0, 74.0, 44.0);
    [slideshowsButton setImage:[UIImage imageNamed:@"whiteSlideshow"] forState:UIControlStateNormal];
    [slideshowsButton setImage:[UIImage imageNamed:@"saffronSlideshow"] forState:UIControlStateSelected];
    [slideshowsButton addTarget:self action:@selector(showSlideshows) forControlEvents:UIControlEventTouchUpInside];
    slideshowsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 22);
    slideshowsBarButton = [[UIBarButtonItem alloc] initWithCustomView:slideshowsButton];
    
    UIBarButtonItem *negativeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeButton.width = -20.f;
    
    self.navigationItem.leftBarButtonItems = @[negativeButton, homeBarButton, lightTablesButton,slideshowsBarButton];
    
    refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshCollectionView:)];
    addButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"plus"] style:UIBarButtonItemStylePlain target:self action:@selector(add)];
    
    UIView *customSelectedView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 38, 44)];
    selectedLabel = [[UILabel alloc] init];
    [selectedLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSansSemibold] size:0]];
    [customSelectedView addSubview:selectedLabel];
    [selectedLabel setFrame:CGRectMake(29, 5, 20, 20)];
    [selectedLabel setBackgroundColor:[UIColor clearColor]];
    
    checkboxView = [[UIImageView alloc] initWithFrame:CGRectMake(11, 14, 16, 16)];
    [customSelectedView addSubview:checkboxView];
    [self configureSelectedButton];

    UIButton *selectedButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [selectedButton setBackgroundColor:[UIColor clearColor]];
    selectedButton.frame = customSelectedView.frame;
    [selectedButton addTarget:self action:@selector(showSelected) forControlEvents:UIControlEventTouchUpInside];
    
    [customSelectedView addSubview:selectedButton];
    selectedBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customSelectedView];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPopover:)];
        notificationsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"alert"] style:UIBarButtonItemStylePlain target:self action:@selector(showNotifications:)];
        
        self.navigationItem.rightBarButtonItems = @[addButton, selectedBarButtonItem, notificationsButton, settingsButton, refreshButton];
        
        //also ensure there's a pull to refresh
        if (!tableViewRefresh){
            tableViewRefresh = [[UIRefreshControl alloc] init];
            [tableViewRefresh addTarget:self action:@selector(refreshTableView:) forControlEvents:UIControlEventValueChanged];
            [self.tableView addSubview:tableViewRefresh];
        }
        
    } else {
        loginButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login"] style:UIBarButtonItemStylePlain target:self action:@selector(showLogin)];
        self.navigationItem.rightBarButtonItems = @[loginButton, addButton, refreshButton];
    }
    
    self.navigationItem.titleView = self.searchBar;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    topInset = self.navigationController.navigationBar.frame.size.height;
    self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
}

- (void)configureSelectedButton {
    if (_selectedPhotos.count){
        [selectedLabel setText:[NSString stringWithFormat:@"%lu",(unsigned long)_selectedPhotos.count]];
        [selectedLabel setTextColor:kElectricBlue];
        [checkboxView setImage:[UIImage imageNamed:@"blueCheckbox"]];
    } else {
        [selectedLabel setText:@"0"];
        [selectedLabel setTextColor:[UIColor whiteColor]];
        [checkboxView setImage:[UIImage imageNamed:@"whiteCheckbox"]];
    }
}

#pragma mark - Login
- (void)loginSuccessful {
    _currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    [self setUpNavBar];
    [self loadUserDashboard];
    if (tableIsVisible){
        [self.tableView reloadData];
    }
}

- (void)loggedOut {
    // reset the views now that we're logged out
    [self setUpNavBar];
    [self.tableView reloadData];
    _currentUser = nil;
}

- (void)loadPhotos {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@20 forKey:@"count"];
    if (_photos.count) {
        Photo *lastPhoto = _photos.lastObject;
        [parameters setObject:[NSNumber numberWithDouble:[lastPhoto.createdDate timeIntervalSince1970]] forKey:@"before_date"];
    } else {
        [ProgressHUD show:@"Loading art..."];
    }
    if (searching && searchText && searchText.length){
        [parameters setObject:searchText forKey:@"search"];
    }
    if (!loading){
        loading = YES;
        [manager GET:@"photos" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"load photos success: %@", responseObject);
            NSLog(@"photos count: %lu",(unsigned long)[[responseObject objectForKey:@"photos"] count]);
            if ([[responseObject objectForKey:@"photos"] count]){
                canLoadMorePhotos = YES;
                
                for (NSDictionary *dict in [responseObject objectForKey:@"photos"]) {
                    Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                    if (!photo){
                        photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [photo populateFromDictionary:dict];
                    [_photos addObject:photo];
                }
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    //NSLog(@"Done saving photos: %u",success);
                }];
            } else {
                canLoadMorePhotos = NO;
                NSLog(@"Can't load any more photo. We got it all!");
            }
            [self.collectionView reloadData];
            [self endRefresh];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self endRefresh];
        }];
    }
}

- (void)loadUserDashboard {
    if (_currentUser && !loading){
        loading = YES;
        [manager GET:[NSString stringWithFormat:@"users/%@/dashboard",_currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting user dashboard: %@", responseObject);
            [_currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                //set up private photos and favorites
                NSPredicate *privatePredicate = [NSPredicate predicateWithFormat:@"art.privateArt == %@ && art.user.identifier == %@", @YES, [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
                _privatePhotos = [Photo MR_findAllWithPredicate:privatePredicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
                [_currentUser.favorites enumerateObjectsUsingBlock:^(Favorite *favorite, NSUInteger idx, BOOL *stop) {
                    if (favorite.photo && ![_favoritePhotos containsObject:favorite.photo]) {
                        [_favoritePhotos addObject:favorite.photo];
                    }
                }];

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
        vc.artDelegate = self;
        //UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        vc.transitioningDelegate = self;
        vc.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:vc animated:YES completion:^{
            
        }];
    } else {
        [self showLogin];
    }
}

- (void)newArtAdded:(Art *)art {
    if ([art.privateArt isEqualToNumber:@NO]){
        //don't animate the changes if the user is looking at a light table, their private art, their favorites, or searching.
        if (!showFavorites && !showLightTable && !searching && !showPrivate){
            [_collectionView performBatchUpdates:^{
                NSMutableArray *indexPathArray = [NSMutableArray array];
                for (Photo *photo in art.photos){
                    [_photos insertObject:photo atIndex:0];
                    [indexPathArray addObject:[NSIndexPath indexPathForItem:0 inSection:0]];
                }
                [_collectionView insertItemsAtIndexPaths:indexPathArray];
            } completion:^(BOOL finished) {
                
            }];
        }
    }
}

- (void)failedToAddArt:(Art*)art {
    [WFAlert show:[NSString stringWithFormat:@"Something went wrong while trying to add \"%@\" to the catalog. Please try again soon.",art.title] withTime:3.3f];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (slideshowSidebarMode){
        _slideshows = [NSMutableArray arrayWithArray:[Slideshow MR_findAll]];
        NSSortDescriptor *alphabeticalSlideshowSort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        [_slideshows sortUsingDescriptors:[NSArray arrayWithObject:alphabeticalSlideshowSort]];
        return 2;
    } else {
        _tables = _tables ? _currentUser.lightTables.array.mutableCopy : [NSMutableArray arrayWithArray:_currentUser.lightTables.array];
        NSSortDescriptor *alphabeticalTableSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [_tables sortUsingDescriptors:[NSArray arrayWithObject:alphabeticalTableSort]];
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (slideshowSidebarMode){
        if (section == 0){
            return _slideshows.count;
        } else {
            return 1;
        }
    } else {
        switch (section) {
            case 0:
                return 2;
                break;
            case 1:
                if (_tables.count){
                    return _tables.count;
                } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
                    return 1;
                } else {
                    return 0;
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
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (slideshowSidebarMode){
        WFSlideshowCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SlideshowCell" forIndexPath:indexPath];
        cell.delegate = self;
        [cell setBackgroundColor:[UIColor clearColor]];
        if (indexPath.section == 0){
            cell.tintColor = [UIColor whiteColor];
            [cell.scrollView setScrollEnabled:YES];
            [cell.contentView addGestureRecognizer:cell.scrollView.panGestureRecognizer];
            if (!loading && _slideshows.count == 0){
                [cell.slideshowLabel setText:@"No Slideshows"];
                [cell.slideshowLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                [cell.imageView setImage:nil];
                [cell.textLabel setText:@""];
            } else {
                Slideshow *slideshow = _slideshows[indexPath.row];
                [cell configureForSlideshow:slideshow];
            }
            
        } else {
            [cell.imageView setImage:[UIImage imageNamed:@"whitePlus"]];
            [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
            [cell.textLabel setText:@"New Slideshow"];
            [cell.scrollView setScrollEnabled:NO];
        }
        
        // ensure the labels are the right color. this cell is also being used on the Slideshows view, and the label text there is black
        [cell.textLabel setTextColor:[UIColor whiteColor]];
        [cell.slideshowLabel setTextColor:[UIColor whiteColor]];
        return cell;
    } else {
        WFMainTableCell *cell = (WFMainTableCell *)[tableView dequeueReusableCellWithIdentifier:@"MainCell"];
        [cell setBackgroundColor:[UIColor clearColor]];
        cell.delegate = self;
        
        if (indexPath.section == 0){
            [cell.scrollView setScrollEnabled:NO];
            if (indexPath.row == 0){
                [cell.iconImageView setImage:[UIImage imageNamed:@"whiteLock"]];
                [cell.label setText:@"Private"];
            } else {
                [cell.iconImageView setImage:[UIImage imageNamed:@"whiteFavorite"]];
                [cell.label setText:@"Favorites"];
            }
            
        } else if (indexPath.section == 1){
            [cell.scrollView setScrollEnabled:YES];
            if (_tables.count){
                Table *table = _tables[indexPath.row];
                [cell configureForTable:table];
                [cell.label setText:@""];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                [cell.actionButton setUserInteractionEnabled:YES];
                
            } else {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
                    [cell.label setText:@"No Light Tables"];
                    [cell.label setTextAlignment:NSTextAlignmentLeft];
                    [cell.label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThinItalic] size:0]];
                } else {
                    [cell.label setText:@"Sign in to create a light table"];
                }
            }
            [cell.iconImageView setImage:nil];
            
        } else {
            [cell.iconImageView setImage:[UIImage imageNamed:@"whitePlus"]];
            [cell.label setText:@"Light Table"];
            [cell.label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
            [cell.scrollView setScrollEnabled:NO];
        }
        
        return cell;
    }
}

- (void)deleteLightTable:(NSNumber*)lightTableId {
    Table *lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:lightTableId inContext:[NSManagedObjectContext MR_defaultContext]];
    NSIndexPath *indexPathToRemove = [NSIndexPath indexPathForRow:[_tables indexOfObject:lightTable] inSection:1];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    if (lightTable && ![lightTable.identifier isEqualToNumber:@0]){
        [manager DELETE:[NSString stringWithFormat:@"light_tables/%@",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
            [self.tableView beginUpdates];
            [_tables removeObject:lightTable];
            [lightTable MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (_tables.count && indexPathToRemove){
                    [self.tableView deleteRowsAtIndexPaths:@[indexPathToRemove] withRowAnimation:UITableViewRowAnimationAutomatic];
                } else {
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                [self.tableView endUpdates];
            }];
            NSLog(@"Success deleting this light table: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete this light table: %@",error.description);
        }];
    } else {
        [self.tableView beginUpdates];
        [_tables removeObject:lightTable];
        if (_tables.count){
            [self.tableView deleteRowsAtIndexPaths:@[indexPathToRemove] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tableView endUpdates];
        
        [lightTable MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
        }];
    }
}

- (void)editLightTable:(NSNumber *)lightTableId {
    Table *lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:lightTableId inContext:[NSManagedObjectContext MR_defaultContext]];
    WFLightTableDetailsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"LightTableDetails"];
    [vc setTableId:lightTable.identifier];
    vc.lightTableDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    vc.transitioningDelegate = self;
    [self resetTransitionBooleans];
    newLightTableTransition = YES;
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

- (void)leaveLightTable:(NSNumber *)lightTableId {
    Table *lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:lightTableId inContext:[NSManagedObjectContext MR_defaultContext]];
    NSIndexPath *indexPathToRemove = [NSIndexPath indexPathForRow:[_tables indexOfObject:lightTable] inSection:1];
    if (![lightTable.identifier isEqualToNumber:@0]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [manager DELETE:[NSString stringWithFormat:@"light_tables/%@/leave",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success leaving table: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error leaving light table: %@",error.description);
        }];
    }
    
    [self.tableView beginUpdates];
    [_tables removeObject:lightTable];
    [lightTable MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    if (_tables.count && indexPathToRemove && indexPathToRemove.row != NSNotFound){
        [self.tableView deleteRowsAtIndexPaths:@[indexPathToRemove] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self.tableView endUpdates];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    searching = NO;
    [_noSearchResultsLabel setHidden:YES];
    if (slideshowSidebarMode){
        if (indexPath.section == 0){
            Slideshow *slideshow = _slideshows[indexPath.row];
            if ([slideshow.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
                [self slideshowSelected:slideshow];
            } else {
                NSLog(@"Play someone else's slideshow");
                WFSlideshowViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Slideshow"];
                [vc setSlideshow:slideshow];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                vc.transitioningDelegate = self;
                vc.modalPresentationStyle = UIModalPresentationCustom;
                [self presentViewController:nav animated:YES completion:^{
                    
                }];
            }
        } else {
            [self newSlideshow];
        }
    } else {
        if (indexPath.section == 0){
            [self setHomeAsReset];
            indexPath.row == 0 ? [self showPrivateArt] : [self showFavorites];
        } else if (indexPath.section == 1){
            if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
                if (_tables.count){
                    Table *table = _tables[indexPath.row];
                    [self showTable:table];
                    [self setHomeAsReset];
                }
            } else {
                [self showLogin];
            }
        } else if (indexPath.section == 2){
            [self newLightTable];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)deleteSlideshow:(NSNumber*)slideshowId {
    NSLog(@"slideshow id? %@",slideshowId);
    Slideshow *slideshow = [Slideshow MR_findFirstByAttribute:@"identifier" withValue:slideshowId inContext:[NSManagedObjectContext MR_defaultContext]];
    NSIndexPath *indexPathToRemove = [NSIndexPath indexPathForRow:[_slideshows indexOfObject:slideshow] inSection:0];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    [manager DELETE:[NSString stringWithFormat:@"slideshows/%@",slideshow.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success deleting this slideshow: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to delete this slideshow: %@",error.description);
    }];

    [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    [self.tableView beginUpdates];
    if (indexPathToRemove && indexPathToRemove.row != NSNotFound && _slideshows.count){
        [self.tableView deleteRowsAtIndexPaths:@[indexPathToRemove] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        _slideshows = [NSMutableArray arrayWithArray:[Slideshow MR_findAll]];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.tableView endUpdates];
}

- (void)removeSlideshow:(NSNumber *)slideshowId {
    Slideshow *slideshow = [Slideshow MR_findFirstByAttribute:@"identifier" withValue:slideshowId inContext:[NSManagedObjectContext MR_defaultContext]];
    NSIndexPath *indexPathToRemove = [NSIndexPath indexPathForRow:[_slideshows indexOfObject:slideshow] inSection:0];
    [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    [self.tableView beginUpdates];
    _slideshows = [NSMutableArray arrayWithArray:[Slideshow MR_findAll]];
    if (indexPathToRemove && indexPathToRemove.row != NSNotFound && _slideshows.count){
        [self.tableView deleteRowsAtIndexPaths:@[indexPathToRemove] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self.tableView endUpdates];
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
    if (showLightTable && [table.identifier isEqualToNumber:_table.identifier]){
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
        NSString *title = table.name.length ? [NSString stringWithFormat:@"\"%@\"",table.name] : @"\"table without a name\"";
        [ProgressHUD show:[NSString stringWithFormat:@"Loading %@",title]];
        loading = YES;
        [manager GET:[NSString stringWithFormat:@"light_tables/%@",table.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success loading light table: %@",responseObject);
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

#pragma mark - Light Table Delegate Section
- (void)newLightTable {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        WFLightTableDetailsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"LightTableDetails"];
        (_selectedPhotos.count) ? [vc setPhotos:_selectedPhotos] : [vc setShowKey:YES];
        vc.lightTableDelegate = self;
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            vc.modalPresentationStyle = UIModalPresentationCustom;
            vc.transitioningDelegate = self;
            [self resetTransitionBooleans];
            newLightTableTransition = YES;
            [self presentViewController:vc animated:YES completion:^{
                
            }];
        }];
    } else {
        [self showLogin];
    }
}

- (void)didJoinLightTable:(Table *)table {
    NSLog(@"just joined light table: %@",table.name);
    if (!slideshowSidebarMode && tableIsVisible){
        [_tables insertObject:table atIndex:0];
        [self.tableView reloadData];
    }
}

- (void)didCreateLightTable:(Table *)table {
    NSLog(@"just created a light table: %@",table.name);
    if (!slideshowSidebarMode && tableIsVisible){
        [_tables insertObject:table atIndex:0];
        [self.tableView reloadData];
    }
}

- (void)didSaveLightTable:(Table *)table {
    
}

- (void)didDeleteLightTable:(Table *)table {
    
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
        return _privatePhotos.count;
    } else if (showLightTable){
        return _table.photos.count;
    } else if (showFavorites){
        return _favoritePhotos.count;
    } else if (searching){
        if (_filteredPhotos.count > 0) {
            [_noSearchResultsLabel setHidden:YES];
        } else {
            [_noSearchResultsLabel setHidden:NO];
        }
        return _filteredPhotos.count;
    } else {
        return _photos.count;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (showFavorites || showLightTable || showPrivate || searching){
        return CGSizeMake(collectionView.frame.size.width, 54);
    } else {
        return CGSizeMake(1, 0);
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (kind == UICollectionElementKindSectionHeader) {
        WFCatalogHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        [headerView.headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
        if (showPrivate){
            [headerView.headerLabel setText:@"My Private Art"];
        } else if (showLightTable) {
            [headerView.headerLabel setText:[NSString stringWithFormat:@"\"%@\" Art",_table.name]];
        } else if (showFavorites) {
            [headerView.headerLabel setText:@"My Favorites"];
        } else if (searching) {
            if (searchText.length){
                [headerView.headerLabel setText:[NSString stringWithFormat:@"Search results for: %@",searchText]];
            } else {
                [headerView.headerLabel setText:@""];
            }
            [headerView.headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
        }
        
        [headerView.headerLabel setTextColor:[UIColor blackColor]];
        return headerView;
    } else {
        return nil;
    }
}

- (void)resetCatalog {
    if (tableIsVisible || searching || showFavorites || showLightTable || showPrivate){
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self resetArtBooleans];
            if (tableIsVisible){
                [self showSidebar];
            }
            searchText = @"";
            searching = NO;
            [_noSearchResultsLabel setHidden:YES];
            [self.searchBar setText:@""];
            [self.searchBar resignFirstResponder];
            [self.view endEditing:YES];
            [self.collectionView reloadData];
            [homeButton setImage:[UIImage imageNamed:@"homeIcon"] forState:UIControlStateNormal];
        });
    }
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    Photo *photo;
    if (showPrivate){
        photo = _privatePhotos[indexPath.item];
    } else if (showLightTable){
        photo = _table.photos[indexPath.item];
    } else if (showFavorites){
        photo = _favoritePhotos[indexPath.item];
    } else if (searching){
        photo = _filteredPhotos[indexPath.item];
    } else {
        photo = _photos[indexPath.item];
    }
    [cell configureForPhoto:photo];
    if ([_selectedPhotos containsObject:photo]){
        [cell.checkmark setHidden:NO];
    } else {
        [cell.checkmark setHidden:YES];
    }
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == _collectionView && !searching){
        float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
        if (bottomEdge >= scrollView.contentSize.height) {
            // at the bottom of the scrollView
            if (canLoadMorePhotos){
                [self loadPhotos];
            }
        }
    }
}

- (void)doubleTap:(UITapGestureRecognizer*)gestureRecognizer {
    CGPoint loc = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *selectedIndexPath = [_collectionView indexPathForItemAtPoint:loc];
    if (!selectedIndexPath) return;
    
    Photo *photo;
    if (showPrivate){
        photo = _privatePhotos[selectedIndexPath.item];
    } else if (showLightTable){
        photo = _table.photos[selectedIndexPath.item];
    } else if (showFavorites){
        photo = _favoritePhotos[selectedIndexPath.item];
    } else if (searching){
        if (_filteredPhotos.count){
            photo = _filteredPhotos[selectedIndexPath.item];
        }
    } else {
        photo = _photos[selectedIndexPath.item];
    }
    if (photo && selectedIndexPath){
        if ([_selectedPhotos containsObject:photo]){
            [_selectedPhotos removeObject:photo];
        } else {
            [_selectedPhotos addObject:photo];
        }
        [_collectionView reloadItemsAtIndexPaths:@[selectedIndexPath]];
        [selectedLabel setText:[NSString stringWithFormat:@"%lu",(unsigned long)_selectedPhotos.count]];
        [self configureSelectedButton];
    }
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *piece = gestureRecognizer.view;
        CGPoint locationInView = [gestureRecognizer locationInView:piece];
        CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview.superview];
        piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
        piece.center = locationInSuperview;
    }
}

- (void)removeFavorite:(UIMenuController*)menuController {
    Art *art = _favoritePhotos[indexPathForFavoriteToRemove.item];
    [_favoritePhotos removeObject:art];
    [_collectionView deleteItemsAtIndexPaths:@[indexPathForFavoriteToRemove]];
}

- (void)removeLightTablePhoto:(UIMenuController*)menuController {
    Photo *photo = _table.photos[indexPathForLightTableArtToRemove.item];
    [_table removePhoto:photo];
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [_collectionView deleteItemsAtIndexPaths:@[indexPathForLightTableArtToRemove]];
    }];
    
    [manager DELETE:[NSString stringWithFormat:@"light_tables/%@/remove",_table.identifier] parameters:@{@"photo_id":photo.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success removing photo from light table: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failed to remove photo from light table: %@",error.description);
    }];
}

- (void)addPhotoToLightTable:(Photo*)photo {
    NSIndexPath *newArtIndexPath = [NSIndexPath indexPathForItem:_table.photos.count inSection:0];
    [_table addPhoto:photo];
    [_collectionView insertItemsAtIndexPaths:@[newArtIndexPath]];
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
    }];
    [manager POST:[NSString stringWithFormat:@"light_tables/%@/add",_table.identifier] parameters:@{@"photo_id":photo.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success adding art from light table: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failed to add art from light table: %@",error.description);
    }];
}

- (void)longPressed:(UILongPressGestureRecognizer*)gestureRecognizer {
    CGPoint loc = [gestureRecognizer locationInView:self.collectionView];
    
    if (showFavorites && indexPathForFavoriteToRemove){
        //trying to interact with a favorite
        if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
            [self becomeFirstResponder];
            
            indexPathForFavoriteToRemove = [_collectionView indexPathForItemAtPoint:loc];
            NSString *menuItemTitle = NSLocalizedString(@"Remove", @"Remove this art from your favorites.");
            UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:menuItemTitle action:@selector(removeFavorite:)];
            UIMenuController *menuController = [UIMenuController sharedMenuController];
            [menuController setMenuItems:@[resetMenuItem]];
            CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
            CGRect menuLocation = CGRectMake(location.x, location.y, 0, 0);
            [menuController setTargetRect:menuLocation inView:[gestureRecognizer view]];
            [menuController setMenuVisible:YES animated:YES];
        }
        return;
    } else if (showLightTable && indexPathForLightTableArtToRemove){
        //trying to interact with a light table piece
        if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
            [self becomeFirstResponder];
            
            indexPathForLightTableArtToRemove = [_collectionView indexPathForItemAtPoint:loc];
            NSString *menuItemTitle = NSLocalizedString(@"Remove", @"Remove this art from your favorites.");
            UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:menuItemTitle action:@selector(removeLightTablePhoto:)];
            UIMenuController *menuController = [UIMenuController sharedMenuController];
            [menuController setMenuItems:@[resetMenuItem]];
            CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
            CGRect menuLocation = CGRectMake(location.x, location.y, 0, 0);
            [menuController setTargetRect:menuLocation inView:[gestureRecognizer view]];
            [menuController setMenuVisible:YES animated:YES];
        }
        return;
    }
    
    CGFloat heightInScreen = fmodf((loc.y-self.collectionView.contentOffset.y), CGRectGetHeight(self.collectionView.frame));
    CGFloat hoverOffset;
    tableIsVisible ? (hoverOffset = kSidebarWidth) : (hoverOffset = 0);
    CGPoint locInScreen = CGPointMake( loc.x - self.collectionView.contentOffset.x + hoverOffset, heightInScreen );
    
    //[self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.startIndex = [self.collectionView indexPathForItemAtPoint:loc];
        
        if (self.startIndex) {
            WFPhotoCell *cell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
            self.dragViewStartLocation = [self.view convertPoint:cell.center fromView:nil];
            
            Photo *photo;
            if (showPrivate){
                photo = _privatePhotos[self.startIndex.item];
            } else if (showLightTable){
                photo = _table.photos[self.startIndex.item];
            } else if (showFavorites){
                photo = _favoritePhotos[self.startIndex.item];
            } else if (searching){
                if (_filteredPhotos.count){
                    photo = _filteredPhotos[self.startIndex.item];
                }
            } else {
                photo = _photos[self.startIndex.item];
            }
            
            if (photo){
                self.draggingView = [[WFInteractiveImageView alloc] initWithImage:[cell getRasterizedImageCopy] andPhoto:photo];
                [cell.contentView setAlpha:0.23f];
            
                [self.view addSubview:self.draggingView];
                UIView *piece = gestureRecognizer.view;
                CGPoint locationInView = [gestureRecognizer locationInView:piece];
                CGPoint locationInSuperview = [gestureRecognizer locationInView:piece.superview];
                
                self.draggingView.center = CGPointMake(locationInView.x / piece.bounds.size.width, locationInView.y / piece.bounds.size.height);
                self.draggingView.center = locationInSuperview;
            }
        }
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.draggingView.center = locInScreen;
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // comparison mode
        // 128 is half the width of an art slide, since the point we're grabbing is a center point, not the origin
        if (loc.x < 0 && loc.y > (_comparisonContainerView.frame.origin.y - 128)){
            NSLog(@"loc x: %f",loc.x);
            if (!comparison1) {
                comparison1 = [[WFInteractiveImageView alloc] initWithFrame:CGRectMake(10, 10, 125, 130) andPhoto:self.draggingView.photo];
                comparison1.imageViewDelegate = self;
                comparison1.contentMode = UIViewContentModeScaleAspectFit;
                [comparison1 sd_setImageWithURL:[NSURL URLWithString:self.draggingView.photo.slideImageUrl]];
                
                comparison1LongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(comparisonTap:)];
                comparison1LongPress.minimumPressDuration = .14f;
                [comparison1 addGestureRecognizer:comparison1LongPress];
                [comparison1 setUserInteractionEnabled:YES];
                [_comparisonContainerView addSubview:comparison1];
                [comparisonTap requireGestureRecognizerToFail:comparison1LongPress];
            } else {
        
                if (!comparison2){
                    comparison2 = [[WFInteractiveImageView alloc] initWithFrame:CGRectMake(comparison1.frame.size.width+comparison1.frame.origin.x+10, 10, 125, 130) andPhoto:self.draggingView.photo];
                    comparison2.contentMode = UIViewContentModeScaleAspectFit;
                    comparison2.imageViewDelegate = self;
                    comparison2LongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(comparisonTap:)];
                    comparison2LongPress.minimumPressDuration = .14f;
                    [comparison2 addGestureRecognizer:comparison2LongPress];
                    [comparison2 setUserInteractionEnabled:YES];
                    
                    [_comparisonContainerView addSubview:comparison2];
                    [comparisonTap requireGestureRecognizerToFail:comparison2LongPress];
                }
            }
            if (loc.x < -(kSidebarWidth/2)){
                [comparison1 sd_setImageWithURL:[NSURL URLWithString:self.draggingView.photo.slideImageUrl]];
                [comparison1 setPhoto:self.draggingView.photo];
            } else {
                [comparison2 sd_setImageWithURL:[NSURL URLWithString:self.draggingView.photo.slideImageUrl]];
                [comparison2 setPhoto:self.draggingView.photo];
            }
            [self resetComparisonLabel];
            [self resetDraggingView];
        } else if (self.draggingView) {
            self.moveToIndexPath = [self.collectionView indexPathForItemAtPoint:loc];
            if (self.moveToIndexPath) {
        
                WFPhotoCell *movedCell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.moveToIndexPath];
                WFPhotoCell *oldIndexCell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
                
                NSNumber *thisNumber = [_photos objectAtIndex:self.startIndex.row];
                [_photos removeObjectAtIndex:self.startIndex.row];
                if (self.moveToIndexPath.row < self.startIndex.row) {
                    [_photos insertObject:thisNumber atIndex:self.moveToIndexPath.row];
                } else {
                    [_photos insertObject:thisNumber atIndex:self.moveToIndexPath.row];
                }
                
                CGPoint moveToPoint = [self.view convertPoint:movedCell.center fromView:nil];
                [UIView animateWithDuration:.27f animations:^{

                    self.draggingView.layer.anchorPoint = moveToPoint;
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

#pragma mark - Comparison Seciton

- (void)shouldCompare {
    if (comparison1 && comparison1.photo && comparison2 && comparison2.photo){
        [self resetTransitionBooleans];
        comparison = YES;
        
        WFComparisonViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Comparison"];
        vc.photos = [NSMutableOrderedSet orderedSetWithArray:@[comparison1.photo, comparison2.photo]];
        
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

- (void)comparisonTap:(UILongPressGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
        [self becomeFirstResponder];
        
        NSString *menuItemTitle = NSLocalizedString(@"Remove", @"Remove art from comparison section");
        UIMenuItem *resetMenuItem;
        if (gestureRecognizer.view == comparison1){
            resetMenuItem = [[UIMenuItem alloc] initWithTitle:menuItemTitle action:@selector(removeComparison1:)];
        } else if (gestureRecognizer.view == comparison2){
            resetMenuItem = [[UIMenuItem alloc] initWithTitle:menuItemTitle action:@selector(removeComparison2:)];
        }
        
        if (resetMenuItem){
            UIMenuController *menuController = [UIMenuController sharedMenuController];
            [menuController setMenuItems:@[resetMenuItem]];
            CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
            CGRect menuLocation = CGRectMake(location.x, location.y, 0, 0);
            [menuController setTargetRect:menuLocation inView:[gestureRecognizer view]];
            [menuController setMenuVisible:YES animated:YES];
        }
    }
}

- (void)removeComparison1:(UIMenuController*)menuController {
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        comparison1.transform = CGAffineTransformMakeScale(.9, .9);
        comparison1.alpha = 0.f;
    } completion:^(BOOL finished) {
        [comparison1 removeFromSuperview];
        comparison1 = nil;
        [self resetComparisonLabel];
    }];
}

- (void)removeComparison2:(UIMenuController*)menuController {
    [UIView animateWithDuration:kDefaultAnimationDuration delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        comparison2.transform = CGAffineTransformMakeScale(.9, .9);
        comparison2.alpha = 0.f;
    } completion:^(BOOL finished) {
        [comparison2 removeFromSuperview];
        comparison2 = nil;
        [self resetComparisonLabel];
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)resetDraggingView {
    WFPhotoCell *cell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
    [UIView animateWithDuration:.27f animations:^{
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
    Photo *photo;
    if (showPrivate){
        photo = _privatePhotos[indexPath.item];
    } else if (showLightTable){
        photo = _table.photos[indexPath.item];
    } else if (showFavorites){
        photo = _favoritePhotos[indexPath.item];
    } else if (searching){
        if (_filteredPhotos.count){
            photo = _filteredPhotos[indexPath.item];
        }
    } else {
        photo = _photos[indexPath.item];
    }
    
    if (photo){
        [self showMetadata:photo];
    }
}

- (void)showMetadata:(Photo*)photo{
    WFArtMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ArtMetadata"];
    vc.metadataDelegate = self;
    [vc setPhoto:photo];
    vc.transitioningDelegate = self;
    vc.modalPresentationStyle = UIModalPresentationCustom;
    [self resetTransitionBooleans];
    metadata = YES;
    
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

#pragma mark - Metadata Delegate
- (void)photoFlagged:(Photo *)photo {
    
}

- (void)artFlagged:(Art*)art {
    for (Photo *photo in art.photos){
        [self removePhoto:photo];
    }
    [art MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    [_collectionView reloadData];
}

- (void)removePhoto:(Photo*)photo {
    if ([_selectedPhotos containsObject:photo]){
        [_selectedPhotos removeObject:photo];
    }
    if ([_photos containsObject:photo]){
        [_photos removeObject:photo];
    }
    [_currentUser.favorites enumerateObjectsUsingBlock:^(Favorite *favorite, NSUInteger idx, BOOL *stop) {
        if (favorite.photo == photo){
            [_favoritePhotos removeObject:photo];
            [favorite MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            *stop = YES;
        }
    }];
    [_tables enumerateObjectsUsingBlock:^(Table *lightTable, NSUInteger idx, BOOL *stop) {
        if ([lightTable.photos containsObject:photo]){
            [lightTable removePhoto:photo];
        }
    }];
}

- (void)favoritedPhoto:(Photo *)photo {
    [_favoritePhotos addObject:photo];
}

- (void)droppedPhoto:(Photo*)photo toLightTable:(Table*)lightTable {
    if (!slideshowSidebarMode && tableIsVisible){
        [self.tableView reloadData];
    }
}

- (void)removedPhoto:(Photo *)photo fromLightTable:(Table *)lightTable {
    //ensure the photo has ACTUALLY been removed from the light table
    [lightTable removePhoto:photo];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    if (!slideshowSidebarMode && tableIsVisible){
        [self.tableView reloadData];
    }
    
    if (showLightTable && [lightTable.identifier isEqualToNumber:_table.identifier]){
        [_collectionView reloadData];
    }
}

- (void)dismissMetadata {
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)photoDeleted:(NSNumber *)photoId {
    NSLog(@"photo deleted");
    if (!showLightTable && !showFavorites && !showPrivate){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"art.privateArt = %@",@NO];
        _photos = [Photo MR_findAllSortedBy:@"createdDate" ascending:NO withPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]].mutableCopy;
        [_collectionView reloadData];
    }
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

- (void)showSelected {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    searchResultsVc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SearchResults"];
    [searchResultsVc setPhotos:_selectedPhotos.array.mutableCopy];
    CGFloat selectedHeight = _selectedPhotos.count*80.f > 640.f ? 640.f : (_selectedPhotos.count*80.f); // don't need to offset by 44 because iOS is already adding a scrolView offset for us
    searchResultsVc.preferredContentSize = CGSizeMake(420, selectedHeight);
    searchResultsVc.searchDelegate = self;
    [searchResultsVc setOriginalPopoverHeight:selectedHeight];
    UINavigationController *selectedNav = [[UINavigationController alloc] initWithRootViewController:searchResultsVc];
    selectedNav.preferredContentSize = CGSizeMake(420, selectedHeight);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:selectedNav];
    self.popover.delegate = self;
    [self.popover presentPopoverFromBarButtonItem:selectedBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)showNotifications:(id)sender {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    WFNotificationsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Notifications"];
    //vc.notificationsDelegate = self;
    vc.preferredContentSize = CGSizeMake(470, 500);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)settingsPopover:(id)sender {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    WFMenuViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Menu"];
    vc.menuDelegate = self;
    vc.preferredContentSize = CGSizeMake(200, 150);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)resetTransitionBooleans {
    settings = NO;
    newArt = NO;
    newLightTableTransition = NO;
    metadata = NO;
    comparison = NO;
    _login = NO;
    notificationsBool = NO;
    groupBool = NO;
    newUser = NO;
    profile = NO;
    showSlideshow = NO;
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

- (void)showProfile {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        [self resetTransitionBooleans];
        profile = YES;
        WFProfileViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
        [vc setUser:_currentUser];
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
    [WFAlert show:kLogoutMessage withTime:2.7f];
    _currentUser = nil;
    [self setUpNavBar];
    [self loadPhotos];
}

- (void)newSlideshow {
    [self.popover dismissPopoverAnimated:YES];
    WFSlideshowSplitViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideshowSplitView"];
    Slideshow *slideshow = [Slideshow MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
    slideshow.user = _currentUser;
    if (_selectedPhotos.count){
        [slideshow setPhotos:[NSOrderedSet orderedSetWithOrderedSet:_selectedPhotos]];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        NSLog(@"new slideshow has %lu slides",(unsigned long)slideshow.slides.count);
        [vc setSlideshow:slideshow];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self resetTransitionBooleans];
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    }];
}

- (void)slideshowSelected:(Slideshow *)presentation {
    [self.popover dismissPopoverAnimated:YES];
    WFSlideshowSplitViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideshowSplitView"];
    [vc setSlideshow:presentation];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self resetTransitionBooleans];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

- (void)showSlideshows {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        tablesButton.selected = NO;
        if (slideshowSidebarMode){
            [self.tableView reloadData];
            [self showSidebar];
        } else {
            slideshowSidebarMode = YES;
            if (tableIsVisible){
                [self.tableView reloadData];
                slideshowsButton.selected = YES;
            } else {
                [self.tableView reloadData];
                [self showSidebar];
            }
        }
    } else {
        [self showLogin];
    }
}

- (void)showLightTables {
    slideshowsButton.selected = NO;
    if (slideshowSidebarMode){
        if (tableIsVisible){
            slideshowSidebarMode = NO;
            [self.tableView reloadData];
            tablesButton.selected = YES;
        } else {
            slideshowSidebarMode = NO;
            [self.tableView reloadData];
            [self showSidebar];
        }
    } else {
        slideshowSidebarMode = NO; //light table mode
        [self.tableView reloadData];
        [self showSidebar];
    }
}

- (void)showSidebar {
    if (tableIsVisible){
        tableIsVisible = NO;
        //hide the light table sidebar
        CGRect collectionFrame = _collectionView.frame;
        collectionFrame.origin.x = 0;
        collectionFrame.size.width += kSidebarWidth;
        slideshowsButton.selected = NO;
        tablesButton.selected = NO;
        [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _tableView.transform = CGAffineTransformIdentity;
            _comparisonContainerView.transform = CGAffineTransformIdentity;
            resetButton.transform = CGAffineTransformIdentity;
            [_collectionView setFrame:collectionFrame];
            
            if (_filteredPhotos.count && searching){
                [_collectionView performBatchUpdates:^{
                    [_collectionView reloadData];
                } completion:^(BOOL finished) {
                
                }];
            } else {
                [_collectionView reloadData];
            }
            
        } completion:^(BOOL finished) {
        
        }];
    } else {
        tableIsVisible = YES;
        if (slideshowSidebarMode) {
            slideshowsButton.selected = YES;
        } else {
            tablesButton.selected = YES;
        }
        //show the light table sidebar
        CGRect collectionFrame = _collectionView.frame;
        collectionFrame.origin.x = kSidebarWidth;
        collectionFrame.size.width -= kSidebarWidth;
        
        [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _tableView.transform = CGAffineTransformMakeTranslation(kSidebarWidth, 0);
            _comparisonContainerView.transform = CGAffineTransformMakeTranslation(kSidebarWidth, 0);
            resetButton.transform = CGAffineTransformMakeTranslation(-kSidebarWidth, 0);
            
            if (_filteredPhotos.count){
                [_collectionView performBatchUpdates:^{
                    [_collectionView reloadData];
                } completion:^(BOOL finished) {
                    [_collectionView setFrame:collectionFrame];
                }];
            } else {
                [_collectionView setFrame:collectionFrame];
                [_collectionView reloadData];
            }
        } completion:^(BOOL finished) {
            
        }];
    }
}

#pragma mark Dismiss & Transition Methods
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
    } else if (newLightTableTransition) {
        WFNewLightTableAnimator *animator = [WFNewLightTableAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (_login) {
        WFLoginAnimator *animator = [WFLoginAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (comparison || showSlideshow) {
        WFSlideshowFocusAnimator *animator = [WFSlideshowFocusAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (newUser) {
        WFWalkthroughAnimator *animator = [WFWalkthroughAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (profile) {
        WFProfileAnimator *animator = [WFProfileAnimator new];
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
    } else if (newLightTableTransition) {
        WFNewLightTableAnimator *animator = [WFNewLightTableAnimator new];
        return animator;
    } else if (_login) {
        WFLoginAnimator *animator = [WFLoginAnimator new];
        return animator;
    } else if (comparison || showSlideshow) {
        WFSlideshowFocusAnimator *animator = [WFSlideshowFocusAnimator new];
        return animator;
    } else if (newUser) {
        WFWalkthroughAnimator *animator = [WFWalkthroughAnimator new];
        return animator;
    } else if (profile) {
        WFProfileAnimator *animator = [WFProfileAnimator new];
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

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar endEditing:YES];
    searchText = searchBar.text;
    [self loadPhotos];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar endEditing:YES];
    searchText = @"";
    searching = NO;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (!searchBar.text.length) {
        searching = NO;
        [self resetArtBooleans];
        [self setHomeAsHome];
    }
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:^{
       
    }];
}

#pragma mark - Search Methods
- (void)setUpSearch {
    [_noSearchResultsLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLightItalic] size:0]];
    [_noSearchResultsLabel setTextColor:[UIColor colorWithWhite:0 alpha:.23]];
    [_noSearchResultsLabel setText:@"No search results..."];
    [_noSearchResultsLabel setHidden:YES];
    
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
    self.searchBar.delegate = self;
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (!_filteredPhotos) _filteredPhotos = [NSMutableArray arrayWithArray:_photos];
    searching = YES;
    if (self.popover) [self.popover dismissPopoverAnimated:YES];
    [self setHomeAsReset];
}

- (void)setHomeAsReset {
    [homeButton setImage:[UIImage imageNamed:@"remove"] forState:UIControlStateNormal];
}

- (void)setHomeAsHome {
    [homeButton setImage:[UIImage imageNamed:@"homeIcon"] forState:UIControlStateNormal];
}

- (void)searchDidSelectPhoto:(Photo *)photo {
    NSLog(@"Search did select art: %@",photo.art.title);
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
    searchText = text;
    searching = YES;
    [self filterContentForSearchText:searchText scope:nil];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    //NSLog(@"search text: %@",text);
    if (text.length) {
        [_filteredPhotos removeAllObjects];
        for (Photo *photo in _photos){
            // evaluate the art metadata, but actually add the photo to _filteredPhotos
            Art *art = photo.art;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if([predicate evaluateWithObject:art.title]) {
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:art.artistsToSentence]){
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:art.locationsToSentence]){
                [_filteredPhotos addObject:photo];
            }
        }
    } else {
        _filteredPhotos = [NSMutableArray arrayWithArray:_photos];
    }
    
    [self.collectionView reloadData];
}

#pragma mark - WFSearchDelegate methods
- (void)lightTableForSelected:(Table *)lightTable {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    for (Photo *photo in _selectedPhotos){
        [lightTable addPhoto:photo];
    }
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {

        __block NSMutableSet *photoIds = [NSMutableSet set];
        [lightTable.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
            [photoIds addObject:photo.identifier];
        }];
        if (tableIsVisible && !slideshowSidebarMode){
            [self.tableView reloadData];
        }
        if (photoIds.count){
            [manager PATCH:[NSString stringWithFormat:@"light_tables/%@",lightTable.identifier] parameters:@{@"light_table":@{@"photo_ids":photoIds}, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success bulk adding photos to a light table: %@",responseObject);
                NSString *photoCount = _selectedPhotos.count == 1 ? @"1 photo" : [NSString stringWithFormat:@"%lu photos",(unsigned long)_selectedPhotos.count];
                [WFAlert show:[NSString stringWithFormat:@"%@ added to %@",photoCount, lightTable.name] withTime:3.3f];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to add selected to a light table: %@",error.description);
            }];
        }
    }];
}

- (void)newLightTableForSelected {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    [self newLightTable];
//    Table *newLightTable = [Table MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
//    for (Photo *photo in _selectedPhotos){
//        [newLightTable addPhoto:photo];
//    }
//    
//    if (tableIsVisible && !slideshowSidebarMode){
//        [self.tableView reloadData];
//    }
//    
//    __block NSMutableSet *photoIds = [NSMutableSet set];
//    [newLightTable.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
//        [photoIds addObject:photo.identifier];
//    }];
//    if (photoIds.count){
//        [ProgressHUD show:@"Creating your light table..."];
//        [manager POST:@"light_tables" parameters:@{@"light_table":@{@"photo_ids":photoIds, @"owner_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]}, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            NSLog(@"Success bulk adding photos to a NEW light table: %@",responseObject);
//            [newLightTable populateFromDictionary:[responseObject objectForKey:@"light_table"]];
//            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
//                [WFAlert show:@"New light table created." withTime:2.7f];
//                [ProgressHUD dismiss];
//            }];
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            [ProgressHUD dismiss];
//            [WFAlert show:@"Sorry, but something went wrong while trying to create your light table. Please try again soon." withTime:2.7f];
//            NSLog(@"Failed to create a new light table from selected: %@",error.description);
//        }];
//    }
}

- (void)slideshowForSelected:(Slideshow *)slideshow {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    for (Photo *photo in _selectedPhotos){
        [slideshow addPhoto:photo];
    }
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (tableIsVisible && slideshowSidebarMode){
            [self.tableView reloadData];
        }
        __block NSMutableArray *photoIds = [NSMutableArray array];
        [slideshow.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
            [photoIds addObject:photo.identifier];
        }];
        if (photoIds.count){
            if ([slideshow.identifier isEqualToNumber:@0]){
                [self newSlideshow];
            } else {
                NSLog(@"should be synching an existing slideshow");
                [manager PATCH:[NSString stringWithFormat:@"slideshows/%@",slideshow.identifier] parameters:@{@"slideshow":@{@"photo_ids":photoIds}, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSLog(@"Success dropping photos into slideshow: %@",responseObject);
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    
                }];
            }
        }
    }];
}

- (void)batchFavorite {
    NSLog(@"Batch favoriting for current user: %@",_currentUser.fullName);
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && _currentUser){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        NSMutableArray *photoIds = [NSMutableArray arrayWithCapacity:_selectedPhotos.count];
        for (Photo *photo in _selectedPhotos){
            [photoIds addObject:photo.identifier];
            Favorite *favorite = [Favorite MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            favorite.photo = photo;
            [_favoritePhotos addObject:photo];
            [_currentUser addFavorite:favorite];
        }
    
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"Done locally saving batch favorites: %u",success);
        }];
        
        if (photoIds.count){
            [parameters setObject:photoIds forKey:@"photo_ids"];
            [manager POST:@"favorites/batch" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success batch favoriting: %@",responseObject);
                [_currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to batch favorite: %@",error.description);
            }];
        }
    } else {
        [self showLogin];
    }
}

- (void)endSearch {
    
}

- (void)removeAllSelected {
    searching = NO;
    [_selectedPhotos removeAllObjects];
    [_collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    [self configureSelectedButton];
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
}

#pragma mark - UIMenuController Methods
- (void)willHideEditMenu:(id)sender {
    
}

- (void)didHideEditMenu:(id)sender {
    [self resignFirstResponder];
    indexPathForFavoriteToRemove = nil;
    indexPathForLightTableArtToRemove = nil;
}

// UIMenuController requires that we can become first responder or it won't display
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (tableViewRefresh.isRefreshing){
        [tableViewRefresh endRefreshing];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
