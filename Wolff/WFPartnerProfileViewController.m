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

@interface WFPartnerProfileViewController () <UIViewControllerTransitioningDelegate, WFMetadataDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    User *_currentUser;
    UIBarButtonItem *dismissButton;
    CGFloat height;
    CGFloat width;
    BOOL photos;
    BOOL slideshows;
    BOOL lightTables;
    UIImageView *navBarShadowView;
    NSDateFormatter *partnerSinceDateFormatter;
    NSArray *_publicPhotos;
}

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
    partnerSinceDateFormatter = [[NSDateFormatter alloc] init];
    [partnerSinceDateFormatter setDateFormat:@"MMM yy"];
    
    photos = YES; //photos mode by default
    [self getPublicPhotos];
}

- (void)loadPartner {
    [ProgressHUD show:@"Fetching info..."];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId]){
        [parameters setObject:[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsId] forKey:@"user_id"];
    }
    [manager GET:[NSString stringWithFormat:@"partners/%@",self.partner.identifier] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Success loading partner details: %@",responseObject);
        [self.partner populateFromDictionary:[responseObject objectForKey:@"partner"]];
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
            self.title = self.partner.name;
            [self getPublicPhotos];
            [ProgressHUD dismiss];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to load partner details: %@",error.description);
        [ProgressHUD dismiss];
    }];
}

- (void)getPublicPhotos {
    NSPredicate *publicPhotoPredicate = [NSPredicate predicateWithFormat:@"ANY partners.identifier == %@ && privatePhoto != %@ && art.privateArt != %@",self.partner.identifier, @YES, @YES];
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
    if ([self.partner.url rangeOfString:@"http://"].location == NSNotFound && [self.partner.url rangeOfString:@"https://"].location == NSNotFound){
        urlString = [@"http://" stringByAppendingString:self.partner.url];
    } else {
        urlString = self.partner.url;
    }
    [vc setUrl:[NSURL URLWithString:urlString]];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:^{
        
    }];
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
        if (width >= 414.f){
            return CGSizeMake(width/2, width/2);
        } else {
            return CGSizeMake(width, width);
        }
    }
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
        WFPartnerProfileHeader *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PartnerProfileHeader" forIndexPath:indexPath];
        [headerView setBackgroundColor:[UIColor clearColor]];
        [headerView configureForPartner:self.partner];
        NSString *photoCount = _publicPhotos.count == 1 ? @"1 image" : [NSString stringWithFormat:@"%lu images",(unsigned long)_publicPhotos.count];
        [headerView.photoCountButton setTitle:photoCount forState:UIControlStateNormal];
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

- (void)showMetadata:(Photo*)photo{
    WFArtMetadataViewController *vc = [[self storyboard] instantiateViewControllerWithIdentifier:@"ArtMetadata"];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.view.clipsToBounds = YES;
    vc.metadataDelegate = self;
    [vc setPhoto:photo];
    if (IDIOM == IPAD){
        nav.transitioningDelegate = self;
        nav.modalPresentationStyle = UIModalPresentationCustom;
        [self resetBooleans];
        photos = YES;
    }
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
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
