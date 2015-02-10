//
//  WFImagePickerController.m
//  Wolff
//
//  Created by Max Haines-Stiles on 12/30/14.
//  Copyright (c) 2014 Wolff. All rights reserved.
//

#import "WFImagePickerController.h"
#import "WFImagePickerCell.h"
#import "Constants.h"
#import "WFUtilities.h"

@interface WFImagePickerController () {
    CGFloat width;
    CGFloat height;
    NSMutableArray *_assets;
    NSMutableOrderedSet *_selectedAssets;
    UIImageView *focusImageView;
    UIImageView *navBarShadowView;
    UIBarButtonItem *selectButton;
    UIBarButtonItem *doneButton;
    UIBarButtonItem *backButton;
    BOOL selectMode;
}

@end

@implementation WFImagePickerController
static NSString * const reuseIdentifier = @"PhotoCell";

@synthesize assetsGroup = _assetsGroup;

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
    _assets = [NSMutableArray array];
    _selectedAssets = [NSMutableOrderedSet orderedSet];
    [self loadPhotos];
    selectButton = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(toggleSelectMode)];

    selectMode = YES;
    
    backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left"] style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    
    self.navigationItem.rightBarButtonItem = doneButton;
    self.navigationItem.leftBarButtonItem = backButton;
    navBarShadowView = [WFUtilities findNavShadow:self.navigationController.navigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    backButton = self.navigationItem.backBarButtonItem;
    navBarShadowView.hidden = YES;
}

- (void)toggleSelectMode {
    selectMode ? (selectMode = NO) : (selectMode = YES);
    if (selectMode){
        self.navigationItem.leftBarButtonItem = backButton;
        self.navigationItem.rightBarButtonItem = doneButton;
    } else {
        self.navigationItem.rightBarButtonItem = selectButton;
        self.navigationItem.leftBarButtonItem = backButton;
    }
}

- (void)loadPhotos {
    if([ALAssetsLibrary authorizationStatus]) {
        ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result) {
                [_assets addObject:result];
            }
        };
        
        ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
        [_assetsGroup setAssetsFilter:onlyPhotosFilter];
        [_assetsGroup enumerateAssetsUsingBlock:assetsEnumerationBlock];
        [self.collectionView reloadData];
    } else {
        NSLog(@"not authorized");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Permission Denied" message:@"Please allow the application to access your photo and videos in settings panel of your device" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFImagePickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    ALAsset *asset = _assets[indexPath.item];
    CGImageRef thumbnailImageRef = [asset thumbnail];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
    [cell.imageView setImage:thumbnail];
    
    if ([_selectedAssets containsObject:asset]){
        [cell.checkmark setHidden:NO];
    } else {
        [cell.checkmark setHidden:YES];
    }
    
    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(128,128);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ALAsset *asset = _assets[indexPath.item];
    WFImagePickerCell *selectedCell = (WFImagePickerCell*)[collectionView cellForItemAtIndexPath:indexPath];
    
    if (selectMode){
        if ([_selectedAssets containsObject:asset]){
            [_selectedAssets removeObject:asset];
        } else {
            [_selectedAssets addObject:asset];
        }
        NSString *viewTitle = _selectedAssets.count == 1 ? @"1 photo selected" : [NSString stringWithFormat:@"%lu photos selected",(unsigned long)_selectedAssets.count];
        self.title = viewTitle;
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
//        if (focusImageView){
//            [UIView animateWithDuration:.23f animations:^{
//                [selectedCell.contentView setAlpha:1.f];
//                focusImageView.transform = CGAffineTransformIdentity;
//            } completion:^(BOOL finished) {
//                [focusImageView removeFromSuperview];
//                focusImageView = nil;
//            }];
//        } else {
            [_selectedAssets addObject:asset];
            [selectedCell.contentView setAlpha:0.23f];
            [self.view addSubview:focusImageView];
            [self.view bringSubviewToFront:focusImageView];
            NSLog(@"selected cell frame origin x: %f and y: %f",selectedCell.frame.origin.x,selectedCell.frame.origin.y);
            focusImageView.frame = selectedCell.frame;
            CGRect newFrame = CGRectMake(width/2-400, height/2-300, 800, 600);
            
            [UIView animateWithDuration:.23f animations:^{
                [focusImageView setFrame:newFrame];
            }];
        //}
    }
}

#pragma mark - Segue support

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showPhoto"]) {
        
        // hand off the assets of this album to our singleton data source
        //[PageViewControllerData sharedInstance].photoAssets = self.assets;
        
        // start viewing the image at the appropriate cell index
        //MyPageViewController *pageViewController = [segue destinationViewController];
        //NSIndexPath *selectedCell = [self.collectionView indexPathsForSelectedItems][0];
        //pageViewController.startingIndex = selectedCell.row;
    }
}

- (void)dismiss {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)done {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishPickingPhotos:)]){
        NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:_selectedAssets.count];
        [_selectedAssets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
            UIImage *fullImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]];
            [imageArray addObject:fullImage];
        }];
        [self.delegate didFinishPickingPhotos:imageArray];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

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

@end
