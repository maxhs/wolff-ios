//
//  WFProfileViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 1/1/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFProfileViewController.h"
#import "WFProfileHeader.h"
#import "WFPhotoCell.h"
#import "WFUtilities.h"
#import "WFPhotoTileCell.h"
#import "WFArtMetadataAnimator.h"
#import "WFArtMetadataViewController.h"
#import "WFWebViewController.h"

@interface WFProfileViewController () <UIViewControllerTransitioningDelegate, WFMetadataDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    UIBarButtonItem *dismissButton;
    CGFloat height;
    CGFloat width;
    BOOL iOS8;
    BOOL photos;
    BOOL slideshows;
    BOOL lightTables;
    UIImageView *navBarShadowView;
    NSDateFormatter *userSinceDateFormatter;
    NSArray *_publicPhotos;
}

@end

@implementation WFProfileViewController
@synthesize user = _user;

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.f){
        iOS8 = YES; width = screenWidth(); height = screenHeight();
    } else {
        iOS8 = NO; width = screenHeight(); height = screenWidth();
    }
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"whiteLogo"]];
    
    [self loadUser];
    userSinceDateFormatter = [[NSDateFormatter alloc] init];
    [userSinceDateFormatter setDateFormat:@"MMM yy"];
    
    //photos mode by default
    photos = YES;
    [self getPublicPhotos];
}

- (void)loadUser {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    [manager GET:[NSString stringWithFormat:@"users/%@",_user.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success loading user details: %@",responseObject);
        [_user populateFromDictionary:[responseObject objectForKey:@"user"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            self.title = _user.fullName;
            [self getPublicPhotos];
        }];
       
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load user details: %@",error.description);
    }];
}

- (void)getPublicPhotos {
    NSPredicate *publicPhotoPredicate = [NSPredicate predicateWithFormat:@"user.identifier == %@ && privatePhoto != %@ && art.privateArt != %@",_user.identifier, @YES, @YES];
    _publicPhotos = [Photo MR_findAllSortedBy:@"createdDate" ascending:NO withPredicate:publicPhotoPredicate inContext:[NSManagedObjectContext MR_defaultContext]];
    [_collectionView reloadData];
}

- (void)resetBooleans {
    photos = NO;
    slideshows = NO;
    lightTables = NO;
}

- (void)goToUrl {
    WFWebViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"WebView"];
    NSString *urlString;
    if ([_user.url rangeOfString:@"http://"].location == NSNotFound && [_user.url rangeOfString:@"https://"].location == NSNotFound){
        urlString = [@"http://" stringByAppendingString:_user.url];
    } else {
        urlString = _user.url;
    }
    [vc setUrl:[NSURL URLWithString:urlString]];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(width/4, width/4);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark - CollectionView data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _publicPhotos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    Photo *photo = _publicPhotos[indexPath.item];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell configureForPhoto:photo];
    [cell.slideContainerView setBackgroundColor:[UIColor colorWithWhite:1 alpha:.23]];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    if (kind == UICollectionElementKindSectionHeader) {
        WFProfileHeader *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"ProfileHeader" forIndexPath:indexPath];
        [headerView setBackgroundColor:[UIColor clearColor]];
        [headerView configureForUser:_user];
        NSString *photoCount = _publicPhotos.count == 1 ? @"1 image" : [NSString stringWithFormat:@"%lu images",(unsigned long)_publicPhotos.count];
        [headerView.photoCountButton setTitle:photoCount forState:UIControlStateNormal];
        
        NSString *slideshowCount = _user.slideshows.count == 1 ? @"1 slideshow" : [NSString stringWithFormat:@"%lu slideshows",(unsigned long)_user.slideshows.count];
        [headerView.slideshowsButton setTitle:slideshowCount forState:UIControlStateNormal];
        
        NSString *lightTableCount = _user.lightTables.count == 1 ? @"1 light table" : [NSString stringWithFormat:@"%lu light tables",(unsigned long)_user.lightTables.count];
        [headerView.lightTablesButton setTitle:lightTableCount forState:UIControlStateNormal];
        
        [headerView.userSinceLabel setText:[NSString stringWithFormat:@"Since %@",[userSinceDateFormatter stringFromDate:_user.createdDate]]];
        if (_user.url.length){
            [headerView.urlButton addTarget:self action:@selector(goToUrl) forControlEvents:UIControlEventTouchUpInside];
        }
        return headerView;
    } else {
        return nil;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (photos){
        Photo *photo = _publicPhotos[indexPath.item];
        [self showMetadata:photo];
    }
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)showMetadata:(Photo*)photo{
    WFArtMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ArtMetadata"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.view.clipsToBounds = YES;
    vc.metadataDelegate = self;
    [vc setPhoto:photo];
    nav.transitioningDelegate = self;
    nav.modalPresentationStyle = UIModalPresentationCustom;
    [self resetBooleans];
    photos = YES;
    [self presentViewController:nav animated:YES completion:^{
        
    }];
}

#pragma mark Dismiss & Transition Methods
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    WFArtMetadataAnimator *animator = [WFArtMetadataAnimator new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    WFArtMetadataAnimator *animator = [WFArtMetadataAnimator new];
    return animator;
}


- (void)dismiss {
    NSLog(@"profile dismiss");
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
