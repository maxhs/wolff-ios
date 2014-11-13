//
//  WFArtsViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 8/3/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFAppDelegate.h"
#import "WFArtsViewController.h"
#import "WFArtCell.h"
#import "User+helper.h"
#import "Art+helper.h"
#import "WFArtMetadataViewController.h"
#import "WFArtViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageManager.h>
#import "WFArtMetadataAnimator.h"
#import "WFMetadataPresentationController.h"

@interface WFArtsViewController () <UIViewControllerTransitioningDelegate> {
    WFAppDelegate *delegate;
    AFHTTPRequestOperationManager *manager;
    CGFloat width;
    CGFloat height;
    NSMutableArray *arts;
    UIBarButtonItem *addButton;
    UIBarButtonItem *settingsButton;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) UIImageView *draggingView;

///the point we first clicked
@property (nonatomic) CGPoint dragViewStartLocation;

///the indexpath for the first item
@property (nonatomic) NSIndexPath *startIndex;
@property (nonatomic) NSIndexPath *moveToIndexPath;

@end

@implementation WFArtsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    delegate = [UIApplication sharedApplication].delegate;
    manager = delegate.manager;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)){
        width = screenWidth();
        height = screenHeight();
    } else {
        height = screenWidth();
        width = screenHeight();
    }
    
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add)];
    settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(goToSettings)];
    self.navigationItem.rightBarButtonItems = @[addButton,settingsButton];
    
    NSLog(@"huh");
}

- (void)add {
    
}

- (void)goToSettings {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation) || [[[UIDevice currentDevice] systemName] floatValue] >= 8.f){
        width = screenWidth();
        height = screenHeight();
    } else {
        height = screenWidth();
        width = screenHeight();
    }
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
    //return arts.count;
    return 12;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFArtCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ArtCell" forIndexPath:indexPath];
    cell.layer.borderColor = [UIColor colorWithWhite:1 alpha:.023].CGColor;
    cell.layer.borderWidth = .5f;
    Art *art = arts[indexPath.row];
    //NSLog(@"art url: %@",art.mediumImageUrl);
    /*if (art.mediumImageUrl.length){
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

- (IBAction)longPressed:(UILongPressGestureRecognizer*)sender {
    CGPoint loc = [sender locationInView:self.collectionView];
    CGFloat heightInScreen = fmodf((loc.y-self.collectionView.contentOffset.y), CGRectGetHeight(self.collectionView.frame));
    CGPoint locInScreen = CGPointMake( loc.x-self.collectionView.contentOffset.x, heightInScreen );
    
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
    NSLog(@"huh?");
    //[self performSegueWithIdentifier:@"Art" sender:art];
    //[self showMetadata:art];
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
//    [self presentViewController:vc animated:YES completion:^{
//
//    }];
}

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

//iOS 8
- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source {
    WFMetadataPresentationController *presentationController = [WFMetadataPresentationController new];
    return presentationController;
}

@end
