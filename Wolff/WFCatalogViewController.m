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
#import "WFLightTableCell.h"
#import "WFLightTableDefaultCell.h"
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

@interface WFCatalogViewController () <UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIViewControllerTransitioningDelegate,UIPopoverControllerDelegate, UIAlertViewDelegate, WFLoginDelegate, WFMenuDelegate,  WFSlideshowDelegate, WFImageViewDelegate, WFSearchDelegate, WFMetadataDelegate, WFNewArtDelegate, WFLightTableDelegate, WFSlideshowsDelegate, WFNotificationsDelegate, WFSettingsDelegate, UIGestureRecognizerDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UIButton *homeButton;
    UIBarButtonItem *homeBarButton;
    UIButton *slideshowsButton;
    UIBarButtonItem *slideshowsBarButton;
    UIButton *tablesButton;
    UIBarButtonItem *lightTablesButton;
    UIBarButtonItem *notificationsButton;
    //UIBarButtonItem *refreshButton;
    CGFloat width, height, keyboardHeight;
    NSMutableOrderedSet *_photos;
    NSMutableOrderedSet *_privatePhotos;
    NSMutableOrderedSet *_favoritePhotos;
    NSMutableOrderedSet *_filteredPhotos;
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
    
    NSString *searchText;
    UIButton *resetButton;
    UIImageView *navBarShadowView;
}

@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) Table *table;
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
    
    _photos = [NSMutableOrderedSet orderedSet];
    _privatePhotos = [NSMutableOrderedSet orderedSet];
    _favoritePhotos = [NSMutableOrderedSet orderedSet];
    
    if (!_selectedPhotos) _selectedPhotos = [NSMutableOrderedSet orderedSet];
    
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
    
    self.collectionView.delaysContentTouches = NO;
    [self.collectionView setBackgroundColor:[UIColor whiteColor]];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
    self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    if (self.currentUser){
        [self loadUserDashboard];
        if (!tableViewRefresh){
            tableViewRefresh = [[UIRefreshControl alloc] init];
            [tableViewRefresh addTarget:self action:@selector(refreshTableView:) forControlEvents:UIControlEventValueChanged];
            [self.tableView addSubview:tableViewRefresh];
        }
    }
    
    //set up the nav buttons
    [self setUpNavBar];
    
    loading = NO;
    [self loadPhotos];
    
    if (tableIsVisible && _photos.count){
        [self.tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showWalkthrough];
}

- (void)showWalkthrough {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kExistingUser]){
        double delayInSeconds = .77f;
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

- (void)setUpGestureRecognizers {
    catalogLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    catalogLongPress.minimumPressDuration = .23f;
    [self.collectionView addGestureRecognizer:catalogLongPress];
    
    catalogDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    catalogDoubleTap.numberOfTapsRequired = 2;
    [self.collectionView addGestureRecognizer:catalogDoubleTap];
    
    comparisonTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shouldCompare)];
    comparisonTap.numberOfTapsRequired = 1;
    [_comparisonContainerView addGestureRecognizer:comparisonTap];
}

- (void)refreshTableView:(UIRefreshControl*)refreshControl {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [ProgressHUD show:@"Refreshing..."];
        if (slideshowSidebarMode){
            [self loadSlideshows];
        } else {
            [self loadUserDashboard];
        }
    } else {
        [refreshControl endRefreshing];
        [self showLogin];
    }
}

- (void)loadSlideshows {
    [manager GET:[NSString stringWithFormat:@"users/%@/slideshows",self.currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading slideshows: %@",responseObject);
        if ([responseObject objectForKey:@"slideshows"]){
            NSMutableOrderedSet *tempSet = [NSMutableOrderedSet orderedSetWithCapacity:[[responseObject objectForKey:@"slideshows"] count]];
            for (id dict in [responseObject objectForKey:@"slideshows"]){
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
                Slideshow *slideshow = [Slideshow MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!slideshow){
                    slideshow = [Slideshow MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [slideshow populateFromDictionary:dict];
                [tempSet addObject:slideshow];
            }
            for (Slideshow *slideshow in _slideshows){
                if (![tempSet containsObject:slideshow]){
                    [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
                }
            }
        }
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [self.tableView reloadData];
            [self endRefresh];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load slideshows: %@",error.description);
        [self endRefresh];
    }];
}

- (void)refreshCollectionView:(id)sender {
    [ProgressHUD show:@"Refreshing Art..."];
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
    
    //refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshCollectionView:)];
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
        
        self.navigationItem.rightBarButtonItems = @[addButton, selectedBarButtonItem, notificationsButton, settingsButton];
        
        //also ensure there's a pull to refresh
        if (!tableViewRefresh){
            tableViewRefresh = [[UIRefreshControl alloc] init];
            [tableViewRefresh addTarget:self action:@selector(refreshTableView:) forControlEvents:UIControlEventValueChanged];
            [self.tableView addSubview:tableViewRefresh];
        }
        
    } else {
        loginButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login"] style:UIBarButtonItemStylePlain target:self action:@selector(showLogin)];
        self.navigationItem.rightBarButtonItems = @[loginButton, addButton];
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
    self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    [self setUpNavBar];
    [self loadUserDashboard];
    if (tableIsVisible){
        [self.tableView reloadData];
    }
    //only ask for push notifications when a user has successfully logged in
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound)];
    }
}

- (void)loggedOut {
    // reset the views now that we're logged out
    [self setUpNavBar];
    [self.tableView reloadData];
    self.currentUser = nil;
}

- (void)loadPhotos {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@40 forKey:@"count"];
    if (searching && searchText && searchText.length){
        [parameters setObject:searchText forKey:@"search"];
    } else if (_photos.count) {
        Photo *lastPhoto = _photos.lastObject;
        [parameters setObject:[NSNumber numberWithDouble:[lastPhoto.createdDate timeIntervalSince1970]] forKey:@"before_date"];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [ProgressHUD show:@"Loading art..."];
        });
    }
    
    if (!loading){
        loading = YES;
        [manager GET:@"photos" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if ([[responseObject objectForKey:@"photos"] count]){
                canLoadMorePhotos = YES;
                [_noSearchResultsLabel setText:@"Searching the full Wölff catalog..."];
                for (NSDictionary *dict in [responseObject objectForKey:@"photos"]) {
                    Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                    if (!photo){
                        photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                    }
                    [photo populateFromDictionary:dict];
                    
                    if (![photo.privatePhoto isEqualToNumber:@YES] && ![photo.art.privateArt isEqualToNumber:@YES]){
                        [_photos addObject:photo];
                        if (searching){
                            [_filteredPhotos addObject:photo];
                        }
                    }
                }
                [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                    [self endRefresh];
                    [self.collectionView reloadData];
                }];
            } else {
                canLoadMorePhotos = NO;
                [self endRefresh];
                [_noSearchResultsLabel setText:kNoSearchResults];
                [_noSearchResultsLabel setHidden:NO];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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

- (void)loadUserDashboard {
    if (self.currentUser && !loading){
        loading = YES;
        [manager GET:[NSString stringWithFormat:@"users/%@/dashboard",self.currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting user dashboard: %@", responseObject);
            [self.currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                //set up private photos and favorites
                NSPredicate *privatePredicate = [NSPredicate predicateWithFormat:@"privatePhoto == %@ && user.identifier == %@", @YES, [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
                _privatePhotos = [NSMutableOrderedSet orderedSetWithArray:[Photo MR_findAllWithPredicate:privatePredicate inContext:[NSManagedObjectContext MR_defaultContext]]];
                [self.currentUser.favorites enumerateObjectsUsingBlock:^(Favorite *favorite, NSUInteger idx, BOOL *stop) {
                    if (favorite.photo && ![_favoritePhotos containsObject:favorite.photo]) {
                        [_favoritePhotos addObject:favorite.photo];
                    }
                }];

                [self.tableView reloadData];
                [self endRefresh];
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get user art: %@",error.description);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to load your art. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            
            [self endRefresh];
        }];
    }
}

- (void)add {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        if (self.currentUser.customerPlan.length){
            if (self.popover){
                [self.popover dismissPopoverAnimated:YES];
            }
            settings = NO; metadata = NO; _login = NO; groupBool = NO;
            newArt = YES;
            WFNewArtViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"NewArt"];
            vc.artDelegate = self;
            vc.transitioningDelegate = self;
            vc.modalPresentationStyle = UIModalPresentationCustom;
            [self presentViewController:vc animated:YES completion:^{
                
            }];
        } else {
            [WFAlert show:@"Uploading art to the Wölff catalog requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
        }
    } else {
        [self showLogin];
    }
}

- (void)newArtAdded:(Art *)art {
    if ([art.privateArt isEqualToNumber:@NO]){
        //don't animate the changes if the user is looking at a light table, their private art, their favorites, or searching.
        if (!showFavorites && !showLightTable && !searching && !showPrivate){
            [self.collectionView performBatchUpdates:^{
                NSMutableArray *indexPathArray = [NSMutableArray array];
                for (Photo *photo in art.photos){
                    [_photos insertObject:photo atIndex:0];
                    [indexPathArray addObject:[NSIndexPath indexPathForItem:0 inSection:0]];
                }
                [self.collectionView insertItemsAtIndexPaths:indexPathArray];
            } completion:^(BOOL finished) {
                
            }];
        }
    }
}

- (void)failedToAddArt:(Art*)art {
    //[WFAlert show:[NSString stringWithFormat:@"Something went wrong while trying to add \"%@\" to the catalog. Please try again soon.",art.title] withTime:3.7f];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (slideshowSidebarMode){
        _slideshows = [NSMutableArray arrayWithArray:[Slideshow MR_findAllInContext:[NSManagedObjectContext MR_defaultContext]]];
        NSSortDescriptor *alphabeticalSlideshowSort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
        [_slideshows sortUsingDescriptors:[NSArray arrayWithObject:alphabeticalSlideshowSort]];
        return 2;
    } else {
        _tables = _tables ? self.currentUser.lightTables.array.mutableCopy : [NSMutableArray arrayWithArray:self.currentUser.lightTables.array];
        NSSortDescriptor *alphabeticalTableSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [_tables sortUsingDescriptors:[NSArray arrayWithObject:alphabeticalTableSort]];
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (slideshowSidebarMode){
        if (section == 0){
            return 1;
        } else {
            return _slideshows.count;
        }
    } else {
        switch (section) {
            case 0:
                return 2;
                break;
            case 1:
                return 1;
                break;
            case 2:
                if (_tables.count){
                    return _tables.count;
                } else if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]) {
                    return 1;
                } else {
                    return 0;
                }
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
        [cell setBackgroundColor:[UIColor clearColor]];
        if (indexPath.section == 0){
            [cell.imageView setImage:[UIImage imageNamed:@"whitePlus"]];
            [cell.textLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
            [cell.textLabel setText:@"New Slideshow"];
            [cell.scrollView setScrollEnabled:NO];
            
        } else {
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
                [cell.actionButton setTag:indexPath.row];
                [cell.actionButton addTarget:self action:@selector(slideshowAction:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
        
        // ensure the labels are the right color. this cell is also being used on the Slideshows view, and the label text there is black
        [cell.textLabel setTextColor:[UIColor whiteColor]];
        [cell.slideshowLabel setTextColor:[UIColor whiteColor]];
        return cell;
    } else {
        if (indexPath.section == 0){
            WFLightTableDefaultCell *cell = (WFLightTableDefaultCell *)[tableView dequeueReusableCellWithIdentifier:@"LightTableDefaultCell"];
            [cell setBackgroundColor:[UIColor clearColor]];
            if (indexPath.row == 0){
                [cell.label setText:@"Private"];
                if (showPrivate){
                    [cell.iconImageView setImage:[UIImage imageNamed:@"blueLock"]];
                    [cell.label setTextColor:kElectricBlue];
                    cell.label.highlightedTextColor = kElectricBlue;
                    [cell setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
                } else {
                    [cell.iconImageView setImage:[UIImage imageNamed:@"whiteLock"]];
                    [cell.label setTextColor:[UIColor whiteColor]];
                    [cell setBackgroundColor:[UIColor clearColor]];
                }
            } else {
                [cell.label setText:@"Favorites"];
                if (showFavorites){
                    [cell.iconImageView setImage:[UIImage imageNamed:@"blueFavorite"]];
                    [cell.label setTextColor:kElectricBlue];
                    [cell setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
                } else {
                    [cell.iconImageView setImage:[UIImage imageNamed:@"whiteFavorite"]];
                    [cell.label setTextColor:[UIColor whiteColor]];
                    [cell setBackgroundColor:[UIColor clearColor]];
                }
            }
            return cell;
        } else if (indexPath.section == 1){
            WFLightTableDefaultCell *cell = (WFLightTableDefaultCell *)[tableView dequeueReusableCellWithIdentifier:@"LightTableDefaultCell"];
            [cell setBackgroundColor:[UIColor clearColor]];
            [cell.iconImageView setImage:[UIImage imageNamed:@"whitePlus"]];
            [cell.label setText:@"Light Table"];
            [cell.label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
            return cell;
        } else {
            WFLightTableCell *cell = (WFLightTableCell *)[tableView dequeueReusableCellWithIdentifier:@"LightTableCell"];
            [cell setBackgroundColor:[UIColor clearColor]];
            if (_tables.count){
                Table *table = _tables[indexPath.row];
                [cell configureForTable:table];
                [cell.label setText:@""];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                if (table == _table){
                    [cell.tableLabel setTextColor:kElectricBlue];
                    [cell.pieceCountLabel setTextColor:kElectricBlue];
                    [cell setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
                } else {
                    [cell.tableLabel setTextColor:[UIColor whiteColor]];
                    [cell.pieceCountLabel setTextColor:[UIColor colorWithWhite:1 alpha:.33]];
                    [cell setBackgroundColor:[UIColor clearColor]];
                }
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
            cell.editButton.tag = indexPath.row;
            cell.deleteButton.tag = indexPath.row;
            cell.leaveButton.tag = indexPath.row;
            [cell.editButton addTarget:self action:@selector(editLightTable:) forControlEvents:UIControlEventTouchUpInside];
            [cell.deleteButton addTarget:self action:@selector(lightTableAction:) forControlEvents:UIControlEventTouchUpInside];
            [cell.leaveButton addTarget:self action:@selector(lightTableAction:) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }
    }
}

- (void)slideshowAction:(UIButton*)button{
    Slideshow *slideshow = _slideshows[button.tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag inSection:1];
    if ([slideshow.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [self deleteSlideshow:slideshow atIndexPath:indexPath];
    } else {
        [self removeSlideshow:slideshow atIndexPath:indexPath];
    }
}

- (void)deleteSlideshow:(Slideshow *)slideshow atIndexPath:(NSIndexPath*)indexPath {
    if (slideshow && ![slideshow.identifier isEqualToNumber:@0]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        [manager DELETE:[NSString stringWithFormat:@"slideshows/%@",slideshow.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success deleting this slideshow from catalog view: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete this slideshow: %@",error.description);
        }];
    }
    [self.tableView beginUpdates];
    [_slideshows removeObject:slideshow];
    [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [UIView animateWithDuration:kFastAnimationDuration animations:^{
            if (_slideshows.count){
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            } else {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
            }
            [self.tableView endUpdates];
        } completion:^(BOOL finished) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }];
}

- (void)removeSlideshow:(Slideshow *)slideshow atIndexPath:(NSIndexPath*)indexPath {
    [self.tableView beginUpdates];
    [_slideshows removeObject:slideshow];
    [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [UIView animateWithDuration:kFastAnimationDuration animations:^{
            if (_slideshows.count){
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            } else {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
            }
            [self.tableView endUpdates];
        } completion:^(BOOL finished) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }];
    
}

- (void)editLightTable:(UIButton *)button {
    Table *lightTable = _tables[button.tag];
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

- (void)lightTableAction:(UIButton*)button{
    Table *lightTable = _tables[button.tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag inSection:2];
    if (lightTable && [lightTable includesOwnerId:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [self deleteLightTable:lightTable atIndexPath:indexPath];
    } else {
        [self leaveLightTable:lightTable atIndexPath:indexPath];
    }
}

- (void)deleteLightTable:(Table *)lightTable atIndexPath:(NSIndexPath*)indexPath {
    WFLightTableCell *cell = (WFLightTableCell*)[_tableView cellForRowAtIndexPath:indexPath];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    if (![lightTable.identifier isEqualToNumber:@0]){
        [manager DELETE:[NSString stringWithFormat:@"light_tables/%@",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success deleting this light table: %@",responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete this light table: %@",error.description);
        }];
    }
    
    [self.tableView beginUpdates];
    [lightTable MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        _tables = _tables ? self.currentUser.lightTables.array.mutableCopy : [NSMutableArray arrayWithArray:self.currentUser.lightTables.array];
        
        [UIView animateWithDuration:kFastAnimationDuration animations:^{
            [cell.scrollView setContentOffset:CGPointZero];
            if (_tables.count){
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            } else {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
            }
            [self.tableView endUpdates];
        } completion:^(BOOL finished) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }];
}

- (void)leaveLightTable:(Table *)lightTable atIndexPath:(NSIndexPath*)indexPath {
    WFLightTableCell *cell = (WFLightTableCell*)[_tableView cellForRowAtIndexPath:indexPath];
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
    [lightTable MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        _tables = _tables ? self.currentUser.lightTables.array.mutableCopy : [NSMutableArray arrayWithArray:self.currentUser.lightTables.array];
        
        [UIView animateWithDuration:kFastAnimationDuration animations:^{
            [cell.scrollView setContentOffset:CGPointZero];
            if (_tables.count){
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            } else {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
            }
            [self.tableView endUpdates];
        } completion:^(BOOL finished) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    searching = NO;
    [_noSearchResultsLabel setHidden:YES];
    if (slideshowSidebarMode){
        if (indexPath.section == 0){
            [self newSlideshow:NO];
        } else {
            Slideshow *slideshow = _slideshows[indexPath.row];
            if (slideshow.user && [slideshow.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
                [self slideshowSelected:slideshow];
            } else {
                WFSlideshowViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Slideshow"];
                [vc setSlideshow:slideshow];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                vc.transitioningDelegate = self;
                vc.modalPresentationStyle = UIModalPresentationCustom;
                [self presentViewController:nav animated:YES completion:^{
                    
                }];
            }
        }
    } else {
        if (indexPath.section == 0){
            indexPath.row == 0 ? [self showPrivateArt] : [self showFavorites];
            [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else if (indexPath.section == 1){
            [self newLightTable];
        } else if (indexPath.section == 2){
            if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
                if (self.currentUser.customerPlan.length){
                    if (_tables.count){
                        Table *table = _tables[indexPath.row];
                        if (_table == table){
                            self.table = nil;
                            showLightTable = NO;
                            [self.collectionView reloadData];
                        } else {
                            [self showLightTable:table];
                        }
                        [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                } else {
                    [WFAlert show:@"Joining or creating light tables requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
                }
            } else {
                [self showLogin];
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)resetArtBooleans {
    showPrivate = NO;
    showFavorites = NO;
    showLightTable = NO;
    self.table = nil;
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

- (void)showLightTable:(Table*)table {
    if (showLightTable && table.identifier && _table.identifier && [table.identifier isEqualToNumber:_table.identifier]){
        [self resetArtBooleans];
    } else {
        [self resetArtBooleans];
        showLightTable = YES;
    }
    self.table = table;
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
        if (self.currentUser.customerPlan.length){
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
            [WFAlert show:@"Joining or creating light tables requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
        }
    } else {
        [self showLogin];
    }
}

- (void)didJoinLightTable:(Table *)table {
    if (!slideshowSidebarMode && tableIsVisible){
        [self.tableView reloadData];
    }
}

- (void)didCreateLightTable:(Table *)table {
    if (!slideshowSidebarMode && tableIsVisible){
        [self.tableView reloadData];
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
    if (searching && _filteredPhotos.count == 0){
        [_noSearchResultsLabel setHidden:NO];
    } else {
        [_noSearchResultsLabel setHidden:YES];
    }
    
    if (searching){
        return _filteredPhotos.count;
    } else if (showPrivate){
        self.searchBar.placeholder = @"Search private collection";
        return _privatePhotos.count;
    } else if (showLightTable){
        if (_table && _table.name.length){
            self.searchBar.placeholder = [NSString stringWithFormat:@"Search %@",_table.name];
        } else {
            self.searchBar.placeholder = @"Search light table";
        }
        return _table.photos.count;
    } else if (showFavorites){
        self.searchBar.placeholder = @"Search favorites";
        return _favoritePhotos.count;
    } else {
        self.searchBar.placeholder = @"Search Wölff Catalog";
        return _photos.count;
    }
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFPhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    Photo *photo;
    if (searching){
        photo = _filteredPhotos[indexPath.item];
    } else if (showPrivate){
        photo = _privatePhotos[indexPath.item];
    } else if (showLightTable){
        photo = _table.photos[indexPath.item];
    } else if (showFavorites){
        photo = _favoritePhotos[indexPath.item];
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if ((searching && searchText.length) || showFavorites || (showLightTable && _table) || showPrivate){
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
            [headerView.headerLabel setText:@"Private Art"];
        } else if (showLightTable) {
            [headerView.headerLabel setText:[NSString stringWithFormat:@"\"%@\" Art",_table.name]];
        } else if (showFavorites) {
            [headerView.headerLabel setText:@"Favorites"];
        } else if (searching) {
            if (searchText.length){
                [headerView.headerLabel setText:[NSString stringWithFormat:@"Search results for: \"%@\"",searchText]];
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
            self.table = nil;
            
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
        });
        
        [_tableView reloadData];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.collectionView && !searching){
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
    NSIndexPath *selectedIndexPath = [self.collectionView indexPathForItemAtPoint:loc];
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
        [self.collectionView reloadItemsAtIndexPaths:@[selectedIndexPath]];
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
    [self.collectionView deleteItemsAtIndexPaths:@[indexPathForFavoriteToRemove]];
}

- (void)removeLightTablePhoto:(UIMenuController*)menuController {
    Photo *photo = _table.photos[indexPathForLightTableArtToRemove.item];
    [_table removePhoto:photo];
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [self.collectionView deleteItemsAtIndexPaths:@[indexPathForLightTableArtToRemove]];
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
    [self.collectionView insertItemsAtIndexPaths:@[newArtIndexPath]];
    
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
            
            indexPathForFavoriteToRemove = [self.collectionView indexPathForItemAtPoint:loc];
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
            
            indexPathForLightTableArtToRemove = [self.collectionView indexPathForItemAtPoint:loc];
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
    if (showPrivate && indexPath.item < _privatePhotos.count){
        photo = _privatePhotos[indexPath.item];
    } else if (showLightTable && indexPath.item < _table.photos.count){
        photo = _table.photos[indexPath.item];
    } else if (showFavorites && indexPath.item < _favoritePhotos.count){
        photo = _favoritePhotos[indexPath.item];
    } else if (searching){
        if (_filteredPhotos.count && indexPath.item < _filteredPhotos.count){
            photo = _filteredPhotos[indexPath.item];
        }
    } else if (indexPath.item < _photos.count){
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
    [self.collectionView reloadData];
}

- (void)removePhoto:(Photo*)photo {
    if ([_selectedPhotos containsObject:photo]){
        [_selectedPhotos removeObject:photo];
    }
    if ([_photos containsObject:photo]){
        [_photos removeObject:photo];
    }
    [self.currentUser.favorites enumerateObjectsUsingBlock:^(Favorite *favorite, NSUInteger idx, BOOL *stop) {
        if (favorite.photo == photo){
            [_favoritePhotos removeObject:photo];
            [favorite MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
            *stop = YES;
        }
    }];
    for (Table *lightTable in _tables){
        if ([lightTable.photos containsObject:photo]){
            [lightTable removePhoto:photo];
        }
    }
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
        [self.collectionView reloadData];
    }
}

- (void)dismissMetadata {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)photoDeleted:(NSNumber *)photoId {
    Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:photoId inContext:[NSManagedObjectContext MR_defaultContext]];
    if (showPrivate){
        NSPredicate *privatePredicate = [NSPredicate predicateWithFormat:@"art.privateArt == %@ && art.user.identifier == %@", @YES, [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
        _privatePhotos = [NSMutableOrderedSet orderedSetWithArray:[Photo MR_findAllWithPredicate:privatePredicate inContext:[NSManagedObjectContext MR_defaultContext]]];
    } else if (showFavorites){
        [self.currentUser.favorites enumerateObjectsUsingBlock:^(Favorite *favorite, NSUInteger idx, BOOL *stop) {
            if (favorite.photo && ![_favoritePhotos containsObject:favorite.photo]) {
                [_favoritePhotos addObject:favorite.photo];
            }
        }];
    } else if (showLightTable && _table){
        [_table removePhoto:photo];
    } else {
        [_photos removeObject:photo];
    }
    [photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [self.collectionView reloadData];
    }];
}

- (void)artDeleted:(NSNumber *)photoId {
    if (!showLightTable && !showFavorites && !showPrivate){
        [self.collectionView reloadData];
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
    WFSearchResultsViewController *searchResultsVc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SearchResults"];
    [searchResultsVc setPhotos:_selectedPhotos];
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
    vc.notificationsDelegate = self;
    vc.preferredContentSize = CGSizeMake(470, 500);
    self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
    self.popover.delegate = self;
    [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)didSelectNotificationWithId:(NSNumber*)notificationId {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    
    Notification *notification = [Notification MR_findFirstByAttribute:@"identifier" withValue:notificationId inContext:[NSManagedObjectContext MR_defaultContext]];
    NSLog(@"Did select notification: %@",notification);
    if (notification.lightTable){
        [self showLightTable:notification.lightTable];
    } else if (notification.slideshow){
        [self slideshowSelected:notification.slideshow];
    } else if (notification.photo){
        [self showMetadata:notification.photo];
    } else if (notification.art){
        [self showMetadata:notification.art.photo];
    }
}

- (void)settingsPopover:(id)sender {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    WFMenuViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Menu"];
    vc.menuDelegate = self;
    vc.preferredContentSize = CGSizeMake(170, 150);
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
        vc.settingsDelegate = self;
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
        [vc setUser:self.currentUser];
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
        [WFAlert show:kLogoutMessage withTime:3.3f];
    }
    self.currentUser = nil;
    [self setUpNavBar];
    [self loadPhotos];
}

- (void)newSlideshow {
    [self newSlideshow:YES];
}

- (void)newSlideshow:(BOOL)withSelectedPhotos {
    [self.popover dismissPopoverAnimated:YES];
    if (self.currentUser.customerPlan.length){
        WFSlideshowSplitViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideshowSplitView"];
        [vc setPhotos:_photos];
        vc.slideshowDelegate = self;
        
        // create the new slideshow
        Slideshow *newSlideshow = [Slideshow MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        if (_selectedPhotos.count && withSelectedPhotos){
            [newSlideshow setPhotos:_selectedPhotos];
            
            [vc setSelectedPhotos:[NSMutableOrderedSet orderedSetWithOrderedSet:_selectedPhotos]];
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        [vc setSlideshow:newSlideshow];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self resetTransitionBooleans];
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    } else {
        [WFAlert show:@"Creating new slideshows requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
    }
}

- (void)slideshowSelected:(Slideshow *)slideshow {
    [self.popover dismissPopoverAnimated:YES];
    if (self.currentUser.customerPlan.length){
        WFSlideshowSplitViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideshowSplitView"];
        [vc setPhotos:_photos];
        vc.slideshowDelegate = self;
        [vc setSlideshowId:slideshow.identifier];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self resetTransitionBooleans];
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    } else {
        [WFAlert show:@"Adding selected art to a slideshow requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
    }
}

#pragma createSlidesShow Delegate
- (void)slideshowCreatedWithId:(NSNumber *)slideshowId {
    [self.tableView reloadData];
}

- (void)slideshowWithId:(NSNumber *)slideshowId droppedToLightTableWithId:(NSNumber *)lightTableId {
    [self.tableView reloadData];
}

- (void)showSlideshows {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        if (self.currentUser.customerPlan.length){
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
            [WFAlert show:@"The ability to show slideshows on this device requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
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
        CGRect collectionFrame = self.collectionView.frame;
        collectionFrame.origin.x = 0;
        collectionFrame.size.width += kSidebarWidth;
        slideshowsButton.selected = NO;
        tablesButton.selected = NO;
        [self.collectionView reloadData];
        
        [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _tableView.transform = CGAffineTransformIdentity;
            _comparisonContainerView.transform = CGAffineTransformIdentity;
            resetButton.transform = CGAffineTransformIdentity;
            [self.collectionView setFrame:collectionFrame];
        } completion:^(BOOL finished) {
            if (self.searchBar.isFirstResponder){
                [self.searchBar resignFirstResponder];
            }
        }];
    } else {
        tableIsVisible = YES;
        if (slideshowSidebarMode) {
            slideshowsButton.selected = YES;
        } else {
            tablesButton.selected = YES;
        }
        //show the light table sidebar
        CGRect collectionFrame = self.collectionView.frame;
        collectionFrame.origin.x = kSidebarWidth;
        collectionFrame.size.width -= kSidebarWidth;
        
         [self.collectionView reloadData];
        
        [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _tableView.transform = CGAffineTransformMakeTranslation(kSidebarWidth, 0);
            _comparisonContainerView.transform = CGAffineTransformMakeTranslation(kSidebarWidth, 0);
            resetButton.transform = CGAffineTransformMakeTranslation(-kSidebarWidth, 0);
            [self.collectionView setFrame:collectionFrame];
           
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
    [ProgressHUD show:@"Searching..."];
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
    if (!_filteredPhotos) _filteredPhotos = [NSMutableOrderedSet orderedSetWithOrderedSet:_photos];
    searching = YES;
    if (self.popover) [self.popover dismissPopoverAnimated:YES];
}

- (void)searchDidSelectPhotoWithId:(NSNumber *)photoId {
   
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
        NSOrderedSet *photosToIterateThrough;
        if (showLightTable && _table){
            photosToIterateThrough = _table.photos;
        } else if (showPrivate){
            photosToIterateThrough = _privatePhotos;
        } else if (showFavorites){
            photosToIterateThrough = _favoritePhotos;
        } else {
            photosToIterateThrough = _photos;
        }
        for (Photo *photo in photosToIterateThrough){
            // evaluate the art metadata, but actually add the photo to _filteredPhotos
            Art *art = photo.art;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", text];
            if([predicate evaluateWithObject:art.title]) {
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:art.artistsToSentence]){
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:art.locationsToSentence]){
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:art.materialsToSentence]){
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:photo.iconsToSentence]){
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:photo.credit]){
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:art.user.fullName]){
                [_filteredPhotos addObject:photo];
            }
        }
        
        if (!_filteredPhotos.count) [self loadPhotos];
    } else {
        _filteredPhotos = [NSMutableOrderedSet orderedSetWithOrderedSet:_photos];
    }
    
    [self.collectionView reloadData];
}

#pragma mark - WFSearchDelegate methods
- (void)batchSelectForLightTableWithId:(NSNumber *)lightTableId {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    if (self.currentUser.customerPlan.length){
        Table *lightTable = [Table MR_findFirstByAttribute:@"identifier" withValue:lightTableId inContext:[NSManagedObjectContext MR_defaultContext]];
        [lightTable addPhotos:_selectedPhotos.array];
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            __block NSMutableArray *photoIds = [NSMutableArray arrayWithCapacity:lightTable.photos.count];
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
                    [WFAlert show:[NSString stringWithFormat:@"%@ added to \"%@\"",photoCount, lightTable.name] withTime:3.3f];
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    NSLog(@"Failed to add selected to a light table: %@",error.description);
                }];
            }
        }];
    } else {
        [WFAlert show:@"Dropping selected art onto a light table requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
    }
}

- (void)newLightTableForSelected {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    if (self.currentUser.customerPlan.length){
        [self newLightTable];
    } else {
        [WFAlert show:@"Creating new light tables requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
    }
    
}

- (void)slideshowForSelected:(Slideshow *)slideshow {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    if (self.currentUser.customerPlan.length){
        if (slideshow){
            for (Photo *photo in _selectedPhotos){
                [slideshow addPhoto:photo];
            }
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                NSString *title = slideshow.title.length ? slideshow.title : @"No title";
                NSString *photoCount = _selectedPhotos.count == 1 ? [NSString stringWithFormat:@"1 photo dropped to \"%@\"",title] : [NSString stringWithFormat:@"%lu photos dropped to \"%@\"",(unsigned long)_selectedPhotos.count,title];
                [WFAlert show:photoCount withTime:3.3f];
                
                __block NSMutableArray *photoIds = [NSMutableArray array];
                [slideshow.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
                    [photoIds addObject:photo.identifier];
                }];
                if (photoIds.count){
                    if ([slideshow.identifier isEqualToNumber:@0]){
                        [self newSlideshow:YES];
                    } else {
                        [manager PATCH:[NSString stringWithFormat:@"slideshows/%@/add_photos",slideshow.identifier] parameters:@{@"slideshow":@{@"photo_ids":photoIds}, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                            NSLog(@"Success dropping photos to slideshow: %@",responseObject);
                            [slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
                            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                                [_tableView reloadData];
                            }];
                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            
                        }];
                    }
                }
            }];
        } else {
            [self newSlideshow:YES];
        }
    } else {
        [WFAlert show:@"Dropping selected art into a slideshow requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
    }
}

- (void)batchFavorite {
    NSLog(@"Batch favoriting for current user: %@",self.currentUser.fullName);
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] && self.currentUser){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        NSMutableArray *photoIds = [NSMutableArray arrayWithCapacity:_selectedPhotos.count];
        for (Photo *photo in _selectedPhotos){
            [photoIds addObject:photo.identifier];
            Favorite *favorite = [Favorite MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
            favorite.photo = photo;
            [_favoritePhotos addObject:photo];
            [self.currentUser addFavorite:favorite];
        }
    
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            NSLog(@"Done locally saving batch favorites: %u",success);
        }];
        
        if (photoIds.count){
            [parameters setObject:photoIds forKey:@"photo_ids"];
            [manager POST:@"favorites/batch" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Success batch favoriting: %@",responseObject);
                [self.currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
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
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
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

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)willShowKeyboard:(NSNotification*)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue *keyboardValue = keyboardInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect convertedKeyboardFrame = [self.view convertRect:keyboardValue.CGRectValue fromView:self.view.window];
    keyboardHeight = convertedKeyboardFrame.size.height;
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, keyboardHeight+44, 0);
                         self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, keyboardHeight+44, 0);
                     }
                     completion:NULL];
}

- (void)willHideKeyboard:(NSNotification *)notification {
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions animationCurve = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] unsignedIntegerValue];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)
                     animations:^{
                         self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
                         self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, 0, 0);
                     }
                     completion:NULL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (tableViewRefresh.isRefreshing){
        [tableViewRefresh endRefreshing];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
