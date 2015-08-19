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
#import "WFNoRotateNavController.h"
#import "WFTransparentBGModalAnimator.h"
#import "WFLoadingCell.h"

static NSString *const createALightTablePlaceholder            = @"Create a light table";
static NSString *const joinLightTablePlaceholder            = @"Join one that exists";
static NSString *const addNewArtOption = @"Add New Art";
static NSString *const notificationsOption = @"View My Notifications";
static NSString *const settingsOption = @"My Settings";
static NSString *const logoutOption = @"Log out";

@interface WFCatalogViewController () <UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIViewControllerTransitioningDelegate,UIPopoverControllerDelegate, UIAlertViewDelegate, WFLoginDelegate, WFMenuDelegate,  WFSlideshowDelegate, WFImageViewDelegate, WFSearchDelegate, WFMetadataDelegate, WFNewArtDelegate, WFLightTableDelegate, WFNotificationsDelegate, WFSettingsDelegate, UIGestureRecognizerDelegate, UIActionSheetDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    UIButton *homeButton;
    UIBarButtonItem *homeBarButton;
    UIButton *slideshowsButton;
    UIBarButtonItem *slideshowsBarButton;
    UIButton *tablesButton;
    UIBarButtonItem *lightTablesButton;
    UIButton *notificationsButton;
    UIBarButtonItem *notificationsBarButton;
    UIBarButtonItem *refreshButton;
    CGFloat width, height, keyboardHeight;
    NSMutableOrderedSet *_photos;
    NSMutableOrderedSet *_myPhotos;
    NSMutableOrderedSet *_favoritePhotos;
    NSMutableOrderedSet *_filteredPhotos;
    NSMutableOrderedSet *_lightTables;
    NSMutableOrderedSet *_slideshows;
    NSMutableOrderedSet *_uncategorizesSlideshows;
    NSMutableArray *_filteredTables;
    UIBarButtonItem *addButton;
    UIBarButtonItem *settingsButton;
    UILabel *selectedLabel;
    UIImageView *checkboxView;
    UIBarButtonItem *selectedBarButtonItem;
    UIBarButtonItem *loginButton;
    UIBarButtonItem *searchButton;
    UIButton *newLightTableButton;
    UIButton *expandLightTablesButton;
    BOOL expanded;
    BOOL metadata;
    BOOL loggedIn;

    BOOL comparison;
    BOOL settings;
    BOOL newArt;
    BOOL newUser;
    BOOL profile;
    BOOL newLightTableTransition;
    BOOL transparentBG;
    BOOL groupBool;
    BOOL sidebarIsVisible;
    BOOL canLoadMore;
    BOOL canSearchMore;
    BOOL canLoadMoreOfMyArt;
    
    BOOL showSlideshow;
    BOOL showMyArt;
    BOOL showFavorites;
    BOOL showLightTable;

    BOOL slideshowSidebarMode;
    BOOL searchVisible;
    
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
    
    UIActionSheet *iPhoneMenu;
    NSString *searchText;
    UIImageView *navBarShadowView;
}

@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) LightTable *lightTable;
@property (weak, nonatomic) IBOutlet UIView *comparisonContainerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *dragForComparisonLabel;
@property (nonatomic) WFInteractiveImageView *draggingView;
@property (nonatomic) NSIndexPath *startIndex;
@property (nonatomic) CGPoint dragViewStartLocation;
@property (nonatomic) NSIndexPath *moveToIndexPath;
@property (nonatomic, strong) id<WFLightTablesDelegate> groupsInteractor;
@property (strong, nonatomic) AFHTTPRequestOperation *mainRequest;
@property (strong, nonatomic) AFHTTPRequestOperation *dashboardRequest;
@property (strong, nonatomic) AFHTTPRequestOperation *lightTableRequest;
@end

@implementation WFCatalogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    width = screenWidth(); height = screenHeight();
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    _photos = [NSMutableOrderedSet orderedSet];
    _selectedPhotos = [NSMutableOrderedSet orderedSet];
    _myPhotos = [NSMutableOrderedSet orderedSet];
    _favoritePhotos = [NSMutableOrderedSet orderedSet];
    _slideshows = [NSMutableOrderedSet orderedSetWithArray:[Slideshow MR_findAllInContext:[NSManagedObjectContext MR_defaultContext]]];
    
    //set up the light table sidebar
    expanded = NO;
    [self setUpTableView];
    [self setUpGestureRecognizers];
    
    [_comparisonContainerView setBackgroundColor:[UIColor colorWithWhite:0 alpha:.9f]];
    _dragForComparisonLabel.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansThin] size:0];
    [_dragForComparisonLabel setTextColor:[UIColor colorWithWhite:.5f alpha:1.f]];
    
    /*self.groupsInteractor = [[WFGroupsInteractor alloc] initWithParentViewController:self];
    UIScreenEdgePanGestureRecognizer *gestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self.groupsInteractor action:@selector(userDidPan:)];
    gestureRecognizer.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:gestureRecognizer];*/
    
    self.collectionView.delaysContentTouches = NO;
    [self.collectionView setBackgroundColor:[UIColor whiteColor]];
    collectionViewRefresh = [[UIRefreshControl alloc] init];
    [collectionViewRefresh addTarget:self action:@selector(refreshCollectionView) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:collectionViewRefresh];
    self.collectionView.alwaysBounceVertical = YES;
    canLoadMore = YES;
    canSearchMore = YES;
    canLoadMoreOfMyArt = YES;
    
    if (IDIOM != IPAD){
        CGRect tableFrame = self.tableView.frame;
        CGRect comparisonFrame = self.comparisonContainerView.frame;
        comparisonFrame.origin.y = tableFrame.size.height;
        comparisonFrame.size.height = height - tableFrame.size.height;
        [self.comparisonContainerView setFrame:comparisonFrame];
    }
    
    [self setUpSearch];
    [self loadBeforePhoto:nil];
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [ProgressHUD show:@"Loading art..."];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccessful) name:LOGGED_IN object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loggedOut) name:LOGGED_OUT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideEditMenu:) name:UIMenuControllerWillHideMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didHideEditMenu:) name:UIMenuControllerDidHideMenuNotification object:nil];
    
    [self setUpNavBar]; //set up the nav buttons
}

- (void)setUpNavBar {
    homeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    homeButton.frame = CGRectMake(14.0, 0.0, 66.0, self.navigationController.navigationBar.frame.size.height);
    [homeButton setBackgroundColor:[UIColor colorWithWhite:0 alpha:.1975f]];
    [homeButton setImage:[UIImage imageNamed:@"homeIcon"] forState:UIControlStateNormal];
    [homeButton addTarget:self action:@selector(resetCatalog) forControlEvents:UIControlEventTouchUpInside];
    homeBarButton = [[UIBarButtonItem alloc] initWithCustomView:homeButton];
    
    tablesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [tablesButton setImage:[UIImage imageNamed:@"whiteTables"] forState:UIControlStateNormal];
    [tablesButton setImage:[UIImage imageNamed:@"blueTables"] forState:UIControlStateSelected];
    [tablesButton addTarget:self action:@selector(showLightTables) forControlEvents:UIControlEventTouchUpInside];
    lightTablesButton = [[UIBarButtonItem alloc] initWithCustomView:tablesButton];
    
    slideshowsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [slideshowsButton setImage:[UIImage imageNamed:@"whiteSlideshow"] forState:UIControlStateNormal];
    [slideshowsButton setImage:[UIImage imageNamed:@"saffronSlideshow"] forState:UIControlStateSelected];
    [slideshowsButton addTarget:self action:@selector(showSlideshows) forControlEvents:UIControlEventTouchUpInside];
    slideshowsBarButton = [[UIBarButtonItem alloc] initWithCustomView:slideshowsButton];
    
    addButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"plus"] style:UIBarButtonItemStylePlain target:self action:@selector(add)];
    
    UIView *customSelectedView = [[UIView alloc] initWithFrame:(IDIOM == IPAD) ? CGRectMake(0, 0, 38, 44) : CGRectMake(0, 0, 53, 44)];
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
    
    UIBarButtonItem *negativeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    negativeButton.width = -20.f;
    
    if (IDIOM == IPAD){
        slideshowsButton.contentEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 22);
        tablesButton.contentEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 0);
        tablesButton.frame = CGRectMake(8.0, 0.0, 58.0, 44.0);
        slideshowsButton.frame = CGRectMake(0.0, 0.0, 64.0, 44.0);
        self.navigationItem.leftBarButtonItems = @[negativeButton, homeBarButton, lightTablesButton,slideshowsBarButton];
    } else {
        slideshowsButton.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
        tablesButton.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    }
    
    UIBarButtonItem *flexibleSpace1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *flexibleSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *flexibleSpace3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *flexibleSpace4 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *moreButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"more"] style:UIBarButtonItemStylePlain target:self action:@selector(showiPhoneMenu)];
    searchButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search15"] style:UIBarButtonItemStylePlain target:self action:@selector(showSearch)];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        loggedIn = YES;
        self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
        
        if (IDIOM == IPAD){
            settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPopover:)];
            notificationsButton = [UIButton buttonWithType:UIButtonTypeCustom];
            notificationsButton.frame = CGRectMake(0.0, 0.0, 42.0, 42.0);
            [notificationsButton setImage:[UIImage imageNamed:@"whiteAlert"] forState:UIControlStateNormal];
            [notificationsButton setImage:[UIImage imageNamed:@"saffronAlert"] forState:UIControlStateSelected];
            [notificationsButton addTarget:self action:@selector(showNotifications) forControlEvents:UIControlEventTouchUpInside];
            notificationsBarButton = [[UIBarButtonItem alloc] initWithCustomView:notificationsButton];
            
            [self setNotificationColor];
            self.navigationItem.rightBarButtonItems = @[addButton, selectedBarButtonItem, notificationsBarButton, settingsButton];
        } else {
            
            self.navigationItem.leftBarButtonItems = @[negativeButton, homeBarButton, lightTablesButton, flexibleSpace1, slideshowsBarButton, flexibleSpace2, selectedBarButtonItem, flexibleSpace3, searchButton, flexibleSpace4, moreButton];
        }
        
        if (!tableViewRefresh){
            tableViewRefresh = [[UIRefreshControl alloc] init];
            [tableViewRefresh addTarget:self action:@selector(refreshTableView:) forControlEvents:UIControlEventValueChanged];
            [self.tableView addSubview:tableViewRefresh];
        }
        
    } else {
        loggedIn = NO;
        loginButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login"] style:UIBarButtonItemStylePlain target:self action:@selector(showLogin)];
        if (IDIOM == IPAD){
            self.navigationItem.rightBarButtonItems = @[loginButton, addButton];
        } else {
            self.navigationItem.leftBarButtonItems = @[negativeButton, homeBarButton, flexibleSpace1, lightTablesButton, flexibleSpace2, slideshowsBarButton, flexibleSpace3, searchButton, flexibleSpace4, loginButton];
        }
    }
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    topInset = self.navigationController.navigationBar.frame.size.height;
    self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, topInset, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, topInset, 0);
    
    if (IDIOM == IPAD){
        self.navigationItem.titleView = self.searchBar;
    }
}

- (void)setNotificationColor {
    [notificationsButton setSelected:[[UIApplication sharedApplication] applicationIconBadgeNumber] ? YES : NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    navBarShadowView.hidden = YES;
    self.currentUser = [self.currentUser MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (sidebarIsVisible && _photos.count){
        [self.tableView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kExistingUser]){
        [self showWalkthrough];
    }
}

- (void)showWalkthrough {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .77f * NSEC_PER_SEC);
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
    if (loggedIn){
        if (slideshowSidebarMode){
            [self loadSlideshows];
        } else {
            [self loadLightTables];
        }
    } else {
        [refreshControl endRefreshing];
        [self showLogin];
    }
}

- (void)loadSlideshows {
    [ProgressHUD show:@"Refreshing slideshows..."];
    [manager GET:[NSString stringWithFormat:@"users/%@/slideshow_titles",self.currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
            _slideshows = tempSet;
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

- (void)loadSlideshow:(Slideshow*)slideshow {
    [ProgressHUD show:[NSString stringWithFormat:@"Fetching \"%@\"...",slideshow.title]];
    [manager GET:[NSString stringWithFormat:@"slideshows/%@",slideshow.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading slideshow: %@",responseObject);
        if ([responseObject objectForKey:@"slideshow"]){
            [slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
        } else {
            
        }
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            [ProgressHUD dismiss];
            [self transitionToSlideshow:slideshow];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load slideshow: %@",error.description);
        [ProgressHUD dismiss];
        [[[UIAlertView alloc] initWithTitle:@"Uh oh" message:@"We weren't able to pull the latest info for this slideshow, so we're showing you what's currently on your device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
        [self transitionToSlideshow:slideshow];
        
    }];
}

- (void)transitionToSlideshow:(Slideshow*)slideshow {
    if (slideshow.user && [slideshow.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [self slideshowSelected:slideshow];
        return;
    } else {
        WFSlideshowViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Slideshow"];
        WFNoRotateNavController *nav = [[WFNoRotateNavController alloc] initWithRootViewController:vc];
        [vc setSlideshow:slideshow];
        
        if (IDIOM == IPAD){
            [self resetTransitionBooleans];
            nav.transitioningDelegate = self;
            nav.modalPresentationStyle = UIModalPresentationCustom;
            [self presentViewController:nav animated:YES completion:NULL];
        } else {
            NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .5f * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self presentViewController:nav animated:YES completion:NULL];
            });
        }
    }
}

- (void)refreshCollectionView {
    [ProgressHUD show:@"Refreshing Art..."];
    [self doneEditing];
    if (showMyArt){
        [_myPhotos removeAllObjects];
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        [self loadMyArt];
    } else if (showFavorites){
        [_favoritePhotos removeAllObjects];
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        [self loadFavorites];
    } else {
        canLoadMore = YES;
        [_photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
            [photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
        }];
        [_filteredPhotos removeAllObjects];
        [_photos removeAllObjects];
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
        [self loadBeforePhoto:nil];
    }
}

- (void)setUpTableView {
    [self.tableView setBackgroundColor:[UIColor blackColor]];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.rowHeight = 60.f;
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

#pragma mark - Login/Logout Delegate
- (void)loginSuccessful {
    self.currentUser = [User MR_findFirstByAttribute:@"identifier" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] inContext:[NSManagedObjectContext MR_defaultContext]];
    loggedIn = YES;
    [self setUpNavBar];
    if (sidebarIsVisible) [self.tableView reloadData];
    [ProgressHUD dismiss];
}

- (void)logout {
    if (sidebarIsVisible) [self showSidebar];
    loggedIn = NO;
    
    [delegate logout];
    [self loggedOut];
    
    // refresh the catalog
    showMyArt = NO;
    showFavorites = NO;
    self.lightTable = nil;
    showLightTable = NO;
    canLoadMore = YES;
    [_photos removeAllObjects];
    [_filteredPhotos removeAllObjects];
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .37f * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [WFAlert show:kLogoutMessage withTime:3.3f];
        [self loadBeforePhoto:nil];
    });
    
}

- (void)loggedOut {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    self.currentUser = nil;
    [self setUpNavBar];
    [self.tableView reloadData];
}

- (void)loadBeforePhoto:(Photo*)lastPhoto {
    if (self.mainRequest) return;
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@(ART_THROTTLE) forKey:@"count"];
    if (searchText.length){
        [parameters setObject:searchText forKey:@"search"];
    }
    if (showLightTable && _lightTable){
        [parameters setObject:_lightTable.identifier forKey:@"light_table_id"];
    }

    if (lastPhoto){
        [parameters setObject:[NSNumber numberWithInt:round([lastPhoto.createdDate timeIntervalSince1970])] forKey:@"before_date"]; // last item in feed
    } else {
        [parameters setObject:[NSNumber numberWithInt:round([[NSDate date] timeIntervalSince1970])] forKey:@"after_date"]; // today
    }
    if (loggedIn){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        if (showMyArt){
            [parameters setObject:@YES forKey:@"my_art"];
        }
    }
    self.mainRequest = [manager GET:@"photos" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *photosDict = [responseObject objectForKey:@"photos"];
        if (photosDict.count){
            NSLog(@"How many photos did we pull? %lu. Can we load more? %u",(unsigned long)photosDict.count, canLoadMore);
            for (id dict in photosDict) {
                Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
                if (!photo){
                    photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
                }
                [photo populateFromDictionary:dict];
                [_photos addObject:photo];
            }
            
            NSSortDescriptor *chronologicalSort = [NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:NO];
            [_photos sortUsingDescriptors:@[chronologicalSort]];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                if (self.searchBar.text.length){
                    [self filterContentForSearchText:searchText scope:nil];
                    if (photosDict.count < ART_THROTTLE){
                        NSLog(@"Searching, but can't search more");
                        canSearchMore = NO;
                    } else {
                        NSLog(@"Searching, CAN search more");
                        canSearchMore = YES;
                    }
                } else if (showMyArt){
                    if (photosDict.count < ART_THROTTLE){
                        canLoadMoreOfMyArt = NO;
                    } else {
                        canLoadMoreOfMyArt = YES;
                    }
                } else {
                    if (photosDict.count < ART_THROTTLE){
                        canLoadMore = NO;
                    } else {
                        canLoadMore = YES;
                    }
                    [self.collectionView reloadData];
                }
                [self endRefresh];
            }];
        } else {
            canLoadMore = NO;
            [self endRefresh];
            NSLog(@"How many photos did we pull? %lu. Can we load more? %u",(unsigned long)photosDict.count, canLoadMore);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self endRefresh];
    }];
}

- (void)endRefresh {
    self.mainRequest = nil;
    [ProgressHUD dismiss];
    if (tableViewRefresh.isRefreshing){
        [tableViewRefresh endRefreshing];
    }
    if (collectionViewRefresh.isRefreshing){
        [collectionViewRefresh endRefreshing];
    }
}

- (void)loadLightTables {
    if (self.dashboardRequest) return;
    if (self.currentUser){
        [ProgressHUD show:@"Refreshing your light tables..."];
        
        self.dashboardRequest = [manager GET:[NSString stringWithFormat:@"users/%@/dashboard",self.currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting user dashboard: %@", responseObject);
            [self.currentUser populateFromDictionary:[responseObject objectForKey:@"user"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {

                NSPredicate *myPredicate = [NSPredicate predicateWithFormat:@"user.identifier == %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
                _myPhotos = [NSMutableOrderedSet orderedSetWithArray:[Photo MR_findAllWithPredicate:myPredicate inContext:[NSManagedObjectContext MR_defaultContext]]];
                NSSortDescriptor *reverseChronologicalSort = [NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:NO];
                [_myPhotos sortUsingDescriptors:@[reverseChronologicalSort]];
            
                [self.currentUser.favorites enumerateObjectsUsingBlock:^(Favorite *favorite, NSUInteger idx, BOOL *stop) {
                    if (favorite.photo && ![_favoritePhotos containsObject:favorite.photo]) {
                        [_favoritePhotos addObject:favorite.photo];
                    }
                }];
                [_favoritePhotos sortUsingDescriptors:@[reverseChronologicalSort]];
                
                NSLog(@"_myPhotos count: %lu",(unsigned long)_myPhotos.count);
                NSLog(@"_favorites count: %lu",(unsigned long)_favoritePhotos.count);
                
                [self.collectionView reloadData];
                [self.tableView reloadData];
                [self endRefresh];
                self.dashboardRequest = nil;
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get user art: %@",error.description);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to load your art. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            
            [self endRefresh];
            self.dashboardRequest = nil;
        }];
    }
}

- (void)loadMyArt {
    if (self.dashboardRequest) return;
    if (self.currentUser){
        [ProgressHUD show:@"Fetching your art..."];
        self.dashboardRequest = [manager GET:[NSString stringWithFormat:@"users/%@/art",self.currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting user art: %@", responseObject);
            [self parsePhotos:[responseObject objectForKey:@"photos"]];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                NSPredicate *myPredicate = [NSPredicate predicateWithFormat:@"user.identifier == %@",[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]];
                _myPhotos = [NSMutableOrderedSet orderedSetWithArray:[Photo MR_findAllWithPredicate:myPredicate inContext:[NSManagedObjectContext MR_defaultContext]]];
                
                NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:NO];
                [_myPhotos sortUsingDescriptors:@[sort]];
                
                NSLog(@"_myPhotos count: %lu",(unsigned long)_myPhotos.count);
                [self.currentUser.favorites enumerateObjectsUsingBlock:^(Favorite *favorite, NSUInteger idx, BOOL *stop) {
                    if (favorite.photo && ![_favoritePhotos containsObject:favorite.photo]) {
                        [_favoritePhotos addObject:favorite.photo];
                    }
                }];
                NSLog(@"_favorites count: %lu",(unsigned long)_favoritePhotos.count);
                [self.collectionView reloadData];
                [self endRefresh];
                self.dashboardRequest = nil;
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            //NSLog(@"Failed to get user art: %@",error.description);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to load your art. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            
            [self endRefresh];
            self.dashboardRequest = nil;
        }];
    }
}

- (void)parsePhotos:(NSArray*)photos {
    for (id dict in photos){
        Photo *photo = [Photo MR_findFirstByAttribute:@"identifier" withValue:[dict objectForKey:@"id"] inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!photo){
            photo = [Photo MR_createInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [photo populateFromDictionary:dict];
    }
}

- (void)loadFavorites {
    if (self.dashboardRequest) return;
    if (self.currentUser){
        [ProgressHUD show:@"Refreshing your favorites..."];
        self.dashboardRequest = [manager GET:[NSString stringWithFormat:@"users/%@/favorites",self.currentUser.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success getting user favorites: %@", responseObject);
            [self parsePhotos:[responseObject objectForKey:@"photos"]];
            
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [self.currentUser.favorites enumerateObjectsUsingBlock:^(Favorite *favorite, NSUInteger idx, BOOL *stop) {
                    if (favorite.photo && ![_favoritePhotos containsObject:favorite.photo]) {
                        [_favoritePhotos addObject:favorite.photo];
                    }
                }];
                [self.collectionView reloadData];
                [self endRefresh];
                self.dashboardRequest = nil;
            }];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to get user favorites: %@",error.description);
            [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"Something went wrong while trying to load your favorites. Please try again soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            [self endRefresh];
            self.dashboardRequest = nil;
        }];
    }
}

- (void)add {
    if (loggedIn){
        if (self.currentUser.customerPlan.length){
            if (self.popover)
                [self.popover dismissPopoverAnimated:YES];
            [self resetArtBooleans];
            newArt = YES;
            WFNewArtViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"NewArt"];
            vc.artDelegate = self;
            
            if (IDIOM == IPAD){
                vc.transitioningDelegate = self;
                vc.modalPresentationStyle = UIModalPresentationCustom;
                [self presentViewController:vc animated:YES completion:NULL];
            } else {
                WFNoRotateNavController *nav = [[WFNoRotateNavController alloc] initWithRootViewController:vc];
                nav.transitioningDelegate = self;
                nav.modalPresentationStyle = UIModalPresentationCustom;
                [self presentViewController:nav animated:YES completion:NULL];
            }
        } else {
            [WFAlert show:@"Uploading art to the Wölff catalog requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
        }
    } else {
        [self showLogin];
    }
}

- (void)newArtAdded:(Art *)a {
    Art *art = [a MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (showFavorites || showLightTable || self.searchBar.text.length){
        //don't animate the changes if the user is looking at a light table, their favorites, or searching.
    } else {
        [self.collectionView performBatchUpdates:^{
            NSMutableArray *indexPathArray = [NSMutableArray array];
            [art.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
                if ([photo.user.identifier isEqualToNumber:self.currentUser.identifier]/*[photo.privatePhoto isEqualToNumber:@YES] || [photo.art.privateArt isEqualToNumber:@YES]*/){
                    [_myPhotos insertObject:photo atIndex:idx];
                    
                    if (showMyArt){
                        [indexPathArray addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
                    }
                } else {
                    [_photos insertObject:photo atIndex:0];
                    [indexPathArray addObject:[NSIndexPath indexPathForItem:idx inSection:0]];
                }
            }];
            [self.collectionView insertItemsAtIndexPaths:indexPathArray];
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)updateNewArt:(Art *)a {
    Art *art = [a MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (showFavorites || showLightTable || self.searchBar.text.length){
        
    } else {
        NSMutableArray *indexPathArray = [NSMutableArray array];
        [art.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
            if (showMyArt /*&& ([photo.privatePhoto isEqualToNumber:@YES] || [photo.art.privateArt isEqualToNumber:@YES])*/){
                [indexPathArray addObject:[NSIndexPath indexPathForItem:[_myPhotos indexOfObject:photo] inSection:0]];
            } else {
                [_photos enumerateObjectsUsingBlock:^(Photo *p, NSUInteger idx, BOOL *stop) {
                    if ([p.fileName isEqualToString:photo.fileName]){
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
                        [indexPathArray addObject:indexPath];
                        [_photos replaceObjectAtIndex:idx withObject:photo];
                        *stop = YES;
                    }
                }];
            }
        }];
        
        if (indexPathArray.count){
            [self.collectionView reloadItemsAtIndexPaths:indexPathArray];
        }
    }
}

- (void)failedToAddArt:(Art*)art {
    //[WFAlert show:[NSString stringWithFormat:@"Something went wrong while trying to add \"%@\" to the catalog. Please try again soon.",art.title] withTime:3.7f];
}

//- (void)resetSlideshows {
//    _slideshows = [NSMutableOrderedSet orderedSetWithArray:[Slideshow MR_findAllInContext:[NSManagedObjectContext MR_defaultContext]]];
//    NSSortDescriptor *alphabeticalSlideshowSort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
//    [_slideshows sortUsingDescriptors:[NSArray arrayWithObject:alphabeticalSlideshowSort]];
//}

- (void)resetLightTables {
    _lightTables = [NSMutableOrderedSet orderedSetWithOrderedSet:self.currentUser.lightTables];
    NSSortDescriptor *alphabeticalTableSort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [_lightTables sortUsingDescriptors:[NSArray arrayWithObject:alphabeticalTableSort]];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    [self resetLightTables];
    if (slideshowSidebarMode){
        return 2 + _lightTables.count;
    } else {
        return 3;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (slideshowSidebarMode){
        if (section == 0){
            return 1;
        } else if (section == _lightTables.count + 1){
            if (!_uncategorizesSlideshows) _uncategorizesSlideshows = [NSMutableOrderedSet orderedSet];
            [_slideshows enumerateObjectsUsingBlock:^(Slideshow *slideshow, NSUInteger idx, BOOL *stop) {
                if (!slideshow.lightTables.count) [_uncategorizesSlideshows addObject:slideshow];
            }];
            return _uncategorizesSlideshows.count;
        } else {
            LightTable *lightTable = _lightTables[section-1];
            return lightTable.slideshows.count;
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
                if (_lightTables.count){
                    return _lightTables.count;
                } else if (loggedIn) {
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
            [cell.iconImageView setImage:[UIImage imageNamed:@"whitePlus"]];
            [cell.label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
            [cell.label setText:@"New Slideshow"];
            [cell.scrollView setScrollEnabled:NO];
            
        } else {
            cell.tintColor = [UIColor whiteColor];
            [cell.scrollView setScrollEnabled:YES];
            [cell.contentView addGestureRecognizer:cell.scrollView.panGestureRecognizer];
            [cell.iconImageView setImage:nil];
            [cell.label setText:@""];
            
            if (indexPath.section == _lightTables.count+1){
                Slideshow *slideshow = _uncategorizesSlideshows[indexPath.row];
                [cell configureForSlideshow:slideshow];
                [cell.actionButton setTag:slideshow.identifier.integerValue];
                [cell.actionButton addTarget:self action:@selector(slideshowAction:) forControlEvents:UIControlEventTouchUpInside];
            } else {
                LightTable *lightTable = _lightTables[indexPath.section-1];
                Slideshow *slideshow = lightTable.slideshows[indexPath.row];
                [cell configureForSlideshow:slideshow];
                [cell.actionButton setTag:slideshow.identifier.integerValue];
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
                [cell.label setText:@"My Art"];
                if (showMyArt){
                    [cell.iconImageView setImage:[UIImage imageNamed:@"paintbrushBlue"]];
                    [cell.label setTextColor:kElectricBlue];
                    cell.label.highlightedTextColor = kElectricBlue;
                    [cell setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
                } else {
                    [cell.iconImageView setImage:[UIImage imageNamed:@"whitePaintbrush"]];
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
            [cell.label setTextColor:[UIColor whiteColor]];
            [cell.label setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansSemibold] size:0]];
            return cell;
        } else {
            WFLightTableCell *cell = (WFLightTableCell *)[tableView dequeueReusableCellWithIdentifier:@"LightTableCell"];
            [cell setBackgroundColor:[UIColor clearColor]];
            if (_lightTables.count){
                LightTable *lightTable = _lightTables[indexPath.row];
                [cell configureForTable:lightTable];
                [cell.label setText:@""];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                if (lightTable == _lightTable){
                    [cell.tableLabel setTextColor:kElectricBlue];
                    [cell.pieceCountLabel setTextColor:kElectricBlue];
                    [cell setBackgroundColor:[UIColor colorWithWhite:1 alpha:.07]];
                } else {
                    [cell.tableLabel setTextColor:[UIColor whiteColor]];
                    [cell.pieceCountLabel setTextColor:[UIColor lightGrayColor]];
                    [cell setBackgroundColor:[UIColor clearColor]];
                }
            } else {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                if (loggedIn){
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (slideshowSidebarMode && section != 0){
        if (section == _lightTables.count+1){
            return 34.f;
        } else {
            LightTable *lightTable = _lightTables[section-1];
            return lightTable.slideshows.count ? 34.f : 0.f;
        }
    } else {
        return 0.f;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGFloat headerHeight = (slideshowSidebarMode && section != 0) ? 34.f : 0.f;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, headerHeight)];
    [headerView setBackgroundColor:[UIColor colorWithWhite:.07 alpha:1]];
    
    if (section == _lightTables.count+1){
        UILabel *lightTableLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 0, kSidebarWidth, headerHeight)];
        [lightTableLabel setText:@"Uncategorized"];
        [lightTableLabel setBackgroundColor:[UIColor clearColor]];
        [lightTableLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSans] size:0]];
        [lightTableLabel setTextAlignment:NSTextAlignmentLeft];
        [lightTableLabel setTextColor:[UIColor lightGrayColor]];
        [headerView addSubview:lightTableLabel];
    } else if (section != 0){
        LightTable *lightTable = _lightTables[section-1];
        if (lightTable.slideshows.count){
            UILabel *lightTableLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 0, kSidebarWidth, headerHeight)];
            [lightTableLabel setText:lightTable.name];
            [lightTableLabel setBackgroundColor:[UIColor clearColor]];
            [lightTableLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleCaption2 forFont:kMuseoSans] size:0]];
            [lightTableLabel setTextAlignment:NSTextAlignmentLeft];
            [lightTableLabel setTextColor:[UIColor lightGrayColor]];
            [headerView addSubview:lightTableLabel];
        }
    }

    return headerView;
}

- (void)slideshowAction:(UIButton*)button{
    NSNumber *slideshowId = @(button.tag);
    Slideshow *slideshow = [Slideshow MR_findFirstByAttribute:@"identifier" withValue:slideshowId inContext:[NSManagedObjectContext MR_defaultContext]];
    if (!slideshow) return;
    if ([slideshow.user.identifier isEqualToNumber:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [self deleteSlideshow:slideshow atIndexPath:nil];
    } else {
        [self removeSlideshow:slideshow atIndexPath:nil];
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
    
    [_slideshows removeObject:slideshow];
    if ([_uncategorizesSlideshows containsObject:slideshow]){
        [_uncategorizesSlideshows removeObject:slideshow];
    }
    [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [UIView animateWithDuration:kFastAnimationDuration animations:^{
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
            //redraw the rest of the tableview
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }];
}

- (void)removeSlideshow:(Slideshow *)slideshow atIndexPath:(NSIndexPath*)indexPath {
    [_slideshows removeObject:slideshow];
    if ([_uncategorizesSlideshows containsObject:slideshow]){
        [_uncategorizesSlideshows removeObject:slideshow];
    }
    [slideshow MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [UIView animateWithDuration:kFastAnimationDuration animations:^{
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
            //redraw the rest of the tableview
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }];
}

- (void)editLightTable:(UIButton *)button {
    LightTable *lightTable = _lightTables[button.tag];
    WFLightTableDetailsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"LightTableDetails"];
    [vc setLightTable:lightTable];
    vc.lightTableDelegate = self;
    
    [self resetTransitionBooleans];
    newLightTableTransition = YES;
    
    if (IDIOM == IPAD){
        vc.modalPresentationStyle = UIModalPresentationCustom;
        vc.transitioningDelegate = self;
        [self presentViewController:vc animated:YES completion:^{ }];
    } else {
        WFNoRotateNavController *nav = [[WFNoRotateNavController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationCustom;
        nav.transitioningDelegate = self;
        [self presentViewController:nav animated:YES completion:^{
            
        }];
    }
}

- (void)lightTableAction:(UIButton*)button{
    LightTable *lightTable = _lightTables[button.tag];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag inSection:2];
    if (lightTable && [lightTable includesOwnerId:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]]){
        [self deleteLightTable:lightTable atIndexPath:indexPath];
    } else {
        [self leaveLightTable:lightTable atIndexPath:indexPath];
    }
}

- (void)deleteLightTable:(LightTable *)lightTable atIndexPath:(NSIndexPath*)indexPath {
    WFLightTableCell *cell = (WFLightTableCell*)[_tableView cellForRowAtIndexPath:indexPath];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (loggedIn){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    if (![lightTable.identifier isEqualToNumber:@0]){
       self.lightTableRequest = [manager DELETE:[NSString stringWithFormat:@"light_tables/%@",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success deleting this light table: %@",responseObject);
           self.lightTableRequest = nil;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failed to delete this light table: %@",error.description);
            self.lightTableRequest = nil;
        }];
    }
    
    [self.tableView beginUpdates];
    [lightTable MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        _lightTables = _lightTables ? self.currentUser.lightTables.array.mutableCopy : [NSMutableArray arrayWithArray:self.currentUser.lightTables.array];
        
        [UIView animateWithDuration:kFastAnimationDuration animations:^{
            [cell.scrollView setContentOffset:CGPointZero];
            if (_lightTables.count){
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

- (void)leaveLightTable:(LightTable *)lightTable atIndexPath:(NSIndexPath*)indexPath {
    WFLightTableCell *cell = (WFLightTableCell*)[_tableView cellForRowAtIndexPath:indexPath];
    if (![lightTable.identifier isEqualToNumber:@0]){
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
        self.lightTableRequest = [manager DELETE:[NSString stringWithFormat:@"light_tables/%@/leave",lightTable.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Success leaving table: %@",responseObject);
            self.lightTableRequest = nil;
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error leaving light table: %@",error.description);
            self.lightTableRequest = nil;
        }];
    }
    
    [self.tableView beginUpdates];
    [lightTable MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        _lightTables = _lightTables ? self.currentUser.lightTables.array.mutableCopy : [NSMutableArray arrayWithArray:self.currentUser.lightTables.array];
        
        [UIView animateWithDuration:kFastAnimationDuration animations:^{
            [cell.scrollView setContentOffset:CGPointZero];
            if (_lightTables.count){
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (slideshowSidebarMode){
        Slideshow *slideshow;
        if (indexPath.section == 0){
            [self newSlideshow:NO];
            return;
        } else if (indexPath.section == _lightTables.count + 1){
            slideshow = _uncategorizesSlideshows[indexPath.row];
        } else {
            LightTable *lightTable = _lightTables[indexPath.section-1];
            if (lightTable.slideshows.count > indexPath.row) slideshow = lightTable.slideshows[indexPath.row];
        }
        
        if (slideshow) [self loadSlideshow:slideshow];
    } else {
        if (indexPath.section == 0){
            if (indexPath.row == 0){
                [self showMyArt];
            } else {
                [self showFavorites];
            }
            if (loggedIn){
                [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)] withRowAnimation:UITableViewRowAnimationAutomatic];
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .23f * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self showSidebar];
                });
            }
        } else if (indexPath.section == 1){
            [self newLightTable];
        } else if (indexPath.section == 2){
            if (loggedIn){
                if (self.currentUser.customerPlan.length){
                    if (_lightTables.count){
                        LightTable *lightTable = _lightTables[indexPath.row];
                        if (_lightTable == lightTable){
                            self.lightTable = nil;
                            showLightTable = NO;
                            [self.collectionView reloadData];
                        } else {
                            [self showLightTable:lightTable];
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
    
    if (IDIOM != IPAD){
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .23f * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (sidebarIsVisible){
                [self showSidebar];
            }
        });
    }
}

- (void)resetArtBooleans {
    showMyArt = NO;
    showFavorites = NO;
    showLightTable = NO;
    self.lightTable = nil;
}

- (void)showMyArt {
    if (loggedIn){
        [self resetArtBooleans];
        if (!showMyArt){
            showMyArt = YES;
            [self loadMyArt];
        }
        [self.collectionView reloadData];
    } else {
        [self showLogin];
    }
}

- (void)showFavorites {
    if (loggedIn){
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

- (void)showLightTable:(LightTable*)lightTable {
    if (showLightTable && lightTable.identifier && self.lightTable.identifier && [lightTable.identifier isEqualToNumber:self.lightTable.identifier]){
        [self resetArtBooleans];
    } else {
        [self resetArtBooleans];
        showLightTable = YES;
    }
    self.lightTable = lightTable;
    [self loadLightTable:_lightTable];
}

- (void)loadLightTable:(LightTable*)lightTable {
    if (self.lightTableRequest) return;
    if (lightTable && ![lightTable.identifier isEqualToNumber:@0]){
        NSString *title = lightTable.name.length ? [NSString stringWithFormat:@"\"%@\"",lightTable.name] : @"\"table without a name\"";
        [ProgressHUD show:[NSString stringWithFormat:@"Loading %@",title]];
        self.lightTableRequest = [manager GET:[NSString stringWithFormat:@"light_tables/%@",lightTable.identifier] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            //NSLog(@"Success loading light table: %@",responseObject);
            [lightTable populateFromDictionary:[responseObject objectForKey:@"table"]];
            [self.collectionView reloadData];
            self.lightTableRequest = nil;
            [self endRefresh];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error loading light table: %@",error.description);
            [self endRefresh];
            [self.collectionView reloadData];
            self.lightTableRequest = nil;
        }];
    }
}

#pragma mark - Light Table Delegate Section
- (void)newLightTable {
    if (loggedIn){
        if (IDIOM == IPAD){
            [self newLightTableWithJoinBool:YES];
        } else {
            [[[UIActionSheet alloc] initWithTitle:@"What do you want to do?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:createALightTablePlaceholder, joinLightTablePlaceholder, nil] showInView:self.view];
        }
        
    } else {
        [self showLogin];
    }
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == iPhoneMenu){
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (double).5 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if ([[iPhoneMenu buttonTitleAtIndex:buttonIndex] isEqualToString:addNewArtOption]){
                [self add];
            } else if ([[iPhoneMenu buttonTitleAtIndex:buttonIndex] isEqualToString:notificationsOption]){
                [self showNotifications];
            } else if ([[iPhoneMenu buttonTitleAtIndex:buttonIndex] isEqualToString:settingsOption]){
                [self showSettings];
            } else if ([[iPhoneMenu buttonTitleAtIndex:buttonIndex] isEqualToString:logoutOption]){
                [self logout];
            }
        });
    } else {
        if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:createALightTablePlaceholder]){
            [self newLightTableWithJoinBool:NO];
        } else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:joinLightTablePlaceholder]){
            [self newLightTableWithJoinBool:YES];
        }
    }
}

- (void)newLightTableWithJoinBool:(BOOL)join {
    if (self.currentUser.customerPlan.length){
        WFLightTableDetailsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"LightTableDetails"];
        vc.lightTableDelegate = self;
        [vc setJoinMode:join];
        (_selectedPhotos.count) ? [vc setPhotos:_selectedPhotos] : [vc setShowKey:YES];

        [self resetTransitionBooleans];
        newLightTableTransition = YES;
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            if (IDIOM == IPAD){
                vc.modalPresentationStyle = UIModalPresentationCustom;
                vc.transitioningDelegate = self;
                [self presentViewController:vc animated:YES completion:NULL];
            } else {
                WFNoRotateNavController *nav = [[WFNoRotateNavController alloc] initWithRootViewController:vc];
                nav.modalPresentationStyle = UIModalPresentationCustom;
                nav.transitioningDelegate = self;
                [self presentViewController:nav animated:YES completion:NULL];
            }
        }];
    } else {
        [WFAlert show:@"Joining or creating light tables requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
    }
}

- (void)didJoinLightTable:(LightTable *)table {
    if (!slideshowSidebarMode && sidebarIsVisible){
        [self.tableView reloadData];
    }
}

- (void)didCreateLightTable:(LightTable *)table {
    if (!slideshowSidebarMode && sidebarIsVisible){
        [self.tableView reloadData];
    }
}

- (void)didUpdateLightTable:(LightTable *)table {
    if (!slideshowSidebarMode && sidebarIsVisible){
        [self.tableView reloadData];
        [self.collectionView reloadData];
    }
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        if (sidebarIsVisible){
            return CGSizeMake((width-kSidebarWidth)/3,(width-kSidebarWidth)/3);
        } else {
            return CGSizeMake(width/4, width/4);
        }
    } else {
        return CGSizeMake(width/2,width/2);
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    width = size.width; height = size.height;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (IDIOM == IPAD){
            
        } else {
            [self.collectionView reloadData];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (IDIOM != IPAD){
            topInset = self.navigationController.navigationBar.frame.size.height;
            homeButton.frame = CGRectMake(0.0, 0.0, 66.0, topInset);
            self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, topInset, 0);
        }
    }];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    if (self.searchBar.text.length){
        return _filteredPhotos.count;
    } else if (showMyArt){
        self.searchBar.placeholder = @"Search my art";
        return _myPhotos.count;
    } else if (showLightTable){
        if (self.lightTable && self.lightTable.name.length){
            self.searchBar.placeholder = [NSString stringWithFormat:@"Search %@",_lightTable.name];
        } else {
            self.searchBar.placeholder = @"Search light table";
        }
        return _lightTable.photos.count;
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
    if (self.searchBar.text.length){
        photo = _filteredPhotos[indexPath.item];
    } else if (showMyArt){
        photo = _myPhotos[indexPath.item];
    } else if (showLightTable){
        photo = self.lightTable.photos[indexPath.item];
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
    if (self.searchBar.text.length || showFavorites || (showLightTable && self.lightTable) || showMyArt){
        return CGSizeMake(collectionView.frame.size.width, 54);
    } else {
        return CGSizeMake(1, 0);
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (kind == UICollectionElementKindSectionHeader) {
        WFCatalogHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        [headerView.headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleSubheadline forFont:kMuseoSansLight] size:0]];
        if (showMyArt){
            [headerView.headerLabel setText:@"My Art"];
        } else if (showLightTable) {
            [headerView.headerLabel setText:[NSString stringWithFormat:@"\"%@\" Art",self.lightTable.name]];
        } else if (showFavorites) {
            [headerView.headerLabel setText:@"Favorites"];
        } else if (self.searchBar.text.length) {
            [headerView.headerLabel setText:[NSString stringWithFormat:@"Search results for: \"%@\"",searchText]];
            [headerView.headerLabel setFont:[UIFont fontWithDescriptor:[UIFontDescriptor preferredCustomFontForTextStyle:UIFontTextStyleBody forFont:kMuseoSansLightItalic] size:0]];
        }
        
        [headerView.headerLabel setTextColor:[UIColor blackColor]];
        return headerView;
    } else {
        return nil;
    }
}

- (void)resetCatalog {
    if (!_photos.count){
        [self loadBeforePhoto:nil];
    }
    
    if (sidebarIsVisible || self.searchBar.text.length || showFavorites || showLightTable || showMyArt){
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self resetArtBooleans];
            self.lightTable = nil;
            
            if (sidebarIsVisible){
                [self showSidebar];
            }
            searchText = @"";
            [self.searchBar setText:@""];
            [self.searchBar resignFirstResponder];
            [self.view endEditing:YES];
            [self.collectionView reloadData];
            [self.tableView reloadData];
        });
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.collectionView){
        float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
        if (bottomEdge >= scrollView.contentSize.height) {
            // at the bottom of the scrollView
            if (canSearchMore && self.searchBar.text.length){
                [self loadBeforePhoto:_filteredPhotos.lastObject];
            } else if (showMyArt) {
                NSLog(@"should be loading more of my art");
            } else if (canLoadMore && _photos.count){
                NSLog(@"can load more normal");
                [self loadBeforePhoto:_photos.lastObject];
            }
        }
    }
}

- (void)doubleTap:(UITapGestureRecognizer*)gestureRecognizer {
    CGPoint loc = [gestureRecognizer locationInView:self.collectionView];
    NSIndexPath *selectedIndexPath = [self.collectionView indexPathForItemAtPoint:loc];
    if (!selectedIndexPath) return;
    
    Photo *photo;
    if (showMyArt){
        photo = _myPhotos[selectedIndexPath.item];
    } else if (showLightTable){
        photo = self.lightTable.photos[selectedIndexPath.item];
    } else if (showFavorites){
        photo = _favoritePhotos[selectedIndexPath.item];
    } else if (self.searchBar.text.length){
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
        [self.collectionView reloadData];
        //[self.collectionView reloadItemsAtIndexPaths:@[selectedIndexPath]];
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
    Photo *photo = self.lightTable.photos[indexPathForLightTableArtToRemove.item];
    [self.lightTable removePhoto:photo];
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        if (indexPathForLightTableArtToRemove) {
            [self.collectionView deleteItemsAtIndexPaths:@[indexPathForLightTableArtToRemove]];
        } else {
            [self.collectionView reloadData];
        }
        [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
            [self.draggingView setAlpha:0.0];
        } completion:^(BOOL finished) {
            [self.draggingView removeFromSuperview];
        }];
    }];
    
    [manager DELETE:[NSString stringWithFormat:@"light_tables/%@/remove",self.lightTable.identifier] parameters:@{@"photo_id":photo.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success removing photo from light table: %@",responseObject);
        if (sidebarIsVisible){
            [self.tableView reloadData];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failed to remove photo from light table: %@",error.description);
    }];
}

- (void)addPhotoToLightTable:(Photo*)photo {
    NSIndexPath *newArtIndexPath = [NSIndexPath indexPathForItem:self.lightTable.photos.count inSection:0];
    [self.lightTable addPhoto:photo];
    [self.collectionView insertItemsAtIndexPaths:@[newArtIndexPath]];
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        
    }];
    [manager POST:[NSString stringWithFormat:@"light_tables/%@/add",self.lightTable.identifier] parameters:@{@"photo_id":photo.identifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"success adding art from light table: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"failed to add art from light table: %@",error.description);
    }];
}

- (void)longPressed:(UILongPressGestureRecognizer*)gestureRecognizer {
    CGPoint loc = [gestureRecognizer locationInView:self.collectionView];
//    if (showFavorites){
//        //trying to interact with a favorite
//        if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
//            [self becomeFirstResponder];
//            
//            indexPathForFavoriteToRemove = [self.collectionView indexPathForItemAtPoint:loc];
//            NSString *menuItemTitle = NSLocalizedString(@"Remove", @"Remove this art from your favorites.");
//            UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:menuItemTitle action:@selector(removeFavorite:)];
//            UIMenuController *menuController = [UIMenuController sharedMenuController];
//            [menuController setMenuItems:@[resetMenuItem]];
//            CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
//            CGRect menuLocation = CGRectMake(location.x, location.y, 0, 0);
//            [menuController setTargetRect:menuLocation inView:[gestureRecognizer view]];
//            [menuController setMenuVisible:YES animated:YES];
//        }
//        return;
//    } else if (showLightTable){
//        //trying to interact with a light table piece
//        if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
//            [self becomeFirstResponder];
//            
//            indexPathForLightTableArtToRemove = [self.collectionView indexPathForItemAtPoint:loc];
//            NSString *menuItemTitle = NSLocalizedString(@"Remove", @"Remove this art from your favorites.");
//            UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:menuItemTitle action:@selector(removeLightTablePhoto:)];
//            UIMenuController *menuController = [UIMenuController sharedMenuController];
//            [menuController setMenuItems:@[resetMenuItem]];
//            CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
//            CGRect menuLocation = CGRectMake(location.x, location.y, 0, 0);
//            [menuController setTargetRect:menuLocation inView:[gestureRecognizer view]];
//            [menuController setMenuVisible:YES animated:YES];
//        }
//        return;
//    }
    
    CGFloat heightInScreen = fmodf((loc.y-self.collectionView.contentOffset.y), CGRectGetHeight(self.collectionView.frame));
    CGFloat hoverOffset;
    sidebarIsVisible ? (hoverOffset = kSidebarWidth) : (hoverOffset = 0);
    CGPoint locInScreen = CGPointMake( loc.x - self.collectionView.contentOffset.x + hoverOffset, heightInScreen );
    
    //[self adjustAnchorPointForGestureRecognizer:gestureRecognizer];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.startIndex = [self.collectionView indexPathForItemAtPoint:loc];
        if (self.startIndex) {
            WFPhotoCell *cell = (WFPhotoCell*)[self.collectionView cellForItemAtIndexPath:self.startIndex];
            self.dragViewStartLocation = [self.view convertPoint:cell.center fromView:nil];
            
            Photo *photo;
            if (showMyArt && _myPhotos.count){
                photo = _myPhotos[self.startIndex.item];
            } else if (showLightTable && self.lightTable.photos.count){
                photo = self.lightTable.photos[self.startIndex.item];
            } else if (showFavorites && _favoritePhotos.count){
                photo = _favoritePhotos[self.startIndex.item];
            } else if (self.searchBar.text.length){
                if (_filteredPhotos.count){
                    photo = _filteredPhotos[self.startIndex.item];
                }
            } else if (_photos.count) {
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
        NSLog(@"does collection view contain point? %u",CGRectContainsPoint(self.collectionView.frame, loc));
        //NSLog(@"loc x: %f and y %f, showlighttable? %u",loc.x, loc.y, showLightTable);
        // comparison mode
        if (loc.x < 0 && loc.y > (_comparisonContainerView.frame.origin.y - 128)){ // 128 is half the width of an art slide, since the point we're grabbing is a center point, not the origin
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
            } else if (showLightTable && !CGRectContainsPoint(self.collectionView.frame, loc)) {
                NSLog(@"get rid of it");
                indexPathForLightTableArtToRemove = self.startIndex;
                [self removeLightTablePhoto:nil];
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
        //WFComparisonViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Comparison"];
        //vc.photos = [NSMutableOrderedSet orderedSetWithArray:@[comparison1.photo, comparison2.photo]];
    
        WFSlideshowViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Slideshow"];
        [vc setPhotos:@[comparison1.photo,comparison2.photo]];
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
    if (IDIOM != IPAD && sidebarIsVisible){
        [self showSidebar]; // temporary
        return;
    }
    Photo *photo;
    if (self.searchBar.text.length && indexPath.item < _filteredPhotos.count){
        photo = _filteredPhotos[indexPath.item];
    } else if (showMyArt && indexPath.item < _myPhotos.count){
        photo = _myPhotos[indexPath.item];
    } else if (showLightTable && indexPath.item < self.lightTable.photos.count){
        photo = self.lightTable.photos[indexPath.item];
    } else if (showFavorites && indexPath.item < _favoritePhotos.count){
        photo = _favoritePhotos[indexPath.item];
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
    
    UINavigationController *nav;
    if (IDIOM == IPAD){
        [self resetTransitionBooleans];
        metadata = YES;
        nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        nav.view.clipsToBounds = YES;
    } else {
        nav = [[WFNoRotateNavController alloc] initWithRootViewController:vc];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:nav animated:YES completion:NULL];
    });
    
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
    for (LightTable *lightTable in _lightTables){
        if ([lightTable.photos containsObject:photo]){
            [lightTable removePhoto:photo];
        }
    }
}

- (void)favoritedPhoto:(Photo *)photo {
    [_favoritePhotos addObject:photo];
}

- (void)droppedPhoto:(Photo*)photo toLightTable:(LightTable*)lightTable {
    if (!slideshowSidebarMode && sidebarIsVisible){
        [self.tableView reloadData];
    }
}

- (void)removedPhoto:(Photo *)photo fromLightTable:(LightTable *)lightTable {
    //ensure the photo has ACTUALLY been removed from the light table
    [lightTable removePhoto:photo];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    if (!slideshowSidebarMode && sidebarIsVisible){
        [self.tableView reloadData];
    }
    
    if (showLightTable && [lightTable.identifier isEqualToNumber:self.lightTable.identifier]){
        [self.collectionView reloadData];
    }
}

- (void)dismissMetadata {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)photoDeleted:(Photo *)p {
    Photo *photo = [p MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (showMyArt){
        [_myPhotos removeObject:photo];
    } else if (showFavorites){
        [_favoritePhotos removeObject:photo];
    } else if (showLightTable && self.lightTable){
        [self.lightTable removePhoto:photo];
    } else {
        [_photos removeObject:photo];
    }
    [photo MR_deleteInContext:[NSManagedObjectContext MR_defaultContext]];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
        [self.collectionView reloadData];
    }];
}

- (void)artDeleted:(Art *)art {
    [self.collectionView reloadData];
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
    if (!_selectedPhotos.count){
        [WFAlert show:@"Double tap to select multiple slides at once" withTime:3.3f];
        return;
    }
    
    WFSearchResultsViewController *searchResultsVc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SearchResults"];
    [searchResultsVc setSelectedPhotos:_selectedPhotos];
    searchResultsVc.searchDelegate = self;
    UINavigationController *selectedNav = [[UINavigationController alloc] initWithRootViewController:searchResultsVc];
    if (IDIOM == IPAD){
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        CGFloat selectedHeight = _selectedPhotos.count*80.f > 640.f ? 640.f : (_selectedPhotos.count*80.f); // don't need to offset by 44 because iOS is already adding a scrolView offset for us
        searchResultsVc.preferredContentSize = CGSizeMake(420, selectedHeight);
        [searchResultsVc setOriginalPopoverHeight:selectedHeight];
        selectedNav.preferredContentSize = CGSizeMake(420, selectedHeight);
        self.popover = [[UIPopoverController alloc] initWithContentViewController:selectedNav];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:selectedBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self resetTransitionBooleans];
        transparentBG = YES;
        selectedNav.transitioningDelegate = self;
        selectedNav.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:selectedNav animated:YES completion:^{
            
        }];
    }
}

- (void)showNotifications {
    WFNotificationsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Notifications"];
    vc.notificationsDelegate = self;
    if (IDIOM == IPAD){
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        vc.preferredContentSize = CGSizeMake(470, 500);
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:notificationsBarButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else {
        [self resetTransitionBooleans];
        transparentBG = YES;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:nav animated:YES completion:NULL];
    }
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
    if (IDIOM == IPAD) {
        if (self.popover){
            [self.popover dismissPopoverAnimated:YES];
        }
        WFMenuViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Menu"];
        vc.menuDelegate = self;
        vc.preferredContentSize = CGSizeMake(170, 150);
        self.popover = [[UIPopoverController alloc] initWithContentViewController:vc];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Where do you want to go?" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *a = [UIAlertAction actionWithTitle:@"Account" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self showSettings];
        }];
        UIAlertAction *p = [UIAlertAction actionWithTitle:@"Profile" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self showProfile];
        }];
        UIAlertAction *l = [UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [self logout];
        }];
        UIAlertAction *c = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertController addAction:a];
        [alertController addAction:p];
        [alertController addAction:l];
        [alertController addAction:c];
        [self presentViewController:alertController animated:YES completion:NULL];
    }
}

- (void)resetTransitionBooleans {
    settings = NO;
    newArt = NO;
    newLightTableTransition = NO;
    metadata = NO;
    comparison = NO;
    _login = NO;
    groupBool = NO;
    newUser = NO;
    profile = NO;
    showSlideshow = NO;
    transparentBG = NO;
}

- (void)showSearch {
    CGFloat navHeight = self.navigationController.navigationBar.frame.size.height;
    if (sidebarIsVisible) {
        [self showSidebar];
    }
    if (searchVisible) {
        [self.searchBar resignFirstResponder];
        [UIView animateWithDuration:kFastAnimationDuration delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.collectionView setFrame:CGRectMake(0, 0, width, height)];
            [self.searchBarContainer setFrame:CGRectMake(0, 0, width, 44)];
            [self.searchBarContainer setAlpha:0.0];
        } completion:^(BOOL finished) {
            searchVisible = NO;
        }];
    } else {
        [UIView animateWithDuration:kFastAnimationDuration delay:0 usingSpringWithDamping:.9 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.collectionView setFrame:CGRectMake(0, navHeight, width, height-navHeight)];
            [self.searchBarContainer setFrame:CGRectMake(0, navHeight, width, 44)];
            [self.searchBarContainer setAlpha:1.0];
        } completion:^(BOOL finished) {
            searchVisible = YES;
            [self.searchBar becomeFirstResponder];
        }];
    }
}

- (void)showSettings {
    if (loggedIn){
        WFSettingsViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Settings"];
        vc.settingsDelegate = self;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self resetTransitionBooleans];
        if (IDIOM == IPAD){
            if (self.popover){
                [self.popover dismissPopoverAnimated:YES];
            }
            settings = YES;
        } else {
            transparentBG = YES;
        }
        [self presentViewController:nav animated:YES completion:NULL];
    } else {
        [self showLogin];
    }
}

- (void)showiPhoneMenu {
    if (!iPhoneMenu)
        iPhoneMenu = [[UIActionSheet alloc] initWithTitle:@"Where to go from here?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:addNewArtOption, notificationsOption, settingsOption, logoutOption, nil];
    [iPhoneMenu showInView:self.view];
}

- (void)showProfile {
    if (loggedIn){
        WFProfileViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"Profile"];
        [vc setUser:self.currentUser];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self resetTransitionBooleans];
        profile = YES;
        
        if (IDIOM == IPAD){
            if (self.popover){
                [self.popover dismissPopoverAnimated:YES];
            }
            nav.transitioningDelegate = self;
            nav.modalPresentationStyle = UIModalPresentationCustom;
        }
        
        [self presentViewController:nav animated:YES completion:NULL];
    } else {
        [self showLogin];
    }
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

- (void)slideshowSelected:(Slideshow *)s {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    if (self.currentUser.customerPlan.length){
        Slideshow *slideshow = [Slideshow MR_findFirstByAttribute:@"identifier" withValue:s.identifier inContext:[NSManagedObjectContext MR_defaultContext]];
        WFSlideshowSplitViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"SlideshowSplitView"];
        vc.slideshowDelegate = self;
        [vc setSlideshow:slideshow];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        
        if (IDIOM == IPAD){
            [self resetTransitionBooleans];
            [self presentViewController:nav animated:YES completion:NULL];
        } else {
            if (self.presentedViewController){// dismiss the presented VC, if applicable
                [self dismissViewControllerAnimated:YES completion:^{
                    [self resetTransitionBooleans];
                    [self presentViewController:nav animated:YES completion:NULL];
                }];
            } else {
                [self resetTransitionBooleans];
                [self presentViewController:nav animated:YES completion:NULL];
            }
        }
    } else {
        [WFAlert show:@"Adding selected art to a slideshow requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
    }
}

#pragma createSlidesShow Delegate
- (void)slideshowCreated:(Slideshow *)s {
    Slideshow *slideshow = [s MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    [_slideshows addObject:slideshow];
    [self.tableView reloadData];
}

- (void)slideshow:(Slideshow *)slideshow droppedToLightTable:(LightTable *)lightTable {
    [self.tableView reloadData];
}

- (void)shouldReloadSlideshows {
    if (sidebarIsVisible && slideshowSidebarMode){
        [self.tableView reloadData];
    }
}

- (void)showSlideshows {
    if (loggedIn){
        if (self.currentUser.customerPlan.length){
            tablesButton.selected = NO;
            if (slideshowSidebarMode){
                [self.tableView reloadData];
                [self showSidebar];
            } else {
                slideshowSidebarMode = YES;
                if (sidebarIsVisible){
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
        if (sidebarIsVisible){
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
    CGFloat offsetWidth = IDIOM == IPAD ? kSidebarWidth : kSidebarWidth;
    if (sidebarIsVisible){
        sidebarIsVisible = NO;
        //hide the light table sidebar
        CGRect collectionFrame = self.collectionView.frame;
        collectionFrame.origin.x = 0;
        collectionFrame.size.width = width;
        slideshowsButton.selected = NO;
        tablesButton.selected = NO;
        
        [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            _tableView.transform = CGAffineTransformIdentity;
            _searchBarContainer.transform = CGAffineTransformIdentity;
            _comparisonContainerView.transform = CGAffineTransformIdentity;
            [self.collectionView reloadData];
            [self.collectionView setFrame:collectionFrame];
        } completion:^(BOOL finished) {
            if (self.searchBar.isFirstResponder){
                [self.searchBar resignFirstResponder];
            }
        }];
    } else {
        if (self.popover) {
            [self.popover dismissPopoverAnimated:YES];
        }
        sidebarIsVisible = YES;
        if (slideshowSidebarMode) {
            slideshowsButton.selected = YES;
        } else {
            tablesButton.selected = YES;
        }
        
        CGRect collectionFrame = self.collectionView.frame;
        collectionFrame.size.width = width - kSidebarWidth;
        collectionFrame.origin.x = offsetWidth;
        
        [UIView animateWithDuration:.35 delay:0 usingSpringWithDamping:.95 initialSpringVelocity:.0001 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _tableView.transform = CGAffineTransformMakeTranslation(offsetWidth, 0);
            _searchBarContainer.transform = CGAffineTransformMakeTranslation(offsetWidth, 0);
            _comparisonContainerView.transform = CGAffineTransformMakeTranslation(offsetWidth, 0);
            [self.collectionView reloadData];
            [self.collectionView setFrame:collectionFrame];
        } completion:^(BOOL finished) {
            if (self.searchBar.isFirstResponder) {
                [self.searchBar resignFirstResponder];
            }
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
        if (IDIOM != IPAD){ animator.dark = YES; }
        animator.presenting = YES;
        return animator;
    } else if (metadata){
        WFArtMetadataAnimator *animator = [WFArtMetadataAnimator new];
        animator.presenting = YES;
        return animator;
    } else if (transparentBG){
        WFTransparentBGModalAnimator *animator = [WFTransparentBGModalAnimator new];
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
    } else if (transparentBG){
        WFTransparentBGModalAnimator *animator = [WFTransparentBGModalAnimator new];
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
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    canSearchMore = YES; // manually set this to on when a user wants to search
    [ProgressHUD show:@"Searching..."];
    [searchBar endEditing:YES];
    searchText = searchBar.text;
    [self loadBeforePhoto:nil];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar endEditing:YES];
    searchText = @"";
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (!searchBar.text.length) {
        [self resetArtBooleans];
    }
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:^{
       
    }];
}

#pragma mark - Search Methods
- (void)setUpSearch {
    [self.searchBar setPlaceholder:@"Search catalog"];
    
    //reset the search bar font
    for (id subview in [self.searchBar.subviews.firstObject subviews]){
        if ([subview isKindOfClass:[UITextField class]]){
            UITextField *searchTextField = (UITextField*)subview;
            if (IDIOM == IPAD){
                [searchTextField setTextColor:[UIColor whiteColor]];
            } else {
                [searchTextField setTextColor:[UIColor blackColor]];
            }
            [searchTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
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
    if (self.popover) [self.popover dismissPopoverAnimated:YES];
}

- (void)searchDidSelectPhoto:(Photo *)photo {
   
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)text {
    [self filterContentForSearchText:text scope:nil];
}

- (void)filterContentForSearchText:(NSString*)text scope:(NSString*)scope {
    searchText = text;
    if (text.length) {
        [_filteredPhotos removeAllObjects];
        NSOrderedSet *photosToIterateThrough;
        if (showLightTable && self.lightTable){
            photosToIterateThrough = self.lightTable.photos;
        } else if (showMyArt){
            photosToIterateThrough = _myPhotos;
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
            } else if ([predicate evaluateWithObject:art.tagsToSentence]){
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:photo.iconsToSentence]){
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:photo.credit]){
                [_filteredPhotos addObject:photo];
            } else if ([predicate evaluateWithObject:art.user.fullName]){
                [_filteredPhotos addObject:photo];
            }
        }
        
        if (!_filteredPhotos.count) [self loadBeforePhoto:nil];
    } else if (showLightTable) {
        _filteredPhotos = [NSMutableOrderedSet orderedSetWithOrderedSet:_lightTable.photos];
    } else if (showMyArt) {
        _filteredPhotos = [NSMutableOrderedSet orderedSetWithOrderedSet:_myPhotos];
    } else if (showFavorites) {
        _filteredPhotos = [NSMutableOrderedSet orderedSetWithOrderedSet:_favoritePhotos];
    } else {
        _filteredPhotos = [NSMutableOrderedSet orderedSetWithOrderedSet:_photos];
    }
    
    NSLog(@"filtered photo count: %lu",(unsigned long)_filteredPhotos.count);
    [self.collectionView reloadData];
}

#pragma mark - WFSearchDelegate methods
- (void)batchSelectForLightTable:(LightTable *)l {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    if (self.currentUser.customerPlan.length){
        LightTable *lightTable = [l MR_inContext:[NSManagedObjectContext MR_defaultContext]];
        [lightTable addPhotos:_selectedPhotos.array];
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            __block NSMutableArray *photoIds = [NSMutableArray arrayWithCapacity:lightTable.photos.count];
            [lightTable.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
                [photoIds addObject:photo.identifier];
            }];
            if (sidebarIsVisible && !slideshowSidebarMode){
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

- (void)slideshowForSelected:(Slideshow *)s {
    Slideshow *slideshow = [s MR_inContext:[NSManagedObjectContext MR_defaultContext]];
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    if (self.currentUser.customerPlan.length){
        if (slideshow){
            NSMutableOrderedSet *photoSet = slideshow.photos.mutableCopy;
            [photoSet addObjectsFromArray:_selectedPhotos.array];
            slideshow.photos = photoSet;
            
            __block NSMutableArray *photoIds = [NSMutableArray array];
            [slideshow.photos enumerateObjectsUsingBlock:^(Photo *photo, NSUInteger idx, BOOL *stop) {
                [photoIds addObject:photo.identifier];
            }];
            
            if (photoIds.count){
                if ([slideshow.identifier isEqualToNumber:@0]){
                    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                        [self newSlideshow:YES];
                    }];
                } else {
                    //NSString *title = slideshow.title.length ? slideshow.title : @"No title";
                    //NSString *photoCount = _selectedPhotos.count == 1 ? [NSString stringWithFormat:@"1 photo dropped to \"%@\"",title] : [NSString stringWithFormat:@"%lu photos dropped to \"%@\"",(unsigned long)_selectedPhotos.count,title];
                    //[WFAlert show:photoCount withTime:3.3f];
                    [manager PATCH:[NSString stringWithFormat:@"slideshows/%@/add_photos",slideshow.identifier] parameters:@{@"slideshow":@{@"photo_ids":photoIds}, @"user_id":[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        //NSLog(@"Success dropping photos to slideshow: %@",responseObject);
                        [slideshow populateFromDictionary:[responseObject objectForKey:@"slideshow"]];
                        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                            [self.tableView reloadData];
                            [self slideshowSelected:slideshow];
                        }];
                        
                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        
                    }];
                }
            }
        } else {
            [self newSlideshow:YES];
        }
    } else {
        [WFAlert show:@"Dropping selected art into a slideshow requires a billing plan.\n\nPlease either set up an individual billing plan OR add yourself as a member to an institution that's been registered with Wölff." withTime:5.f];
    }
}

- (void)batchFavorite {
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
    
    if (loggedIn && self.currentUser){
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

- (void)removeAllSelected {
    [_selectedPhotos removeAllObjects];
    [self.collectionView reloadData];
    [self configureSelectedButton];
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
}

- (void)endSearch {
    
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

- (void)doneEditing {
    [self.view endEditing:YES];
    [self.searchBar endEditing:YES];
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
                         self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, keyboardHeight+44, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, keyboardHeight+44, 0);
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
                         self.collectionView.contentInset = UIEdgeInsetsMake(topInset, 0, topInset, 0);
                         self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, topInset, 0);
                         self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, topInset, 0);
                         self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, topInset, 0);
                     }
                     completion:NULL];
}

- (void)viewWillDisappear:(BOOL)animated {
    [ProgressHUD dismiss];
    [super viewWillDisappear:animated];
    if (tableViewRefresh.isRefreshing){
        [tableViewRefresh endRefreshing];
    }
    if (self.popover){
        [self.popover dismissPopoverAnimated:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
