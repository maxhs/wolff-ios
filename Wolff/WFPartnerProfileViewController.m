//
//  WFPartnerProfileViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/8/15.
//  Copyright (c) 2015 Wolff. All rights reserved.
//

#import "WFPartnerProfileViewController.h"
#import "WFProfileHeader.h"
#import "WFPhotoCell.h"
#import "WFUtilities.h"
#import "WFPhotoTileCell.h"
#import "WFArtMetadataAnimator.h"
#import "WFArtMetadataViewController.h"
#import "WFWebViewController.h"
#import "WFPartnerProfileHeader.h"
#import "WFNoRotateNavController.h"
#import "WFTracking.h"

@interface WFPartnerProfileViewController () <UIViewControllerTransitioningDelegate, WFMetadataDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    UIBarButtonItem *dismissButton;
    CGFloat height;
    CGFloat width;
    BOOL photos;
    BOOL slideshows;
    BOOL canLoadMore;
    UIImageView *navBarShadowView;
    NSDateFormatter *partnerSinceDateFormatter;
    NSMutableOrderedSet *_publicPhotos;
}
@property (strong, nonatomic) AFHTTPRequestOperation *loadPartnerRequest;
@property (strong, nonatomic) AFHTTPRequestOperation *photosRequest;
@end

@implementation WFPartnerProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.collectionView setBackgroundColor:[UIColor clearColor]];
    width = screenWidth();
    height = screenHeight();
    dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.view.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"whiteLogo"]];
    
    [self loadPartner];
    [self loadPartnerPhotosBeforePhoto:nil];
    partnerSinceDateFormatter = [[NSDateFormatter alloc] init];
    [partnerSinceDateFormatter setDateFormat:@"MMM yy"];
    
    photos = YES; //photos mode by default
    [self getPublicPhotos];
}

- (void)getPublicPhotos {
    NSPredicate *publicPhotoPredicate = [NSPredicate predicateWithFormat:@"ANY partners.identifier == %@ && privatePhoto != %@ && art.privateArt != %@",self.partner.identifier, @YES, @YES];
    _publicPhotos = [NSMutableOrderedSet orderedSetWithArray:[Photo MR_findAllSortedBy:@"createdDate" ascending:NO withPredicate:publicPhotoPredicate inContext:[NSManagedObjectContext MR_defaultContext]]];
    [self.collectionView reloadData];
}

- (void)loadPartner {
    if (self.loadPartnerRequest) return;
    [ProgressHUD show:@"Fetching info..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    self.loadPartnerRequest = [manager GET:[NSString stringWithFormat:@"partners/%@",self.partner.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading partner details: %@",responseObject);
        [self.partner populateFromDictionary:[responseObject objectForKey:@"partner"]];
        self.title = self.partner.name;
        
        [WFTracking trackEvent:@"Partner Profile" withProperties:[WFTracking generateTrackingPropertiesForPartner:self.partner]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            
            [ProgressHUD dismiss];
            self.loadPartnerRequest = nil;
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load partner details: %@",error.description);
        [ProgressHUD dismiss];
        self.loadPartnerRequest = nil;
    }];
}

- (void)loadPartnerPhotosBeforePhoto:(Photo*)photo {
    if (self.photosRequest) return;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    //[parameters setObject:@(ART_THROTTLE) forKey:@"count"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    if (photo){
        [parameters setObject:[NSNumber numberWithInt:round([photo.createdDate timeIntervalSince1970])] forKey:@"before_date"]; // last item in feed
    } else {
        [parameters setObject:[NSNumber numberWithInt:round([[NSDate date] timeIntervalSince1970])] forKey:@"before_date"]; // today
    }
    self.photosRequest = [manager GET:[NSString stringWithFormat:@"partners/%@/photos",self.partner.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading partner photos: %@",responseObject);
        NSArray *photoDict = [responseObject objectForKey:@"photos"];
        if (photoDict.count){
            canLoadMore = YES;
            [self parsePhotos:[responseObject objectForKey:@"photos"]];
            //[self.partner populateFromDictionary:responseObject];
            [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [ProgressHUD dismiss];
                self.photosRequest = nil;
            }];
        } else {
            canLoadMore = NO;
            [ProgressHUD dismiss];
            self.photosRequest = nil;
        }
        NSLog(@"Success loading %lu partner photos",(unsigned long)[photoDict count]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Failed to load partner photos: %@",error.description);
        [ProgressHUD dismiss];
        self.photosRequest = nil;
    }];
}

- (void)parsePhotos:(NSArray*)photosArray {
    [photosArray enumerateObjectsUsingBlock:^(id dict, NSUInteger idx, BOOL * stop) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [dict objectForKey:@"id"]];
        Photo *photo = [Photo MR_findFirstWithPredicate:predicate inContext:[NSManagedObjectContext MR_defaultContext]];
        if (!photo){
            photo = [Photo MR_createEntityInContext:[NSManagedObjectContext MR_defaultContext]];
        }
        [photo populateFromDictionary:dict];
        [_publicPhotos addObject:photo];
    }];
    [self.collectionView reloadData];
}

- (void)resetBooleans {
    photos = NO;
    slideshows = NO;
}

- (void)goToUrl {
    WFWebViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"WebView"];
    NSString *urlString;
    if ([self.partner.url rangeOfString:@"http://"].location == NSNotFound && [self.partner.url rangeOfString:@"https://"].location == NSNotFound){
        urlString = [@"http://" stringByAppendingString:self.partner.url];
    } else {
        urlString = self.partner.url;
    }
    [vc setUrl:[NSURL URLWithString:urlString]];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:NULL];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    width = size.width;
    height = size.height;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (IDIOM == IPAD){
            
        } else {
            [self.collectionView reloadData];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Code here will execute after the rotation has finished.
        // Equivalent to placing it in the deprecated method -[didRotateFromInterfaceOrientation:]
        
    }];
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IDIOM == IPAD){
        return CGSizeMake(width/4, width/4);
    } else {
        return CGSizeMake(width/2, width/2);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (IDIOM == IPAD){
        return CGSizeMake(width,270);
    } else {
        return CGSizeMake(width,160);
    }
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
        WFPartnerProfileHeader *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PartnerProfileHeader" forIndexPath:indexPath];
        [headerView setBackgroundColor:[UIColor clearColor]];
        [headerView configureForPartner:self.partner];
        [headerView.partnerSinceLabel setText:[NSString stringWithFormat:@"Partner since %@",[partnerSinceDateFormatter stringFromDate:self.partner.createdDate]]];
        if (self.partner.url.length){
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.collectionView){
        float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
        if (bottomEdge >= scrollView.contentSize.height) {
            // at the bottom of the scrollView
            if (_publicPhotos.count){
                if (canLoadMore){
                    [self loadPartnerPhotosBeforePhoto:_publicPhotos.lastObject];
                }
            }
        }
    }
}

- (void)showMetadata:(Photo*)photo{
    WFArtMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ArtMetadata"];
    vc.metadataDelegate = self;
    [vc setPhoto:photo];
    
    UINavigationController *nav;
    if (IDIOM == IPAD){
        [self resetBooleans];
        photos = YES;
        nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        nav.view.clipsToBounds = YES;
    } else {
        nav = [[WFNoRotateNavController alloc] initWithRootViewController:vc];
        NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
    
    [self presentViewController:nav animated:YES completion:NULL];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.photosRequest cancel];
    [self.loadPartnerRequest cancel];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
