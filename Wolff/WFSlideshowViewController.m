//
//  WFSlideshowViewController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/6/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFSlideshowViewController.h"
#import "WFSlideshowSlideCell.h"
#import "WFAppDelegate.h"

@interface WFSlideshowViewController () <UIToolbarDelegate> {
    UIBarButtonItem *dismissButton;
    UIBarButtonItem *fullScreenButton;
    UIBarButtonItem *metadataButton;
    WFAppDelegate *delegate;
    CGFloat topInset;
}

@end

@implementation WFSlideshowViewController

@synthesize presentation = _presentation;

- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (WFAppDelegate*)[UIApplication sharedApplication].delegate;
    [self setUpNavBar];
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.f) {
        self.navigationController.hidesBarsOnTap = YES;
    }
    
    [_bottomToolbar setBarStyle:UIBarStyleBlackTranslucent];
    [_bottomToolbar setTranslucent:YES];
}

- (void)setUpNavBar {
    dismissButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"remove"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    fullScreenButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"presentation"] style:UIBarButtonItemStylePlain target:self action:@selector(goFullScreen)];
    metadataButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"right"] style:UIBarButtonItemStylePlain target:self action:@selector(showPresentationMetadata)];
    self.navigationItem.rightBarButtonItems = @[fullScreenButton, metadataButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    topInset = _collectionView.contentInset.top;
}

- (void)showPresentationMetadata {
    NSLog(@"Should be showing presentation metadata");
}

- (void)goFullScreen {
    NSLog(@"Should be going full screen");
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    offset.y = 0;
    [_collectionView setContentOffset:offset];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _presentation.slides.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFSlideshowSlideCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SlideCell" forIndexPath:indexPath];
    Slide *slide = _presentation.slides[indexPath.item];
    [cell configureForSlide:slide inView:self.view];
    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.frame.size.width,collectionView.frame.size.height);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.f) {
        self.navigationController.hidesBarsOnTap = NO;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
